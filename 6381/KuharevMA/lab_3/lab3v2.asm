testpc segment
		assume cs:testpc, ds: testpc, es:nothing, ss:nothing
		org 100h
start: jmp begin

;data segment

AVAILABLE_MEMORY db "Available memory:        (bytes)", 0dh, 0ah, '$'
EXTENDED_MEMORY db "Extended memory:       (kbytes)", 0dh, 0ah, '$'

NEW_LINE db 0dh, 0ah, '$'

TABLE_TITLE db "| MSB Adress | MSB Type | PSP Address | Size(Para) | SC/SD    |", 0dh, 0ah, '$'
TABLE_DATA  db "                                                               ", 0dh, 0ah, '$'

;end data segment

;--------------------------------------------------------------------------------
PRINT_STRING PROC near
		push ax
		mov 	ah, 09h
		int		21h
		pop ax
		ret
PRINT_STRING ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX PROC near
;байт AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX 
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;в AL - старшая, в AH - младшая
	pop CX
	ret
BYTE_TO_HEX ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
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
;--------------------------------------------------------------------------------
BYTE_TO_DEC PROC near
;перевод в 10с/с, SI - адрес поля младшей цифры
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
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;--------------------------------------------------------------------------------
WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
loop_b: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_b
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
endl:	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP
;--------------------------------------------------------------------------------
GET_AVAILABLE_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si

	xor ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h

	mov ax, 10h
	mul bx

	mov si, offset AVAILABLE_MEMORY
	add si, 017h
	call WRD_TO_DEC

	mov dx, offset AVAILABLE_MEMORY
	call PRINT_STRING

	pop si
	pop dx
	pop bx
	pop ax

	ret
GET_AVAILABLE_MEMORY ENDP
;--------------------------------------------------------------------------------
GET_EXTENDED_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si

	xor dx, dx

	mov al, 30h
    out 70h, al
    in al, 71h 
    mov bl, al 
    mov al, 31h  
    out 70h, al
    in al, 71h

	mov ah, al
	mov al, bl

	mov si, offset EXTENDED_MEMORY
	add si, 015h
	call WRD_TO_DEC

	mov dx, offset EXTENDED_MEMORY
	call PRINT_STRING

	pop si
	pop dx
	pop bx
	pop ax

	ret
GET_EXTENDED_MEMORY ENDP
;--------------------------------------------------------------------------------
GET_MCB_DATA PROC near
	;msb address
	mov di, offset TABLE_DATA
	mov ax, es
	add di, 05h
	call WRD_TO_HEX

	;msb type
	mov di, offset TABLE_DATA
	add di, 0Fh
	xor ah, ah
	mov al, es:[00h]
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	
	;psp adress
	mov di, offset TABLE_DATA
	mov ax, es:[01h]
	add di, 1Dh
	call WRD_TO_HEX

	;size
	mov di, offset TABLE_DATA
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	add di, 2Eh
	push si
	mov si, di
	call WRD_TO_DEC
	pop si

	;sc/sd
	mov di, offset TABLE_DATA
	add di, 35h
    mov bx, 0h
	GET_8_BYTES:
        mov dl, es:[bx + 8]
		mov [di], dl
		inc di
		inc bx
		cmp bx, 8h
	jne GET_8_BYTES

	mov ax, es:[03h]
	mov bl, es:[00h]

	ret
GET_MCB_DATA ENDP

GET_ALL_MSB_DATA PROC NEAR
	mov ah, 52h
	int 21h
	sub bx, 2h
	mov es, es:[bx]

FOR_EACH_MSB:
		call GET_MCB_DATA
		mov dx, offset TABLE_DATA
		call PRINT_STRING

		mov cx, es
		add ax, cx
		inc ax
		mov es, ax

		cmp bl, 4Dh
		je FOR_EACH_MSB
GET_ALL_MSB_DATA ENDP

begin:
    call GET_AVAILABLE_MEMORY
    call GET_EXTENDED_MEMORY

	mov ah, 4ah
	mov bx, offset END_OF_PROGRAMM
	int 21h


	mov dx, offset NEW_LINE
	call PRINT_STRING

	mov dx, offset TABLE_TITLE
	call PRINT_STRING

	call GET_ALL_MSB_DATA

	xor al, al
	mov ah, 4Ch
	int 21h

	END_OF_PROGRAMM db 0
testpc ends
end start