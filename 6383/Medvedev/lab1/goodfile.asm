STACK SEGMENT STACK
	DW 0100h DUP(?)

STACK ENDS

DATA SEGMENT

;Данные
PCTYPE		db 'Type of PC:   ','$'
OSVERS		db 'Version of the system:    .  ',0Dh,0Ah,'$'
OEM			db 'OEM serial number:      ',0Dh,0Ah,'$'
NUMBER		db 'User serial number:   ',0Dh,0Ah,'$'
PC			db 'PC',0Dh,0Ah,'$'
PC_XT 		db 'PC/XT',0Dh,0Ah,'$'
AT_	 		db 'AT',0Dh,0Ah,'$'
PS2_30 		db 'PS2 model 30',0Dh,0Ah,'$'
PS2_50 		db 'PS2 model 50 or 60',0Dh,0Ah,'$'
PS2_80 		db 'PS2 model 80',0Dh,0Ah,'$'
PCjr 		db 'PCjr',0Dh,0Ah,'$'
PC_Conv 	db 'PC Convertible',0Dh,0Ah,'$'
DATA ENDS

CODE SEGMENT

ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:STACK

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
BYTE_TO_HEX		PROC near 
		push	cx
		mov		al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX 
		pop		cx 			
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
PRINT PROC NEAR 
		push ax
		mov ah, 09h
	    int 21h
	    pop ax
	    ret
PRINT ENDP
;----------------------------
OS_TYPE PROC	near ;Нахождение типа PC
		 mov ax, 0F000h		
		 mov es, ax			
	     sub bx, bx
		 mov bh, es:[0FFFEh]	
		 ret
OS_TYPE 		ENDP
;----------------------------
VERSION_		PROC	near ; Нахождение версии системы
		push	ax
		push 	si
		lea		si,OSVERS
		add		si,19h
		call	BYTE_TO_DEC
		add		si,3h
		mov 	al,ah
		call	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
VERSION_		ENDP
;-----------------------------
OEM_		PROC	near ; Нахождение серийного номера ОЕМ
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si,OEM
		add		si,17h
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
OEM_		ENDP
;-----------------------------
NUMBER_	PROC	near ;Нахождение серийного номера пользователя
		push	ax
		push	bx
		push	cx
		push	si
		mov		al,bl
		call	BYTE_TO_HEX
		lea		di,NUMBER
		add		di,22
		mov		[di],AX
		mov		ax,cx
		lea		di,NUMBER
		add		di,27
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop		ax
		ret
NUMBER_	ENDP
;-----------------------------

BEGIN:
		mov ax, DATA
		mov ds, ax
		;mov bx, ds
		call 	OS_TYPE 
		lea		dx,PCTYPE
		call	PRINT		 
		lea	dx, PC
		cmp bh, 0FFh
		je	output
	
		lea	dx, PC_XT
		cmp bh, 0FEh
		je	output
	
		lea	dx, AT_
		cmp bh, 0FCh
		je	output
	
		lea	dx, PS2_30
		cmp bh, 0FAh
		je	output

		lea	dx, PS2_50
		cmp bh, 0FCh
		je	output
	
		lea	dx, PS2_80
		cmp bh, 0F8h
		je	output
	
		lea	dx, PCjr
		cmp bh, 0FDh
		je	output

		lea	dx, PC_Conv
		cmp bh, 0F9h
		je	output
output:
		call	PRINT

		mov		ah,30h  
		int		21h
		call	VERSION_ ; Нахождение версии системы
		lea		dx,OSVERS
		call	PRINT
		
		call	OEM_ ; Нахождение серийного номера OEM
		lea		dx,OEM 
		call	PRINT
		
		call	NUMBER_ ; Нахождение серийного номера пользователя
		lea		dx,NUMBER
		call	PRINT

		xor al, al
		mov ah, 4ch
		int 21h
CODE ENDS
END BEGIN