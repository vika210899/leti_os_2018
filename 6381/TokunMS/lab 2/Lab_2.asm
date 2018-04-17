TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN


UnavailAdr			db		'Segment address of unavailable memory:        ',0dh,0ah,'$'
EnvAdr				db		'Segment address of the environment:        ',0dh,0ah,'$'
FindTail			db		'Command line tail:','$'
EnvContent			db		'Content of the environment: ' , '$'
ModPath				db		'Module path: ' , '$'
ENDL				db		0dh,0ah,'$'


TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX	ENDP
;-----------------------------------------------------------
BYTE_TO_HEX		PROC 	near	; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah, al
		call	TETR_TO_HEX
		xchg	al, ah
		mov		cl, 4
		shr		al, cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP
;-----------------------------------------------------------
WRD_TO_HEX		PROC	near	; перевод в 16 с/с 16-ти разрядного числа
								; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		dec		di
		mov		al, bh
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;-----------------------------------------------------------
IDENT_UN_MEM	PROC	near	; Определение первого байта недоступной памяти
		push	ax
		mov 	ax, es:[2]
		lea		di, UnavailAdr
		add 	di, 42
		call	WRD_TO_HEX
		pop		ax
		ret
IDENT_UN_MEM	ENDP
;-----------------------------------------------------------
IDENT_ADR_ENV		PROC	near	; Определение сегментного адреса среды передаваемой программе
		push	ax
		mov 	ax, es:[2Ch]
		lea		di, EnvAdr
		add 	di, 39
		call	WRD_TO_HEX
		pop		ax
		ret
IDENT_ADR_ENV			ENDP
;-----------------------------------------------------------
INDENT_COM_TAIL	PROC	near 	; Определение хвоста командной строки в символьном виде
		push	ax
		push	cx
		lea 	dx, FindTail   
    	call 	WRITE
    	xor 	ax, ax
		xor 	cx, cx
		mov 	cl, es:[80h]
		test 	cl, cl
		je		EMPTY
		xor 	di,	di
	NEXTS:
		mov 	dl, es:[81h+di]
		mov 	ah, 02h
		int 	21h
		inc 	di
		loop	NEXTS
	EMPTY:
		lea		dx, ENDL
		call	WRITE
    	pop		cx
    	pop		ax
		ret
INDENT_COM_TAIL		ENDP
;-----------------------------------------------------------
IDENT_ENV_CONT		PROC	near	; Определение содержимого области среды и пути к модулю
		push 	es 
		push	ax 
		push	bx 
		push	cx 
		lea		dx, EnvContent
		call	WRITE 
		mov		bx, 1 
		mov		es, es:[2ch] 
		mov		si, 0
	NEXT_EL:
		lea		dx, ENDL
		call	WRITE
		mov		ax,si 
	END_NF:
		cmp 	byte ptr es:[si], 0
		je 		END_AREA 
		inc		si
		jmp 	END_NF
	END_AREA:
		push	es:[si]
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx, es 
		mov		ds, cx 
		mov		dx, ax 
		call	WRITE 
		pop		ds 
		pop		es:[si] 
		cmp		bx, 0 
		je 		FINAL
		inc		si
		cmp 	byte ptr es:[si], 01h 
    	jne 	NEXT_EL
    	lea		dx, ModPath 
    	call	WRITE 
    	mov		bx, 0
    	add 	si, 2 
    	jmp 	NEXT_EL
    FINAL:
		pop		cx 
		pop		bx 
		pop		ax 
		pop		es 
		ret
IDENT_ENV_CONT			ENDP
;-----------------------------------------------------------
WRITE	PROC	near
		mov		ah, 09h
		int		21h
		ret
WRITE	ENDP
;-----------------------------------------------------------
BEGIN:
		call	IDENT_UN_MEM 
		call	IDENT_ADR_ENV	
		lea		dx, UnavailAdr   
		call	WRITE 
		lea		dx, EnvAdr   
		call	WRITE
    	call	INDENT_COM_TAIL
		call	IDENT_ENV_CONT	

		xor		al, al
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START