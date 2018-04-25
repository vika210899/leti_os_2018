TESTPC	SEGMENT 
        ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING 
        org 100H	
				
START:  JMP BEGIN	

;data segment

NOT_AVAILABLE_MEMORY db "Not available memery address:          ", 0dh, 0ah, '$'
ENVIRONMENT_SEGMENT_ADDRESS db "Environment segment address:         ", 0dh, 0ah, '$'
ENVIRONMENT_DATA db "Environment data: ", 0dh, 0ah, '$'


END_OF_LINE db " ", 0dh, 0ah, '$'

START_PATH db "Start directory: ", 0dh, 0ah, '$'

COMMAND_TEXT db "Command Tail: "
COMMAND_TAIL db "                                                           ", 0dh, 0ah, '$'

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
GET_NOT_AVAILABLE_MEMORY PROC NEAR
	push ax
	push di
	
	mov ax, ds:[02h] 
	mov di, offset NOT_AVAILABLE_MEMORY
	add di, 020h
	call WRD_TO_HEX

	mov dx, offset NOT_AVAILABLE_MEMORY
	call PRINT_STRING
	
	pop di
	pop ax
	ret
GET_NOT_AVAILABLE_MEMORY ENDP
;--------------------------------------------------------------------------------
GET_ENVIRONMENT_SEGMENT_ADDRESS PROC NEAR
	push ax
	push di
	
	mov ax, ds:[02Ch] 
	mov di, offset ENVIRONMENT_SEGMENT_ADDRESS
	add di, 01Fh
	call WRD_TO_HEX

	mov dx, offset ENVIRONMENT_SEGMENT_ADDRESS
	call PRINT_STRING
	
	pop di
	pop ax
	ret
GET_ENVIRONMENT_SEGMENT_ADDRESS ENDP
;--------------------------------------------------------------------------------
GET_COMMAND_TAIL PROC NEAR
	push ax
	push bx
	push cx
	push dx

	push si
	push di

	mov si, 80h
	xor cx, cx
	mov cl, byte ptr cs:[si]
	mov bx, offset COMMAND_TAIL

	inc si
	cycle_begin:
		cmp cl, 0h
		jz cycle_end

		xor ax, ax
		mov al, byte ptr cs:[si]
		mov [bx], al

		add bx, 1
		sub cl, 1
		add si, 1

		jmp cycle_begin
	cycle_end:

	xor ax, ax
	mov al, 0Ah
	mov [bx], al
	inc bx
	mov al, '$'
	mov [bx], al

	mov dx, offset COMMAND_TEXT
	call PRINT_STRING
	mov dx, offset END_OF_LINE
	call PRINT_STRING
	
	pop di
	pop si
	
	pop dx
	pop cx
	pop bx
	pop ax

	ret
GET_COMMAND_TAIL ENDP
;--------------------------------------------------------------------------------
GET_ENVIRONMENT_DATA PROC NEAR
	push ax
	push dx
	push ds	
	push es

	mov dx, offset ENVIRONMENT_DATA
	call PRINT_STRING
	
 	mov ah, 02h
	mov es, ds:[02Ch]
	xor si,si

	cycle1_begin:
		mov dl, es:[si]
		int 21h
		cmp dl, 0h
		je cycle1_end
		inc si
		jmp cycle1_begin
	cycle1_end:

	mov dx, offset END_OF_LINE
	call  PRINT_STRING

	inc si
	mov dl, es:[si]
	cmp dl, 0h
	jne cycle1_begin
 	
	mov dx, offset END_OF_LINE
	call PRINT_STRING
	
	mov dx, offset START_PATH
	call PRINT_STRING
	
	add si, 3h
	mov ah, 02h
	mov es, ds:[02Ch]

	cycle2_begin:
		mov dl, es:[si]
		cmp dl, 0h
		je cycle2_end
		int 21h
		inc si
		jmp cycle2_begin
	cycle2_end:
 	
	pop es
	pop ds
	pop dx
	pop ax
	ret
GET_ENVIRONMENT_DATA ENDP
;--------------------------------------------------------------------------------

begin:

call GET_NOT_AVAILABLE_MEMORY
call GET_ENVIRONMENT_SEGMENT_ADDRESS
call GET_COMMAND_TAIL
call GET_ENVIRONMENT_DATA

xor al, al
mov ah, 4Ch
int 21h
	
TESTPC 	ENDS
		END START

