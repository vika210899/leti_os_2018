TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN
; ДАННЫЕ
lock_mem db 13, 10, "Locked memory address:     h$" 
environment db 13, 10, "Environment address:     h$" 
tail db 13, 10, "Command line tail:        $" 
emp db 13, 10, "There are not sybmols$"
Env_cont db 13, 10, "Content:", 13, 10, "$"
ent db 13, 10, "$"
path db 13, 10, "Path:", 13, 10, "$" 

;ПРОЦЕДУРЫ
;-------------------------------
;вывод строки
WRITE PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-------------------------------
;вывод нужной информации
INTERFACE PROC near 
	; Memory
	mov ax, ds:[02h]        ;сегментный адрес первого байта недоступной памяти
	mov di, offset lock_mem
	add di, 28
	call WRD_TO_HEX         ;переводим в 16 с.с
	mov dx, offset lock_mem 
	call WRITE
	
	; Environment
	mov ax, ds:[2Ch]        ;сегментный адрес среды
	mov di, offset environment
	add di, 26
	call WRD_TO_HEX         ;переводим в 16 с.с
	mov dx, offset environment
	call WRITE
	
	; Tail
	xor cx, cx
	mov cl, ds:[80h]       ;число символов в хвосте
	mov si, offset tail
	add si, 20
	test cl, cl
	jz empty               ;если хвост пустой
	xor di, di
	xor ax, ax
	readtail:              
		mov al, ds:[81h+di] ;хвост 
		mov [si], al
		inc di
		inc si
		loop readtail
		mov dx, offset tail 
		call WRITE
		jmp nextaction
	empty:
		mov dx, offset emp ;вывод сообщения, что хвост пустой
		call WRITE
	nextaction: nop
	
;Вывод содержимого области среды, в символьном виде и путей загружаемого модуля
	mov dx, offset Env_cont
	call WRITE
	xor di, di
	mov bx, 2Ch
	mov ds, [bx]
	readstring:
		cmp byte ptr [di], 00h
		jz pressenter
		mov dl, [di]
		mov ah, 02h
		int 21h
		jmp findend
	pressenter:
		push ds
		mov cx, cs
		mov ds, cx
		mov dx, offset ent
		call WRITE
		pop ds
	findend:
		inc di
		cmp word ptr [di], 0001h
		jz readpath
		jmp readstring
	readpath:
		push ds
		mov ax, cs
		mov ds, ax
		mov dx, offset path
		call WRITE
		pop ds
		add di, 2
	pathloop:
		cmp byte ptr [di], 00h
		jz final
		mov dl, [di]
		mov ah, 02h
		int 21h
		inc di
		jmp pathloop
	final:
		ret
INTERFACE ENDP
;-------------------------------

;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------
; КОД
BEGIN:   
		   call INTERFACE
		   mov ah, 10h
		   int 16h
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START     ;конец модуля, START - точка входа
