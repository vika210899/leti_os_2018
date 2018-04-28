TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

Error1	 	db  'Error 1!',0dh,0ah,'$'
Error2	 	db  'Error 2!',0dh,0ah,'$'
AvlMem 		db  'Available memory:          bytes',0dh,0ah,'$'
ExtMem  	db  'Extended memory:           Kbytes',0dh,0ah,'$'
MCBHead  	db  'List of Lists:',0dh,0ah,'$'
MCBType  	db  'MCB Type:   h - $'
MCBSeg  	db  'Address:     h - $'
MCBSize  	db  'MCB Size:       byte - $'
MCBName  	db  'Name:               ',0dh,0ah,'$'

;-----------------------------------------------------------
TETR_TO_HEX		PROC	near	; Функция перевода из 2 с/с в 16 половины байта
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;-----------------------------------------------------------
BYTE_TO_HEX		PROC near	; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP
;-----------------------------------------------------------
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
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;-----------------------------------------------------------
BYTE_TO_DEC		PROC	near	; перевод одного байта в 10 с/с, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
	loop_bd:
		div		cx
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
	end_l:	
		pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP
;-----------------------------------------------------------
WRD_TO_DEC		PROC	near	; перевод 2 байтов в 10 с/с, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		mov		cx,10
	loop_wrd:
		div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_wrd
		cmp		ax,00h
		jbe		end_wrl
		or		al,30h
		mov		[si],al
	end_wrl:	
		pop		ax
		pop		dx
		pop		cx
		ret
WRD_TO_DEC		ENDP
;-----------------------------------------------------------
IDENT_AVL_MEM    PROC    near
		push 	ax
		push 	bx
		push 	cx
		push 	dx
		mov 	bx, 0ffffh
		mov 	ah, 4Ah
		int 	21h
		mov 	ax, bx
		mov 	cx, 10h
		mul 	cx
		lea  	si, AvlMem +25
		call 	WRD_TO_DEC
		lea		dx, AvlMem 
		call 	WRITE
		
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		ret
IDENT_AVL_MEM   	ENDP
;-----------------------------------------------------------
IDENT_EXT_MEM    	PROC    near
		push 	ax
		push 	bx
		push 	si
		push 	dx
		mov		al, 30h 
		out		70h, al 
		in		al, 71h 
		mov		bl, al 
		mov		al, 31h 
		out		70h, al
		in		al, 71h 
		
		mov 	ah, al
		mov 	al, bl 
		xor 	dx, dx
		lea 	si, ExtMem+25
		call 	WRD_TO_DEC
		lea 	dx, ExtMem
		call 	WRITE
		pop		dx
		pop		si
		pop		bx
		pop		ax
		ret
IDENT_EXT_MEM    	ENDP
;-----------------------------------------------------------
IDENT_MCB	PROC 	near
		push 	ax
		push 	bx
		push 	cx
		push 	dx
		lea		dx, MCBHead
		call	WRITE
		mov		ah,52h
		int		21h
		mov		es, es:[bx-2]
		mov		bx, 1
	NotLast:
		xor		ax, ax
		xor		cx, cx
		xor		di, di
		xor		si, si
		mov		al, es:[00h]
		call 	BYTE_TO_HEX
		lea		di,MCBType+10
		mov		[di],ax
		cmp 	byte ptr es:[00h],5Ah
		je 		Last
	NextBlock:
		lea		di, MCBSeg+12
		mov		ax, es:[01h]
		call 	WRD_TO_HEX
		mov		ax, es:[03h]
		mov 	cx, 10h
    	mul 	cx
    	lea		si, MCBSize+15
		call 	WRD_TO_DEC
		lea		dx, MCBType
		call 	WRITE
		lea		dx, MCBSeg
		call 	WRITE
		lea		dx, MCBSize
		call 	WRITE
		lea		si, MCBName+7
		call 	IDENT_END
		lea		dx, MCBName
		call 	WRITE
		cmp		bx,0
		jz		Exit
		xor 	ax, ax
    	mov 	ax, es
    	add 	ax, es:[03h]
    	inc 	ax
    	mov 	es, ax
		jmp 	NotLast
	Exit:
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		ret	
	Last:
		mov		bx,0
		jmp 	NextBlock
IDENT_MCB	ENDP
;-----------------------------------------------------------
IDENT_END	PROC	near
		push 	bx
		push 	ax
		mov		bx, 08h
		mov		ax, es:[bx]
		mov		[si], ax
		mov		ax, es:[bx+2]
		mov		[si+2], ax
		mov		ax, es:[bx+4]
		mov		[si+4], ax
		mov		ax, es:[bx+6]
		mov		[si+6], ax
		pop		ax
    	pop		bx
		ret
IDENT_END	ENDP
;-----------------------------------------------------------
WRITE	PROC	near
		mov		ah,09h
		int		21h
		ret
WRITE	ENDP
;-----------------------------------------------------------
BEGIN:
		mov 	bx, 0ffffh
		mov 	ah, 4Ah
		int 	21h
		mov 	ax, bx
		mov 	cx, 10h
		mul 	cx
		lea  	si, AvlMem + 25
		call 	WRD_TO_DEC
		lea		dx, AvlMem
		call 	WRITE
			
		mov		bx, 1000h
		mov		ah, 48h
		int		21h
		
		jnc 	no_error_1
		lea 	dx, Error1
		call 	WRITE
		jmp		 EndR
		
	no_error_1:
		lea 	ax, Endl
		mov 	bx, 10h
		xor 	dx, dx
		div 	bx
		inc 	ax
		mov 	bx, ax
		mov 	ah, 4Ah
		int 	21h	
		
		jnc 	no_error_2
		lea 	dx, Error2
		call 	WRITE
		jmp 	EndR
	no_error_2:
		call 	IDENT_EXT_MEM 
		call 	IDENT_MCB
	Endr:
		xor		al,al
		mov		ah,4Ch
		int		21h
	Endl:
TESTPC	ENDS
		END 	START