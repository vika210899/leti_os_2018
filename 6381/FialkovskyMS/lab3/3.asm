; Шаблон текста программы для модуля типа .COM
TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

hex db '    $'
endl db 0DH,0AH,'$'
str_print_free_memory db 'Size of free memory: ', '$'
str_print_free_memory_empty db '       Bytes', '$'
str_print_extended_memory db 'Size of extended memory: ', '$'
str_print_extended_memory_empty db '      KBytes','$'

str_mcb_list_header  db ' Addrss Owner   Size Name$'
str_mcb_list_empty db '                               $'
str_error db 'Error!!1!', '$'
;str_overflow db 'Overflow error.$'


; Сокращение для функции вывода.
PRINT_DX proc near
	mov AH,09h
	int 21h
	ret
PRINT_DX endp

; Вспомогательная функция из шаблона
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

; байт AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

;перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: 
	div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: 
	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

; перевод в 10с/с числа DX:AX, SI - адрес поля младшей цифры
DWORD_TO_DEC PROC near
	push ax
	push CX
	push DX
	;xor AH,AH
	;xor DX,DX
	mov CX,10
loop_dwd: 
	div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_dwd
	cmp AL,00h
	je dwd_end
	or AL,30h
	mov [SI],AL
dwd_end: 
	pop DX
	pop CX
	pop ax
	ret
DWORD_TO_DEC ENDP

; Выводит размер доступной памяти 
PRINT_FREE_MEMORY proc near
	push ax
	push bx
	push dx
	push si
	mov ah, 4Ah
	mov bx, 0FFFFh ;заведомо большая память
	int 21h	; в bx  получаем макс размер в параграфах
	mov ax, 16 ; в 1 параграфе 16 байт
	mul bx  ;dx:ax = ax * bx
	
	mov si, offset str_print_free_memory_empty+5
	call DWORD_TO_DEC
	
	mov dx, offset endl
	call PRINT_DX
	mov dx, offset str_print_free_memory
	call PRINT_DX
	mov dx, offset str_print_free_memory_empty
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX

	pop si
	pop dx
	pop bx
	pop ax
	ret
PRINT_FREE_MEMORY endp

; Выводит размера расширенной памяти
PRINT_EXTENDED_MEMORY proc near
	push ax
	push dx
	push si
	; работа с CMOS
	mov AL,31h
    out 70h,AL
    in AL,71h 
	mov ah, al ; записыаем в ah старший разряд
	mov  AL,30h
    out 70h,AL
    in AL,71h ; записываем в ah младший разряд
	; теперь в ax лежит полный размер расширенной памяти
	mov dx,0 ;DWORD_TO_DEC работает с dx и ax, поэтому dx обнулим
	mov si,offset str_print_extended_memory_empty + 4
	call DWORD_TO_DEC
	
	mov dx, offset str_print_extended_memory
	call PRINT_DX
	mov dx, offset str_print_extended_memory_empty
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	call PRINT_DX
	
	pop si
	pop dx
	pop ax
	ret
PRINT_EXTENDED_MEMORY endp


; Вывод информации о всех MCB
PRINT_MCB_LIST proc near
	mov dx, offset str_mcb_list_header
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	
	mov ah,52h ;Get List of Lists
	int 21h
	mov ax,es:[bx-2] ; в es:[bx-2] лежит адрес самого первого МСВ
	mov es,ax
	mov dx,es
	
	xor bx,bx
	print_list_cycle:
		call PRINT_MCB_LIST_CURRENT
		cmp byte ptr es:[00h],5Ah ; По смещению 0 находится байт, определяющий тип мсв (последний (5AH) в списке или нет(4DH))
		je print_exit ; если последний, выход
		inc dx ; Moving to the next MCB
		add dx,es:[03h] ; прибавляем размер текущего участка для перехода к след. блоку
		mov es,dx ; теперь этот адрес в es
	jmp print_list_cycle
	print_exit:	
	ret
PRINT_MCB_LIST endp

; Процедура вывода информации MCB, находящегося по адресу es
PRINT_MCB_LIST_CURRENT PROC near
	push ax
	push dx
	push bx
	push si
	push es
	push di
	
	; Address
	mov di, offset str_mcb_list_empty + 5
	mov ax,es
	call WRD_TO_HEX
	
	; Owner
	mov di, offset str_mcb_list_empty + 11
	mov ax,es:[01h]
	call WRD_TO_HEX
	
	; Size
	mov ax,es:[03h] ; кладём размер участка в параграфах
	mov si, offset str_mcb_list_empty+19
	mov bx,16 ; переводим параграфы в байты
	mul bx
	call DWORD_TO_DEC
	
	; Name
	mov bx, offset str_mcb_list_empty + 28
	mov dx,es:[0Fh-1]
	mov [bx-1],dx
	mov dx,es:[0Fh-3]
	mov [bx-3],dx
	mov dx,es:[0Fh-5]
	mov [bx-5],dx
	mov dx,es:[0Fh-7]
	mov [bx-7],dx
	
	mov dx, offset str_mcb_list_empty
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	
	mov al,' '
	mov ah,' '
	mov si, offset str_mcb_list_empty ; Deleting symbols from string
	mov [si+20],ax
	mov [si+18],ax
	mov [si+16],ax
	mov [si+14],ax
	mov [si+12],ax
		
	pop di
	pop es
	pop si
	pop bx
	pop dx
	pop ax

	ret
PRINT_MCB_LIST_CURRENT endp

FREE_MEMORY proc near
	push ax
	push bx
	push dx
	
	mov ax, offset last_byte ; получаем адрес последнего байта для вычисления размера программы в байтах
	mov bx,10h 
	xor dx,dx
	div bx ; делим на 16 для перевода в параграфы
	inc ax ; выравниваем в большую сторону в случае деления с остатком
	;add ax,16 ; 200 слов на PSP
	;add ax,32 ; 100 слов
	mov bx,ax
	mov ah,4Ah 
	int 21h ; освобождаем память системным вызовом
	pop dx
	pop bx
	pop ax
	ret
FREE_MEMORY endp

ALLOCATE_MEMORY proc near	
	mov bx, 4096 ; 4096 параграфов = 64 KBytes
	mov ah, 48h
	int 21h
	ret
ALLOCATE_MEMORY endp


BEGIN:
	call PRINT_FREE_MEMORY
	call PRINT_EXTENDED_MEMORY
	call FREE_MEMORY
	call ALLOCATE_MEMORY
	call PRINT_MCB_LIST	
	xor AL,AL
	mov AH,4Ch
	int 21H
	last_byte:
TESTPC ends
END START