TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H

START:	jmp		BEGIN

;Данные
AVAIL_MEM   db  '  Amount of available memory:        b',0dh,0ah,'$'
EXT_MEM  	db  '  Extended memory size:       kB',0dh,0ah,'$'
TABLE_HEAD  db  '  MSB Adress   MSB Type   PSP Address    Size        SC/SD    ', 0dh, 0ah, '$'
TABLE_DATA  db  '                                                               ', 0dh, 0ah, '$'
NEW_LINE	db	' ',0dh,0ah,'$'

;Процедуры
;----------------------------
TETR_TO_HEX		PROC	near
		and 	 al,0Fh
		cmp 	 al,09
		jbe 	 NEXT
		add 	 al,07
NEXT:	add 	 al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near ;байт в AL переводится в два символа шестн. числа в AX
		push 	 cx
		mov 	 ah,al
		call 	 TETR_TO_HEX
		xchg 	 al,ah
		mov 	 cl,4
		shr 	 al,cl
		call 	 TETR_TO_HEX  ;в AL - старшая, в AH - младшая
		pop 	 cx
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near ;перевод в 16 с/с 16-ти разрядного числа, в AX - число, DI - адрес последнего символа
		push 	 bx
		mov 	 bh,ah
		call 	 BYTE_TO_HEX
		mov 	 [di],ah
		dec 	 di
		mov 	 [di],al
		dec 	 di
		mov 	 al,bh
		call 	 BYTE_TO_HEX
		mov 	 [di],ah
		dec 	 di
		mov 	 [di],al
		pop 	 bx
		ret	
WRD_TO_HEX		ENDP
;----------------------------
BYTE_TO_DEC		PROC	near ;перевод в 10 с/с, SI - адрес поля младшей цифры
		push 	 cx
		push 	 dx
		xor 	 ah,ah
		xor 	 dx,dx
		mov 	 cx,10
loop_bd: div 	 cx
		or 		 dl,30h
		mov 	 [si],dl
		dec 	 si
		xor	     dx,dx
		cmp 	 ax,10
		jae 	 loop_bd
		cmp		 al,00h
		je 		 end_l
		or 		 al,30h
		mov 	 [si],al
end_l:	pop 	 dx
		pop		 cx
		ret
BYTE_TO_DEC		ENDP
;----------------------------
WRD_TO_DEC		PROC	near
		push	 cx ; перевод двух байтов в 10 с/с, SI - адрес поля младшей цифры
		push	 dx
		push	 ax
		mov		 cx,10
wrd_loop_bd:
		div		 cx
		or 		 dl,30h
		mov 	 [si],dl
		dec 	 si
		xor		 dx,dx
		cmp		 ax,10
		jae		  wrd_loop_bd
		cmp		 ax,00h
		jbe		 wrd_end_l
		or		 al,30h
		mov		 [si],al
wrd_end_l:	
		pop		 ax
		pop		 dx
		pop		 cx
		ret
WRD_TO_DEC		ENDP
;----------------------------
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push	 ax
		mov 	 ah, 09h
	    int 	 21h
	    pop		 ax
	    ret
OUTPUT_PROC ENDP
;----------------------------
DET_AVAIL_MEM PROC NEAR ; Определение доступной памяти
		push 	 ax
		push 	 bx
		push 	 dx
		push 	 si
		
		xor 	 ax, ax
		mov 	 ah, 04Ah
		mov 	 bx, 0FFFFh
		int 	 21h
		mov 	 ax, 10h
		mul 	 bx
		
		lea 	 si, AVAIL_MEM
		add 	 si, 23h 
		call 	 WRD_TO_DEC
		
		pop 	 si
		pop 	 dx
		pop 	 bx
		pop 	 ax
		ret
DET_AVAIL_MEM ENDP
;----------------------------
DET_EXT_MEM PROC    near ; Определение расширенной памяти
		push 	 ax
		push 	 bx
		push 	 si
		push 	 dx
		
		mov		 al, 30h ; Запись адреса ячейки CMOS
		out		 70h, al 
		in		 al, 71h ; Чтение младшего байта
		mov		 bl, al ;  размера расширенной памяти
		mov		 al, 31h ; Запись адреса ячейки CMOS
		out		 70h, al
		in		 al, 71h ; Чтение старшего байта размера расширенной памяти
		mov 	 ah, al
		mov 	 al, bl ; Хранение в AX размера расширенной памяти
		sub 	 dx, dx
		
		lea 	 si, EXT_MEM
		add 	 si, 28 
		call 	 WRD_TO_DEC
		
		pop		 dx
		pop		 si
		pop		 bx
		pop		 ax
		ret
DET_EXT_MEM ENDP
;----------------------------
DET_DATA PROC near ;Определяем данные МСВ
		lea 	 di, TABLE_DATA ; Адрес МСВ
		mov 	 ax, es
		add 	 di, 05h
		call 	 WRD_TO_HEX

		lea 	 di, TABLE_DATA ; Тип МСВ
		add 	 di, 0Fh
		xor 	 ah, ah
		mov 	 al, es:[00h]
		call 	 BYTE_TO_HEX
		mov 	 [di], al
		inc 	 di
		mov 	 [di], ah
	
		lea 	 di, TABLE_DATA ; Адрес PSP
		mov 	 ax, es:[01h]
		add 	 di, 1Dh
		call 	 WRD_TO_HEX

		lea 	 di, TABLE_DATA  ; Размер
		mov 	 ax, es:[03h]
		mov 	 bx, 10h
		mul 	 bx
		add 	 di, 2Eh
		push 	 si
		mov 	 si, di
		call 	 WRD_TO_DEC
		pop 	 si

		lea 	 di, TABLE_DATA  ;SC/SD
		add 	 di, 35h
		mov 	 bx, 0h
		print:
				 mov dl, es:[bx + 8]
				 mov [di], dl
				 inc di
				 inc bx
				 cmp bx, 8h
		jne 	 print
		mov 	 ax, es:[3h]
		mov  	 bl, es:[0h]
		ret
DET_DATA ENDP
;----------------------------
OUTPUT_DATA PROC NEAR  ; Определяем и выводим цепочку блоков управления памятью
		mov 	 ah, 52h
		int 	 21h
		sub 	 bx, 2h
		mov 	 es, es:[bx]
		output:
			call 	 DET_DATA
			lea 	 dx, TABLE_DATA
			call 	 OUTPUT_PROC
			mov 	 cx, es
			add 	 ax, cx
			inc 	 ax
			mov 	 es, ax
			cmp 	 bl, 4Dh
			je 	  	 output
		ret
OUTPUT_DATA ENDP
;----------------------------
BEGIN: 
		call 	 DET_AVAIL_MEM ;Вызываем функцию определения доступной памяти
		lea		 dx,AVAIL_MEM
		call 	 OUTPUT_PROC
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		
		call 	 DET_EXT_MEM ;Вызываем функцию определения расширенной памяти
		lea		 dx,EXT_MEM
		call 	 OUTPUT_PROC
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		
		mov 	 ah, 4ah  ;Освобождаем память
		lea 	 bx, END_PROG
		int 	 21h
		
		mov 	ah, 48h	;Запрашиваем 64Кб памяти
		mov 	bx, 1000h
		int 	21h
		
		lea 	 dx, TABLE_HEAD
		call 	 OUTPUT_PROC
		call 	 OUTPUT_DATA
		
;Выход в DOS
		xor 	 al, al
		mov 	 ah, 4ch
		int 	 21h
	
		END_PROG db 0
TESTPC 	ENDS
		END START