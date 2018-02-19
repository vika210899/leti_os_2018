TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H

START:	jmp		BEGIN
;Данные
ADDR_MEM	db	'Address of inaccessible memory:     ',0dh,0ah,'$'
ADDR_ENV	db	'Address of the environment:     ',0dh,0ah,'$'
TAIL		db	'Tail command line:   ',0dh,0ah,'$'
CONTENT		db	'Content of the environment area: ' , '$'
PATH		db	'Path of the loadable module: ' , '$'
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
		call 	 TETR_TO_HEX  ;в AL - старша¤, в AH - младша¤
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
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push	 ax
		mov 	 ah, 09h
	    int 	 21h
	    pop		 ax
	    ret
OUTPUT_PROC ENDP
;----------------------------
DETERMINE_ADDR_MEM PROC NEAR ;Определение сегментного адреса недоступной памяти
		push 	 ax
		push 	 di
		mov 	 ax, ds:[02h] ;Загружаем адрес
		lea 	 di, ADDR_MEM
		add 	 di, 23h ;Загружаем адрес последнего символа в строке
		call 	 WRD_TO_HEX ;Переводим в 16 СС
		pop di
		pop ax
		ret
DETERMINE_ADDR_MEM ENDP
;----------------------------
DETERMINE_ADDR_ENV PROC NEAR ;Определение сегментного адреса среды
		push 	 ax
		push 	 di
		mov 	 ax, ds:[2Ch] ;Загружаем адрес
		lea 	 di, ADDR_ENV
		add 	 di, 01Fh ;Загружаем адрес последнего символа в строке
		call  	 WRD_TO_HEX ;Переводим в 16 СС
		pop 	 di
		pop 	 ax
		ret
DETERMINE_ADDR_ENV ENDP
;----------------------------
DETERMINE_TAIL PROC NEAR ;Определение хвоста командной строки
		push 	 ax
		push 	 cx
		push 	 dx	
		push 	 si
		push 	 di
	
		xor 	 cx, cx
		mov 	 ch, ds:[80h] ; Загружаем число символов в конце командной строки
		mov 	 si, 81h
		mov 	 di, offset TAIL
		add 	 di, 14h ;Загружаем адрес последнего символа в строке

	get_line:
		cmp 	 ch, 0 ; Проверяем на пустоту строки
		je 	  	 null_l 
	
		mov 	 al, ds:[si] ; Записываем очередной символ
		mov 	 [di], al    
		inc 	 di 
		inc 	 si 
		dec 	 ch 
		jmp 	 get_line
		
	null_l:
		mov 	 al, 0h
		mov 	 [di], al
	
		pop 	 di
		pop 	 si
		pop 	 dx
		pop 	 cx
		pop 	 ax
		ret
DETERMINE_TAIL ENDP
;----------------------------
DETERMINE_CONTENT_PATH	PROC near ;Определяем содержимое области среды и путь к загружаемому модулю
		push 	 es
		push 	 ax 
		push 	 bx 
		push 	 cx 
		
		lea 	 dx, CONTENT ;Вывод поясняющей строки
		call 	 OUTPUT_PROC
		mov		 es,es:[2ch] ;Записываем начало содержимого области среды
		mov		 bx, 0	
		xor		 si,si 
	new:
		lea 	 dx, NEW_LINE ;Перенос на новую строку
		call	 OUTPUT_PROC
		mov		 ax,si ;Сохраняем адрес начала названия элемента области среды
	count_env:
		cmp 	 byte ptr es:[si], 0 
		je 		 get_content ;Доходим до конца элемента области среды
		inc		 si
		jmp 	 count_env 
	get_content:
		push 	 es:[si] 
		mov	 	 byte ptr es:[si], '$'
		push 	 ds 
		mov	 	 cx,es 
		mov	 	 ds,cx 
		mov	 	 dx,ax ;Записываем значение адреса начала строки
		call 	 OUTPUT_PROC ;Выводим полученную строку
		pop	 	 ds 
		pop	 	 es:[si] ;Возвращаем значение текущей ячейки	
		cmp		 bx,0 ;Проверяем на окончание
		jne 	 end_proc ; Если bx!=0 то переходим к концу процедуры
		inc		 si 
		cmp 	 byte ptr es:[si], 1 ;Проверяем, идет ли дальше информация о пути
    	jne 	 new 
		lea 	 dx, NEW_LINE ;Перенос на новую строку
		call	 OUTPUT_PROC
    	lea		 dx,PATH ;Записываем значение адреса пути
		call	 OUTPUT_PROC
    	mov		 bx,1 ;Сообщаем программе, что дальше пойдет путь
    	add 	 si,2
    	jmp 	 new
    end_proc:
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		pop		 cx 
		pop		 bx 
		pop		 ax
		pop		 es 
		ret
DETERMINE_CONTENT_PATH	ENDP
;----------------------------
	BEGIN: 
		call 	 DETERMINE_ADDR_MEM ;Определяем адрес памяти
		lea		 dx,ADDR_MEM
		call 	 OUTPUT_PROC
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		
		call	 DETERMINE_ADDR_ENV ;Определяем адрес среды
		lea		 dx,ADDR_ENV 
		call	 OUTPUT_PROC
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		
		call	 DETERMINE_TAIL ;Определяем хвост командной строки
		lea		 dx,TAIL
		call	 OUTPUT_PROC
		lea	 	 dx,NEW_LINE
		call 	 OUTPUT_PROC
		
		call 	 DETERMINE_CONTENT_PATH ;Определяем содержимое среды и путь модуля
	
;Выход в DOS
		xor 	al, al
		mov 	ah, 4ch
		int 	21h
	
TESTPC 	ENDS
		END START