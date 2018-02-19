.MODEL SMALL
.STACK 100h
.DATA

EOF	EQU '$'
;Данные
TYPE_PC		db 'Type of PC:   ','$'
VERSION		db 'Version of the system:    .  ',0Dh,0Ah,'$'
OEM_NUM		db 'OEM serial number:      ',0Dh,0Ah,'$'
USER_NUM	db 'User serial number:   ',0Dh,0Ah,'$'
PC			db 'PC',0Dh,0Ah,'$'
PC_XT 		db 'PC/XT',0Dh,0Ah,'$'
AT	 		db 'AT',0Dh,0Ah,'$'
PC2_30 		db 'PC2 model 30',0Dh,0Ah,'$'
PC2_50 		db 'PC2 model 50 or 60',0Dh,0Ah,'$'
PC2_80 		db 'PC2 model 80',0Dh,0Ah,'$'
PCjr 		db 'PCjr',0Dh,0Ah,'$'
PC_Conv 	db 'PC Convertible',0Dh,0Ah,'$'

.CODE
START: jmp	BEGIN
;Процедуры
;----------------------------
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near ;байт в AL переводится в два символа шестн. числа в AX
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
WRD_TO_HEX		PROC	near ;перевод в 16 с/с 16-ти разрядного числа, в AX - число, DI - адрес последнего символа
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
BYTE_TO_DEC		PROC	near ;перевод в 10 с/с, SI - адрес поля младшей цифры
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
;----------------------------
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push ax
		mov ah, 09h
	    int 21h
	    pop ax
	    ret
OUTPUT_PROC ENDP
;----------------------------
DET_TYPE PROC	near ;Определение типа PC
		 mov ax, 0F000h		
		 mov es, ax			
	     sub bx, bx
		 mov bh, es:[0FFFEh]	
		 ret
DET_TYPE 		ENDP
;----------------------------
DET_VERSION		PROC	near ; Определение версии системы
		push	ax
		push 	si
		lea		si,VERSION
		add		si,19h
		call	BYTE_TO_DEC
		add		si,3h
		mov 	al,ah
		call	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
DET_VERSION		ENDP
;-----------------------------
DET_OEM_NUM		PROC	near ; Определение серийного номера ОЕМ
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si,OEM_NUM
		add		si,17h
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
DET_OEM_NUM		ENDP
;-----------------------------
DET_USER_NUM	PROC	near ;Определение серийного номера пользователя
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
DET_USER_NUM	ENDP
;-----------------------------

BEGIN:
		mov ax, @data
		mov ds, ax
		mov bx, ds
;Вызываем функцию определения типа РС и выводим поясняющее сообщение
		call 	DET_TYPE 
		lea		dx,TYPE_PC
		call	OUTPUT_PROC		 
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
		call	OUTPUT_PROC
;Определяем оставшиеся характеристики и выводим их на экран
		mov		ah,30h  
		int		21h
		call	DET_VERSION ; Определяем версию системы
		lea		dx,VERSION
		call	OUTPUT_PROC
		
		call	DET_OEM_NUM ; Определеляем серийный номер ОЕМ
		lea		dx,OEM_NUM 
		call	OUTPUT_PROC
		
		call	DET_USER_NUM ;Определяем серийный номер пользователя
		lea		dx,USER_NUM
		call	OUTPUT_PROC

;Выход в DOS
		xor al, al
		mov ah, 4ch
		int 21h
		END START