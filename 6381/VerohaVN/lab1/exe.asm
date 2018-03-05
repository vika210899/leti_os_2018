EOL EQU '$'

DATA	SEGMENT
	TYPE_PC			db		'PC type:  ',0dh,0ah,'$'
	SYS_VER			db		'MS-DOS version:  .  ',0dh,0ah,'$'
	OEM_NUM			db		'OEM number:      ',0dh,0ah,'$'
	USER_NUM			db		'User serial number:         H',0dh,0ah,'$'
DATA ENDS

CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:AStack
Write_msg		PROC	FAR
		mov		ah,09h
		int		21h
		ret
Write_msg		ENDP

AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS

TETR_TO_HEX		PROC	FAR
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC FAR
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
WRD_TO_HEX		PROC	FAR
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
BYTE_TO_DEC		PROC	FAR
; перевод в 10 с/с, SI - адрес поля младшей цифры
; AL содержит исходный байт
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

; Процедура определения типа PC
PC_INFO PROC	NEAR
		push 	es
		push	bx
		push	ax
		mov		bx,0f000h
		mov 	es,bx
		mov 	ax,es:[0fffeh]
		mov		ah,al
		call 	BYTE_TO_HEX
		lea		bx,TYPE_PC
		mov		[bx+9],ax
		pop		ax
		pop		bx
		pop		es
		ret
PC_INFO	ENDP
;----------------------------
; Процедура определения версии MS-DOS
SYSTEM_INFO	PROC	NEAR
	push	AX
	push	SI
	
	lea	SI,SYS_VER
	add	SI,16
	call	BYTE_TO_DEC

	lea	SI,SYS_VER
	add	SI,19
	mov	AL,AH
	call	BYTE_TO_DEC

	pop	SI
	pop	AX
	ret
SYSTEM_INFO	ENDP
;---------------------------
OEM_INFO		PROC	FAR
; функция определяющая OEM
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si,OEM_NUM
		add		si,14
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
OEM_INFO		ENDP
;--------------------------
USER_INFO		PROC	FAR
		push	ax
		push	bx
		push	cx
		push	si
		mov		al,bl
		call	BYTE_TO_HEX
		lea		di,USER_NUM
		add		di,22
		mov		[di],AX
		mov		ax,cx
		lea		di,USER_NUM
		add		di,27
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop		ax
		ret
USER_INFO	ENDP
Main      		PROC  FAR
		push  	DS
    	sub   	AX,AX
    	push  	AX
    	mov   	AX,DATA
    	mov   	DS,AX
    	sub   	AX,AX
		call 	PC_INFO
		mov		ah,30h
		int		21h
		call	SYSTEM_INFO
		call	OEM_INFO
		call	USER_INFO
; выводим информацию
		lea		dx,TYPE_PC
		call	Write_msg
		lea		dx,SYS_VER
		call	Write_msg
		lea		dx,OEM_NUM
		call	Write_msg
		lea		dx,USER_NUM
		call	Write_msg
; выход в DOS
		xor		al,al
		mov		ah,3Ch
		int		21h
		ret
Main    		ENDP
CODE			ENDS
				END Main