.MODEL SMALL
.STACK 200h
.DATA
hex db '    $'
endl db 0DH,0AH,'$'
str_os_type db 'OS type: $'
str_os_type_not_interpret db 'Can not be interpreted: $'
str_os_version db 'OS version:   .  ',0DH,0AH,'$'
str_oem db 'OEM:    ',0DH,0AH,'$' ;
str_usnumber db 'User serial number: ','$'
str_pc db 'PC',0DH,0AH,'$'
str_pc_xt db 'PC/XT',0DH,0AH,'$'
str_at db 'AT',0DH,0AH,'$'
str_ps2_30 db 'PS2 model 30',0DH,0AH,'$'
str_ps2_80 db 'PS2 model 80',0DH,0AH,'$'
str_pc_jr db 'PCjr',0DH,0AH,'$'
str_pc_convert db 'PC Convertible',0DH,0AH,'$'

.CODE
START: JMP BEGIN

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

; Вывод типа ОС.
PRINT_OS_TYPE proc near
	mov dx, offset str_os_type
	call PRINT_DX
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh
	
	cmp al,0FFh
	je pc
	cmp al,0FEh
	je pc_xt
	cmp al,0FBh
	je pc_xt
	cmp al,0FCh
	je at
	cmp al,0FAh
	je ps2_30
	cmp al,0F8h
	je ps2_80
	cmp al,0FDh
	je pc_jr
	cmp al,0F9h
	je pc_convert
	jmp type_error
	
	pc:
		mov dx, offset str_pc
		jmp type_success
	pc_xt:
		mov dx, offset str_pc_xt
		jmp type_success
	at:
		mov dx, offset str_at
		jmp type_success
	ps2_30:
		mov dx, offset str_ps2_30
		jmp type_success
	ps2_80:
		mov dx, offset str_ps2_80
		jmp type_success
	pc_jr:
		mov dx, offset str_pc_jr
		jmp type_success
	pc_convert:
		mov dx, offset str_pc_convert
		jmp type_success
	
	type_success:
		call PRINT_DX
	ret
	
	type_error:
		mov dx, offset str_os_type_not_interpret
		call PRINT_DX
		call BYTE_TO_HEX
		mov bx,ax
		mov dl,bl
		mov ah,02h
		int 21h
		mov dl,bh
		int 21h
	ret
PRINT_OS_TYPE endp

; Вывод версии ОС.
PRINT_OS_VERSION proc near
	xor ax,ax
	mov ah,30h
	int 21h
	
	mov si, offset str_os_version
	add si,13
	push ax
	call BYTE_TO_DEC
	pop ax
	
	mov al,ah
	add si,3
	cmp al,10
	jl cov_one_digit_l
	inc si
	cov_one_digit_l:
	call BYTE_TO_DEC
	mov dx, offset str_os_version
	call PRINT_DX
	ret
PRINT_OS_VERSION ENDP

; Вывод ОЕМ
PRINT_OEM proc near
	xor ax,ax
	mov ah,30h
	int 21h

	mov si, offset str_oem
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	
	mov dx, offset str_oem
	call PRINT_DX
	ret
PRINT_OEM endp

; Вывод серийного номера
PRINT_USNUMBER PROC NEAR
	xor ax,ax
	mov ah,30h
	int 21h
	mov dx, offset str_usnumber
	call PRINT_DX
	
	mov  al,bl
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	
	mov di, offset hex
	add di,3
	mov ax,cx
	call WRD_TO_HEX
	mov dx, offset hex
	call PRINT_DX
	
	mov dx, offset endl
	call PRINT_DX
	ret
PRINT_USNUMBER ENDP


BEGIN:
	mov   AX,@data
	mov   DS,AX
	call PRINT_OS_TYPE
	call PRINT_OS_VERSION
	call PRINT_OEM
	call PRINT_USNUMBER
	xor AL,AL
	mov AH,4Ch
	int 21H
 END START