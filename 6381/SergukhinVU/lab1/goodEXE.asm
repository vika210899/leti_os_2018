AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS

EOL EQU '$'

DATA	SEGMENT
	TYPE_PC			db		'PC type:  ','$'
	SYS_VER			db		'MS-DOS version:  .  ',0dh,0ah,'$'
	OEM_NUM			db		'OEM number:      ',0dh,0ah,'$'
	USER_NUM		db		'User serial number:        ',0dh,0ah,'$'
	
PC			db 'PC',0Dh,0Ah,'$'
PC_XT 		db 'PC/XT',0Dh,0Ah,'$'
AT	 		db 'AT',0Dh,0Ah,'$'
PC2_30 		db 'PC2 model 30',0Dh,0Ah,'$'
PC2_50 		db 'PC2 model 50 or 60',0Dh,0Ah,'$'
PC2_80 		db 'PC2 model 80',0Dh,0Ah,'$'
PCjr 		db 'PCjr',0Dh,0Ah,'$'
PC_Conv 	db 'PC Convertible',0Dh,0Ah,'$'

DATA ENDS

CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:AStack
PrintMsg		PROC	FAR
		mov		ah,09h
		int		21h
		ret
PrintMsg		ENDP


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
GET_PC_INFO PROC	NEAR
		 mov ax, 0F000h		
		 mov es, ax			
	     sub bx, bx
		 mov bh, es:[0FFFEh]	
		 ret

GET_PC_INFO	ENDP
;----------------------------
; Процедура определения версии MS-DOS
GET_SYSTEM_INFO	PROC	NEAR
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
GET_SYSTEM_INFO	ENDP
;---------------------------
GET_OEM_INFO		PROC	FAR
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
GET_OEM_INFO		ENDP
;--------------------------
GET_USER_INFO		PROC	FAR
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
GET_USER_INFO	ENDP
Main      		PROC  FAR
		push  	DS
    	sub   	AX,AX
    	push  	AX
    	mov   	AX,DATA
    	mov   	DS,AX
    	sub   	AX,AX
;Вызываем функцию определения типа РС 		
		call 	GET_PC_INFO
		lea		dx,TYPE_PC
		call	PrintMsg
;Определяем по предпоследнему биту ROM BIOS тип IBM PC 		
		lea	dx, PC
		cmp bh, 0FFh
		je	output
	
		lea	dx, PC_XT
		cmp bh, 0FEh
		je	output
	
		lea	dx, AT
		cmp bh, 0FCh
		je	output
	
		lea	dx, PC2_30
		cmp bh, 0FAh
		je	output

		lea	dx, PC2_50
		cmp bh, 0FCh
		je	output
	
		lea	dx, PC2_80
		cmp bh, 0F8h
		je	output
	
		lea	dx, PCjr
		cmp bh, 0FDh
		je	output

		lea	dx, PC_Conv
		cmp bh, 0F9h
		je	output
output:
		call	PrintMsg
		
;Определяем оставшиеся характеристики
 		mov		ah,30h
		int		21h
		call	GET_SYSTEM_INFO
		call	GET_OEM_INFO
		call	GET_USER_INFO
; выводим информацию

		lea		dx,SYS_VER
		call	PrintMsg
		lea		dx,OEM_NUM
		call	PrintMsg
		lea		dx,USER_NUM
		call	PrintMsg
; выход в DOS
		xor		al,al
		mov		ah,4Ch
		int		21h
		ret
Main    		ENDP
CODE			ENDS
				END Main