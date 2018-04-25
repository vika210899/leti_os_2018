TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: 	JMP	BEGIN

;ДАННЫЕ
AvailableMemory	db 'Amount of available memory:                                        ', 0DH, 0AH, '$'
ExtendedMemory	db 'Size of extended memory:                                           ', 0DH, 0AH, '$'
MCBData		 	db '| MCB Address |  MCB Type  | PSP Address |    Size    |   SC/SD    |', 0DH, 0AH, '$'
MCB 			db '|             |            |             |            |            |', 0DH, 0AH, '$'
Line 			db '--------------------------------------------------------------------', 0DH, 0AH, '$'

TETR_TO_HEX		PROC near
		and		al, 0Fh 
		cmp		al, 09
		jbe		NEXT
		add		al, 07
	NEXT:	add		al, 30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near
		push	cx
		mov		ah, al
		call	TETR_TO_HEX
		xchg	al, ah
		mov		cl, 4 
		shr		al, cl
		call	TETR_TO_HEX
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	near
		push	bx
		mov		bh, ah 
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di 
		mov		[di], al
		dec		di
		mov		al, bh
		xor		ah, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		pop		bx
		ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC		PROC	near
		push	cx
		push	dx
		push	ax
		xor		ah, ah
		xor		dx, dx
		mov		cx, 10 
	loop_bd:div		cx 
		or 		dl, 30h
		mov 	[si], dl
		dec 	si
		xor		dx, dx
		cmp		ax, 10
		jae		loop_bd
		cmp		ax, 00h
		jbe		end_l
		or		al, 30h
		mov		[si], al
	end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP	

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

FIND_AVAILABLE_MEMORY PROC NEAR
	xor ax, ax
	mov ah, 4Ah 
	mov bx, 0FFFFh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset AvailableMemory
	add si, 21h
	call WRD_TO_DEC	
	
	mov dx, offset AvailableMemory
	call PRINT_STR
	
	ret
FIND_AVAILABLE_MEMORY ENDP

FIND_EXTENDED_MEMORY PROC NEAR
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
	mov si, offset ExtendedMemory
	add si, 1Dh
	call WRD_TO_DEC	

	mov dx, offset ExtendedMemory
	call PRINT_STR

	ret
FIND_EXTENDED_MEMORY ENDP

FIND_MCB PROC near 
	mov di, offset MCB
	mov ax, es
	add di, 8h
	call WRD_TO_HEX

	mov di, offset MCB
	add di, 15h
	xor ah, ah
	mov al, es:[00h]
	call WRD_TO_HEX

	mov al, 20h
	mov [di], al
	inc di
	mov [di], al
	mov di, offset MCB
	mov ax, es:[01h]
	add di, 23h
	call WRD_TO_HEX

	mov di, offset MCB
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	add di, 32h
	push si
	mov si, di
	call WRD_TO_DEC

	pop si
	mov di, offset MCB
	add di, 3Ah
    mov bx, 0h

	SC_SD:
        mov dl, es:[bx + 8]
		mov [di], dl
		inc di
		inc bx 
		cmp bx, 8h
	jne SC_SD

	mov ax, es:[03h]
	mov bl, es:[00h]

	mov dx,offset MCB 
	call PRINT_STR

	ret
FIND_MCB ENDP

PRINT_STR PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_STR ENDP

BEGIN:

	call FIND_AVAILABLE_MEMORY

	mov ah, 4ah
	mov bx, offset MemSize
	int 21h

	call FIND_EXTENDED_MEMORY

	mov dx, offset Line
	call PRINT_STR

	mov dx, offset MCBData	
	call PRINT_STR

	mov dx, offset Line
	call PRINT_STR

	mov ah,52h
	int 21h
	sub bx,2h
	mov es,es:[bx]
	
loop_mcb:
	call FIND_MCB

	mov cx,es
	add ax,cx
	inc ax
	mov es,ax
	cmp bl,5Ah
	jne loop_mcb
	
	mov dx, offset Line
	call PRINT_STR
	
	mov ax, 4c00h
	int 21h

MemSize db 0
TESTPC 	ENDS
		END START