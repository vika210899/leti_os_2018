TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN


	IbmPC				db		'IBM PC code: ','$'
	SystVer				db		'Sys version:  .  ',0dh,0ah,'$'
	SerOEMNumb			db		'Serial OEM number:      ',0dh,0ah,'$'
	UserSer				db		'User serial number:    ','$'
	PC 				    db 		'PC',0dh,0ah,'$'
	PX				    db		'PC/XT',0dh,0ah,'$'
	PCAT			    db 		'AT',0dh,0ah,'$'
	PS2model30 			db 		'PS2 model 30',0dh,0ah,'$'
	PS2model80			db 		'PS2 model 80',0dh,0ah,'$'
	PCjr 				db 		'PCjr',0dh,0ah,'$'
	PCConv 				db 		'PC Convertible',0dh,0ah,'$'
	Nul					db		3,?,3

	
;-----------------------------------------------------------
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near	; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near	; первод в 16 с/с 16-ти разрядного числа
								; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		xor		ah,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;----------------------------
BYTE_TO_DEC		PROC	near	; перевод в 10 с/с, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
loop_bd:div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_bd
		cmp		ax,00h
		jbe		end_l
		or		al,30h
		mov		[si],al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP
;---------------------------
IDENT_IBM_PC	PROC	near ; Определение типа IBM PC
		push 	es
		push	bx
		push	ax
		mov		bx,0f000h
		mov 	es,bx
		mov 	al,es:[0fffeh]
		lea		dx, IbmPC
		call 	Write
		
		cmp al, 0ffh
		jnz mPX_1
		lea dx, PC
		jmp exit
	mPX_1:
		cmp al, 0feh
		jnz mPX_2
		lea dx, PX
		jmp exit
	mPX_2:
		cmp al, 0fbh
		jnz mAT
		lea dx, PX
		jmp exit
	mAT:
		cmp al, 0fch
		jnz mPS2_30
		lea dx, PCAT
		jmp exit
	mPS2_30:
		cmp al, 0fah
		jnz mPS2_80
		lea dx, PS2model30
		jmp exit
	mPS2_80:
		cmp al, 0f8h
		jnz mPCjr
		lea dx, PS2model80
		jmp exit
	mPCjr:
		cmp al, 0fdh
		jnz mPC_C
		lea dx, PCjr
		jmp exit
	mPC_C:
		cmp al, 0f9h
		jnz last
		lea dx, PCConv
		jmp exit	
	last:
		lea bx, Nul
		mov [bx],al
		lea dx, Nul
	exit:
		call Write
		
		pop		ax
		pop		bx
		pop		es
		ret
IDENT_IBM_PC	ENDP
;--------------------------
IDENT_SYS_VER	PROC	near	; Определение версии системы
		push	ax
		push 	si
		lea		si,SystVer
		add		si,13
		call	BYTE_TO_DEC
		add		si,3
		mov 	al,ah
		call	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
IDENT_SYS_VER	ENDP
;---------------------------
IDENT_OEM_SER		PROC	near	; Определение серийного номера OEM
		push	ax
		push	si
		mov 	al,bh
		lea		si,SerOEMNumb
		add		si,21
		call	BYTE_TO_DEC
		pop		si
		pop		ax
		ret
IDENT_OEM_SER		ENDP
;--------------------------
IDENT_USER_SER		PROC	near	; Определение серийного номера пользователя
		push	ax
		mov		al,bl
		call	BYTE_TO_HEX
		lea		di,UserSer
		add		di,20
		mov		[di],ax
		mov		ax,cx
		lea		di,UserSer
		add		di,25
		call	WRD_TO_HEX
		pop		ax
		ret
IDENT_USER_SER		ENDP
;--------------------------
Write		PROC	near
		mov		ah,09h
		int		21h
		ret
Write	ENDP
;--------------------------
BEGIN:
		call 	IDENT_IBM_PC
		mov		ah,30h
		int		21h
		call	IDENT_SYS_VER
		call	IDENT_OEM_SER
		call	IDENT_USER_SER

		lea		dx, SystVer
		call	Write
		lea		dx, SerOEMNumb
		call	Write
		lea		dx,UserSer
		call	Write

		xor		al,al
		mov		ah,3Ch
		int		21h
		ret
TESTPC	ENDS
		END 	START