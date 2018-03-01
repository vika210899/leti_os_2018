TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	JMP BEGIN
	
EOF	EQU '$'
endl db 0DH,0AH,EOF
str_inaccess_mem db 'Segment address with the first unavailable byte:', EOF
str_inaccess_mem_empty db '     ',EOF
str_env_address db 'Address of an environment segment:',EOF
str_env_address_empty db '    ',EOF
str_tail db 'Argv:',EOF
str_tail_empty db 64 DUP(' '),EOF
str_tail_err db 'No argv!',EOF
str_env_content db 'Content of the environment:',0DH,0AH,EOF
str_path db 'Path of the loaded module:',0DH,0AH,EOF

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

; Печать адреса недоступной памяти
PRINT_INACCESIBLE_MEMORY proc near
	push ax
	push di
	push dx
	
	mov ax,ss:[2]
	mov di, offset str_inaccess_mem_empty+3
	call WRD_TO_HEX
	
	mov dx, offset str_inaccess_mem
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	mov dx , offset str_inaccess_mem_empty
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	
	pop dx
	pop di
	pop ax
	ret
PRINT_INACCESIBLE_MEMORY ENDP

; Печать сегментного адреса среды
PRINT_ENV_ADDRES PROC near
	push ax
	push di
	push dx
	
	mov ax,ss:[2Ch]
	mov di, offset str_env_address_empty+3
	call WRD_TO_HEX
	
	mov dx, offset str_env_address
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	mov dx, offset str_env_address_empty
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	
	pop dx
	pop di
	pop ax
	ret
PRINT_ENV_ADDRES ENDP

; Печатает аргументы командой строки
PRINT_ARGV PROC near
	push cx
	push dx
	push bx
	
	xor ch,ch
	mov cl,ss:[80h]
	
	cmp cl,0
	jne TailExist
	mov dx, offset str_tail_err
	call PRINT_DX
	mov dx, offset endl
	call PRINT_DX
	pop bx
	pop dx
	pop cx
	ret
		
TailExist:
	mov dx, offset str_tail
	call PRINT_DX	
	mov bp, offset str_tail_empty
	print_char:
		mov di,cx
		mov bl,ds:[di+80h]
		mov ds:[bp+di-2],bl
	loop print_char
	mov dx, offset str_tail_empty
	call PRINT_DX
	pop bx
	pop dx
	pop cx
	ret
PRINT_ARGV ENDP

; Печатает содержимое области среды
PRINT_ENV PROC near
	push ax
	push es
	push bp
	push dx

	mov ax,ss:[44]
	mov es,ax
	xor bp,bp
PE_cycle1:
	cmp word ptr es:[bp],1
	je PE_exit1
	cmp byte ptr es:[bp],0
	jne PE_noendl
	mov dx, offset endl
	call PRINT_DX
	inc bp
PE_noendl:
	mov dl,es:[bp]
	mov ah,2
	int 21h
	inc bp
	jmp PE_cycle1
	
	PE_exit1:
	add bp,2
	mov dx, offset endl
	call PRINT_DX
	mov dx, offset str_path
	call PRINT_DX
PE_cycle2:
	cmp byte ptr es:[bp],0
	je PE_exit2
	mov dl,es:[bp]
	mov ah,2
	int 21h
	inc bp
	jmp PE_cycle2	
PE_exit2:

	pop dx
	pop bp
	pop es
	pop ax
	ret
PRINT_ENV ENDP

BEGIN:
	mov dx, offset endl
	call PRINT_DX
	call PRINT_INACCESIBLE_MEMORY
	mov dx, offset endl
	call PRINT_DX	
	call PRINT_ENV_ADDRES
	mov dx, offset endl
	call PRINT_DX	
	call PRINT_ARGV
	mov dx, offset endl
	call PRINT_DX
	mov dx, offset str_env_content
	call PRINT_DX
	call PRINT_ENV
	mov dx, offset endl
	call PRINT_DX
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START