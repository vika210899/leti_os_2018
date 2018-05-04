CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
 
RStack db 64 dup (0)


MY_INT	PROC	FAR              ;Пользовательское прерывание
	
		jmp IntCode
	IntData:
		SIGNATURE	db '999999'
		KEEP_CS 	dw 0
		KEEP_IP 	dw 0
		KEEP_ES 	dw 0 
		UNLOAD 	 	db 0 
		KEEP_SP  	dw 0
		KEEP_SS  	dw 0
		OUT_STRING 	db 'Number of interruptions:$'
		ONES		db '0$'
		DOZENS		db '0$'
		HUNDREDS	db '0$'
		THOUSANDS	db '0$'
		
	IntCode:
		mov		KEEP_SP, sp
		mov 	KEEP_SS, ss
		mov		ax, cs
		mov 	ss, ax
		mov		sp, 40h
	
		push	ax
		push	dx
		push	ds
		push	es
	
		cmp 	UNLOAD, 1
		je 		IntRestore
		
		call 	CALCULATE_INT
		
	IntPrint:	
		push 	es
		push 	bp
		push	cx
		;вывод количества прерываний на консоль
		mov 	ax, SEG OUT_STRING
		mov 	es, AX
		lea 	ax, OUT_STRING
		mov 	bp, AX
		mov 	dh, 23 ;строка
		mov		dl, 10 ;столбец		
		mov		cx, 24
		call 	OUTPUT_BP

		lea 	ax, THOUSANDS
		mov 	bp, AX
		mov		dl, 35 ;столбец		
		mov 	cx, 1
		call	OUTPUT_BP
		
		lea 	ax, HUNDREDS
		mov 	bp, AX
		mov		dl, 36 ;столбец		
		mov 	cx, 1
		call	OUTPUT_BP
		
		lea 	ax, DOZENS
		mov 	bp, AX
		mov		dl, 37 ;столбец		
		mov 	cx, 1
		call	OUTPUT_BP
		
		lea 	ax, ONES
		mov 	bp, AX
		mov		dl, 38 ;столбец		
		mov 	cx, 1
		call	OUTPUT_BP
				
		pop		cx
		pop 	bp
		pop 	es
		pop 	dx
		
		jmp 	IntEndp
				
	IntRestore:
		call 	SET_DEFAULT_INT
		
	IntEndp:
		pop 	es 
		pop 	ds
		pop 	dx
		pop 	ax
		mov 	sp, KEEP_SP
		mov 	ss, KEEP_SS	
		mov 	al, 20h
		out 	20h, al
		iret
		
MY_INT 	ENDP
;-----------------------------------------------------------
CALCULATE_INT	PROC             ; Увеличивает счетчик
		push 	ax
		push 	si
		push	ds
		mov		ax, seg	ONES
		mov		ds, ax
		lea 	si, ONES
		
		mov		ah, [si]
		cmp		ah, '9'
		jne		Not_9
		mov		ah, '0'
		mov		[si], ah
		
		add		si, 2
		mov		ah, [si]
		cmp		ah, '9'
		jne		Not_9
		mov		ah, '0'
		mov		[si], ah
		
		add		si, 2
		mov		ah, [si]
		cmp		ah, '9'
		jne		Not_9
		mov		ah, '0'
		mov		[si], ah
		
		add		si, 2
		mov		ah, [si]
		cmp		ah, '9'
		jne		Not_9
		mov		ah, '0'
		mov		[si], ah
		
	
	Not_9:
		inc		ah
		mov		[si], ah
	
		pop		ds
		pop		si
		pop		ax
		ret
CALCULATE_INT 	ENDP
;-----------------------------------------------------------
OUTPUT_BP 	PROC                 ; Выводит сообщение длиной cx, записанное в es:bp в позицию dh, dl
		push 	ax
		push 	bx		
		mov		ah, 13h
		mov 	bl, 4
		mov 	al, 0
		mov		bh, 0
		int 	10h
		pop 	bx
		pop 	ax
		ret
OUTPUT_BP	ENDP
;-----------------------------------------------------------
CHECK	PROC                     ; Проверяет установлено ли пользовательское прерывание и задан ли параметр /un 
		mov 	KEEP_ES, es 	
		mov 	ah, 35h
		mov 	al, 1ch
		int		21h
		lea 	si, SIGNATURE
		sub 	si, offset MY_INT
		
		;проверка ключа
		mov 	ax, '99'
		cmp 	ax, es:[bx + si]
		jne 	Not_custom
		cmp 	ax, es:[bx + si + 2]
		jne 	Not_custom
		cmp		ax, es:[bx + si + 4]
		jne		Not_custom
		jmp 	Have_cust
		
	Not_custom: 
		call 	SET_MY_INT 
		lea 	dx, Last_byte
		mov 	cl, 4 
		shr 	dx, cl
		inc 	dx	
		add 	dx, CODE 
		sub 	dx, KEEP_ES 
		xor 	al, al
		mov 	ah, 31h 
		int 	21h 
		
	Have_cust: 
		push 	es
		push 	ax
		mov 	ax, KEEP_ES 
		mov 	es, ax
		;проверка параметра /un 
		cmp 	byte ptr es:[82h], '/' 
		jne 	Not_unloaded
		cmp 	byte ptr es:[83h], 'u' 
		jne 	Not_unloaded 
		cmp 	byte ptr es:[84h], 'n' 
		jne 	Not_unloaded 
		
		pop 	ax
		pop 	es
		mov 	byte ptr es:[bx + si + 12], 1  ;установка флага для выгрузки
		lea 	dx, UNLOADED
		call 	Write
		ret
	Not_unloaded: 
		pop 	ax
		pop 	es
		lea 	dx, LOADED_BEFORE
		call 	WRITE
		ret	
		
CHECK	ENDP
;-----------------------------------------------------------
SET_MY_INT PROC                  ; Устанавливает пользовательское прерывание	
		push 	dx
		push	ds
		mov 	ah, 35h
		mov 	al, 1ch
		int		21h
		mov 	KEEP_CS, es
		mov		KEEP_IP, bx
		lea		dx, MY_INT
		mov		ax, seg MY_INT
		mov 	ds, ax
		mov 	ah, 25h
		mov 	al, 1ch
		int		21h
		pop		ds
		lea 	dx, LOADED
		call 	WRITE
		pop		dx
		ret
SET_MY_INT ENDP
;-----------------------------------------------------------
WRITE	PROC 	NEAR             ; Вывод сообщения, записанного в dx	
		push	ax
		mov		ah, 09h
		int 	21h
		pop 	ax
		ret
WRITE	ENDP
;-----------------------------------------------------------
SET_DEFAULT_INT		PROC NEAR        ; Восстановить исходное прерывание	
		CLI 
		mov 	dx, KEEP_IP
		mov 	ax, KEEP_CS
		mov 	ds, AX 
		mov 	ah, 25h 
		mov 	al, 1Ch 
		int 	21h 
		mov		es, KEEP_ES
		mov 	es, ES:[2Ch] 
		mov 	ah, 49h 
		int 	21h 
		mov		es, KEEP_ES
		mov 	ah, 49h
		int 	21h	
		STI
		ret
SET_DEFAULT_INT		ENDP



ASTACK SEGMENT STACK
		DW 512 DUP (?)
ASTACK ENDS

DATA	SEGMENT
		LOADED  		db 'Custom interruption has been loaded!',0dh,0ah,'$'
		UNLOADED  		db 'Custom interruption has been unloaded!',0dh,0ah,'$'
		LOADED_BEFORE 	db 'Custom interruption has already been loaded!',0dh,0ah,'$'
DATA	ENDS

MAIN	PROC	FAR
		push 	ds
		sub 	ax, ax
		push 	ax
		mov 	ax, DATA
		mov 	ds, ax
		
		call 	CHECK 
		sub 	al, al
		mov 	ah, 4ch 
		int 	21h
		ret
	Last_byte:
MAIN 	ENDP
CODE 	ENDS
		END MAIN