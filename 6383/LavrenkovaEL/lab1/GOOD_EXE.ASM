DOSSEG
AStack    SEGMENT  STACK
          DW 512 DUP(?)
AStack    ENDS

DATA SEGMENT
MainVersionPC	db	'Main Version PC:  ', 0dh, 0ah,'$'
ModifyNumber	db	'Modify number:  .  ', 0dh, 0ah,'$'
OEM_Code		db	'OEM Code:   ', 0dh, 0ah, '$'
UserSN	        db	'User Serial Number:       ', 0dh, 0ah, '$'

DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack
;--------------------------------------------------------------------------------
PRINT_STRING PROC near
		mov 	ah, 09h
		int		21h
		ret
PRINT_STRING ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC	near
		and		al, 0fh
		cmp		al, 09
		jbe		NEXT
		add		al, 07
NEXT:	add		al, 30h
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near
		push	cx
		mov		al, ah
		call	TETR_TO_HEX
		xchg	al, ah
		mov		cl, 4
		shr		al, cl
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
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
;--------------------------------------------------------------------------------
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
;--------------------------------------------------------------------------------
BEGIN:
		push  ds      
        sub   ax, ax    
        push  ax       
        mov   ax, DATA            
        mov   ds, ax              

		;GetPCVersion
		push	es
		push	bx
		push	ax
		mov 	bx, 0F000h
		mov 	es, bx
		mov 	ax, es:[0FFFEh]
		mov 	ah, al
		call	BYTE_TO_HEX
		lea		bx, MainVersionPC
		mov 	[bx + 17], ax
		pop		ax
		pop 	bx
		pop 	es

		mov 	ah, 30h
		int		21h

		;GetModifyNumber
		push	ax
		push	si
		lea		si, ModifyNumber
		add		si, 15
		call	BYTE_TO_DEC
		add		si, 3
		mov 	al, ah
		call   	BYTE_TO_DEC
		pop 	si
		pop 	ax

		mov 	ah, 30h
		int		21h

		;GetOEM
		push ax
		push bx
		push si
		mov 	al, bh
		lea		si, OEM_Code
		add		si, 12
		call	BYTE_TO_DEC
		pop si
		pop bx
		pop ax

		;GetSerialNumber
		mov 	al, bl
		call	BYTE_TO_HEX
		lea		di, UserSN
		add		di, 20
		mov 	[di], ax
		mov 	ax, cx
		lea		di, UserSN
		add		di, 25
		call	WRD_TO_HEX

		lea		dx, MainVersionPC
		call	PRINT_STRING
		lea		dx, ModifyNumber
		call	PRINT_STRING
		lea		dx, Oem_Code
		call 	PRINT_STRING
		lea		dx, UserSN
		call	PRINT_STRING

		;exit
		xor		al, al
		mov 	ah, 4ch
		int		21h
		ret
CODE ENDS
END  	BEGIN