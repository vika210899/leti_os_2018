; Шаблон текста программы для модуля типа .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ
STRAVLMEMINF db 'Size of available memory: $'
STRAVLMEM db '       B$'
STREXPMEMINF db 'Size of expanded memory: $'
STREXPMEM db '      KB$'
STRMCBINFO  db ' # ADDR OWNR      SIZE NAME$'
STRMCBINFO2 db '                               $'
STROVERFLOWERR db 'Overflow error.$'
STRERROR db 'Error.$'
STRENDL db 0DH,0AH,'$'
; ПРОЦЕДУРЫ
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
	
;---------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
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
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
;---------------------------------------
; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;---------------------------------------
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
;---------------------------------------
; Процедура вывода информации о памяти
CHECK_MEMORY PROC near
	; Вывод количества доступной памяти:	
	mov dx,offset STRAVLMEMINF
	call PRINT
	mov si,offset STRAVLMEM+5
	mov ah,4Ah
	mov bx,0FFFFh ; Заведомо больший размер
	int 21h ; Получение объема доступной памяти в регистр bx
	mov ax,bx
	xor dx,dx
	mov bx,10h
	mul bx
	call DWORD_TO_DEC
	mov dx,offset STRAVLMEM
	call PRINT
	mov dx,offset STRENDL
	call PRINT		

	; Вывод размера расширенной памяти:
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov ah,al
	mov al,bl ; В ax теперь хранится размер расширенной памяти
	mov dx,0 ; Функция DWORD_TO_DEC смотрит число в DX:AX, поэтому DX обнуляем 
	mov si,offset STREXPMEM+4
	call DWORD_TO_DEC
	
	mov dx,offset STREXPMEMINF
	call PRINT
	mov dx,offset STREXPMEM
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	; Вывод информации о всех MCB
	mov dx, offset STRMCBINFO
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	mov ah,52h
	int 21h
	mov ax,es:[bx-2]
	mov es,ax ; Moved to the first MCB
	mov dx,es
	
	mov cx,01h ; Number of current MCB
	xor bx,bx
	CM_cycle:
		call PRINT_MCB_INFO
		
		cmp byte ptr es:[00h],5Ah ; Checking if current MCB is last
		je CM_exit
		inc cx
		inc dx ; Moving to the next MCB
		add dx,es:[03h]
		mov es,dx
	jmp CM_cycle
	CM_exit:	
	
	ret
CHECK_MEMORY ENDP
;---------------------------------------
; Процедура вывода информации MCB, находящегося по адресу es
; В cx подаётся номер обрабатываемого MCB
PRINT_MCB_INFO PROC near
	push ax
	push dx
	push bx
	push si
	push es
	push di
	
	mov si,offset STRMCBINFO2+1 ;#
	mov ax,cx
	call BYTE_TO_DEC
	
	mov di,offset STRMCBINFO2+6 ; ADDR
	mov ax,es
	call WRD_TO_HEX
	
	mov di,offset STRMCBINFO2+11 ; OWNR
	mov ax,es:[01h]
	call WRD_TO_HEX
	
	mov si,offset STRMCBINFO2+21 ; SIZE
	mov ax,es:[03h]
	cmp ax,0A000h
	jb PCI_overflowcheck
		mov dx,offset STROVERFLOWERR
		call PRINT
		xor AL,AL
		mov AH,4Ch
		int 21H
	PCI_overflowcheck:
	mov bx,10h
	mul bx
	call DWORD_TO_DEC
	
	mov bx,offset STRMCBINFO2+30 ; NAME
	mov dx,es:[0Fh-1]
	mov [bx-1],dx
	mov dx,es:[0Fh-3]
	mov [bx-3],dx
	mov dx,es:[0Fh-5]
	mov [bx-5],dx
	mov dx,es:[0Fh-7]
	mov [bx-7],dx
	
	mov dx,offset STRMCBINFO2
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	mov al,' '
	mov ah,' '
	mov si,offset STRMCBINFO2 ; Deleting symbols from string
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
PRINT_MCB_INFO ENDP
;---------------------------------------
BEGIN:
	call CHECK_MEMORY
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START