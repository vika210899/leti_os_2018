TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ
PC_TYPE			db		'PC Type:  ',0dh,0ah,'$'
SYSTEM_VERSION	db		'System version:  .  ',0dh,0ah,'$'
OEM_NUMBER		db		'OEM number:      ',0dh,0ah,'$'
SERIAL_NUMBER	db		'User serial number:               ',0dh,0ah,'$'
; ПРОЦЕДУРЫ
;-----------------------------------------------------------
Write_msg		PROC	near
		mov		ah,09h
		int		21h
		ret
Write_msg		ENDP
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
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
WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа
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
BYTE_TO_DEC		PROC	near
; перевод в 10 с/с, SI - адрес поля младшей цифры
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
GET_PC_TYPE 	PROC	near
; Функция определяющая тип PC
		push 	es
		push	bx
		push	ax
		mov		bx,0f000h
		mov 	es,bx
		mov 	ax,es:[0fffeh]
		mov		ah,al
		call 	BYTE_TO_HEX
		lea		bx,PC_TYPE
		mov		[bx+9],ax
		pop		ax
		pop		bx
		pop		es
		ret
GET_PC_TYPE		ENDP
;----------------------------
GET_SYS_VER		PROC	near
; Функция определяющая версию системы
		push	ax
		push 	si
		lea		si,SYSTEM_VERSION
		add		si,16
		call	BYTE_TO_DEC
		add		si,3
		mov 	al,ah
		call	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
GET_SYS_VER		ENDP
;---------------------------
GET_OEM_NUM		PROC	near
; функция определяющая OEM
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si,OEM_NUMBER
		add		si,14
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
GET_OEM_NUM		ENDP
;--------------------------
GET_SERIAL_NUM	PROC	near
		push	ax
		push	bx
		push	cx
		push	si
		mov		al,bl
		call	BYTE_TO_HEX
		lea		di,SERIAL_NUMBER
		add		di,22
		mov		[di],AX
		mov		ax,cx
		lea		di,SERIAL_NUMBER
		add		di,27
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop		ax
		ret
GET_SERIAL_NUM	ENDP
BEGIN:
; определяем нужную информацию
		call 	GET_PC_TYPE
		mov		ah,30h
		int		21h
		call	GET_SYS_VER
		call	GET_OEM_NUM
		call	GET_SERIAL_NUM
; выводим информацию
		lea		dx,PC_TYPE
		call	Write_msg
		lea		dx,SYSTEM_VERSION
		call	Write_msg
		lea		dx,OEM_NUMBER
		call	Write_msg
		lea		dx,SERIAL_NUMBER
		call	Write_msg
; выход в DOS
		xor		al,al
		mov		ah,3Ch
		int		21h
		ret
TESTPC	ENDS
		END 	START