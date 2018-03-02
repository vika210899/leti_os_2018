CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

; данные
ADDR_MEM DB 'Segment address of first byte of not available memory=    ', 0AH, 0DH,'$'
ADDR_ENV DB 'Segment address of environment=    ', 0AH, 0DH, '$'
TAIL_OF_CMD DB 'The tail of cmd promt=' , '$'
NEW_LINE DB  0AH, 0DH, '$'
ENV DB 0AH, 0DH,'Enviroment:', 0AH, 0DH, '$'
PATH_TO_PROG DB 'Path of the loaded modul=', '$'
; процедуры
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX           ;в AH младшая
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ;перевод в 16 с/с 16-ти разрядного числа
	push BX          ; в AX - число, DI - адрес последнего символа
	mov BH,AH        ;  now it aclually converts byte to string, last sybmol adress is di
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

BYTE_TO_DEC PROC near ; перевод байта в 10с/с, SI - адрес поля младшей цифры
	push	AX        ; AL содержит исходный байт
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
	pop	AX
	ret
BYTE_TO_DEC ENDP

print_addr_env proc near
	mov dx, offset ENV
	mov ah, 09h
	int 21h
	mov bx, 2Ch
	mov ax, [bx]
	mov ds, ax
	mov di,0
	mov dx, di
	cicl:
		cmp byte ptr [di], 0
		je exit
		cf:
			inc di
			cmp byte ptr [di], 0
			jne cf
			mov byte ptr [di], '$'
				mov ah, 09h
				int 21h
				push dx
				push ds
				push es
				mov dx, offset NEW_LINE
				pop ds
				int 21h
				pop ds
				pop dx
			mov byte ptr [di], 0h ; восстанвливаем 0
			inc di
			mov dx, di
			jmp cicl
	exit:
	push es
	pop ds
	mov dx, offset NEW_LINE
	mov ah, 09h
	int 21h
	ret
print_addr_env endp

print_tail_of_cmd_str proc near
	mov dx, offset TAIL_OF_CMD
	mov ah, 09h
	int 21h
	mov bx, 80h		;число символов в строке
	mov al, [bx] 
	cmp al, 0
	je empty
		mov ah, 0
		mov di, ax
		mov al, [di+81h]
		push ax
		mov byte ptr [di+81h], '$'
		mov dx, 81h
		mov ah, 09h
		int 21h
		pop ax
		mov [di+81h], al
	empty:
	mov dx, offset NEW_LINE
	mov ah, 09h
	int 21h
	ret
print_tail_of_cmd_str endp

print_path_to_prog proc near ; В DI хранится адрес конца среды
	mov dx, offset PATH_TO_PROG
	mov ah, 09h
	int 21h
	mov bx, 2Ch
	mov ax, [bx]
	mov ds, ax
	add di, 3
	mov dx, di
	find:
	inc di
	cmp byte ptr [di], 0
	jne find
	mov byte ptr [di], '$'
		mov ah, 09h
		int 21h
	mov byte ptr [di], 0h ; восстанвливаем 0
	push es
	pop ds
	ret
print_path_to_prog endp

BEGIN:
	push DS 
	sub AX,AX 
	push AX 
	
	; 1)Сегметный адрес недоступной памяти 
	mov bx, 2h
	mov ax, [bx]
	mov DI, OFFSET (ADDR_MEM+57)
	call WRD_TO_HEX
	mov dx, offset ADDR_MEM
	mov ah, 09h
	int 21h
	
	; 2)Сегметный адрес среды
	mov bx, 2ch
	mov ax, [bx]
	mov DI, OFFSET (ADDR_ENV+34)
	call WRD_TO_HEX
	mov dx, offset ADDR_ENV
	mov ah, 09h
	int 21h

	; 3)Хвост командной строки
	call print_tail_of_cmd_str
	
	; 4)Содержимое области среды
	call print_addr_env
	
	; 5)Путь загружаемого модуля
	call print_path_to_prog
	
	; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END START