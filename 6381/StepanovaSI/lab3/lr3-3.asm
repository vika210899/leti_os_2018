TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H ;использовать смещение 100h (256 байт) от начала
				 ;сегмента, в который загружена программа
START: 	JMP	BEGIN ; START - точка входа

;ДАННЫЕ
AvailableMemory	db 'Amount of available memory:                                        ', 0DH, 0AH, '$'
ExtendedMemory	db 'Size of extended memory:                                           ', 0DH, 0AH, 0DH, 0AH, '$'
MCBData		 	db '| MCB Address |  MCB Type  | PSP Address |    Size    |   SC/SD    |', 0DH, 0AH, '$'
MCB 			db '|             |            |             |            |            |', 0DH, 0AH, '$'
Line 			db '--------------------------------------------------------------------', 0DH, 0AH, '$'

;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;половина байт AL переводится в символ шестнадцатиричного числа в AL
		and		al, 0Fh ;and 00001111 - оставляем только вторую половину al
		cmp		al, 09 ;если больше 9, то надо переводить в букву
		jbe		NEXT ;выполняет короткий переход, если первый операнд МЕНЬШЕ или РАВЕН второму операнду
		add		al, 07 ;дополняем код до буквы
	NEXT:	add		al, 30h ;16-ричный код буквы или цифры в al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;байт AL переводится в два символа шестнадцатиричного числа в AX
		push	cx
		mov		ah, al ;копируем al в ah
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		xchg	al, ah ;меняем местами al и  ah
		mov		cl, 4 
		shr		al, cl ;cдвиг всех битов al вправо на 4
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;регистр AX переводится в шестнадцатеричную систему, DI - адрес последнего символа
		push	bx
		mov		bh, ah ;копируем ah в bh, т.к. ah испортится при переводе
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра ah по адресу, лежащему в регистре DI
		dec		di 
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		al, bh ;копируем bh в al, восстанавливаем значение ah
		xor		ah, ah ;очищаем ah
		call	BYTE_TO_HEX ;переводим al в два символа шестнадцатиричного числа в AX
		mov		[di], ah ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		dec		di
		mov		[di], al ;пересылка содержимого регистра al по адресу, лежащему в регистре DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_DEC		PROC	near ;байт AL переводится в десятичную систему, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		xor		ah, ah ;очищаем ah
		xor		dx, dx ;очищаем dx
		mov		cx, 10 
	loop_bd:div		cx ;делим ax на 10
		or 		dl, 30h ;логическое или 00110000
		mov 	[si], dl ;пересылка содержимого регистра dl по адресу, лежащему в регистре si
		dec 	si
		xor		dx, dx ;очищаем dx
		cmp		ax, 10 ;сравниваем содержимое ax с 10
		jae		loop_bd ;перейти, если больше или равно 10
		cmp		ax, 00h ;сравниваем ax и 0
		jbe		end_l ;Перейти, если меньше или равно 0
		or		al, 30h ;логическое или 00110000
		mov		[si], al ;пересылка содержимого регистра dl по адресу, лежащему в регистре si
	end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP	
;--------------------------------------------------------------------------------
WRD_TO_DEC PROC near
		push CX
		push DX
		mov CX,10
	loop_b: div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_b
		cmp AL,00h
		je endl
		or AL,30h
		mov [SI],AL
	endl:	pop DX
		pop CX
		ret
WRD_TO_DEC ENDP
;--------------------------------------------------------------------------------
;ПРОЦЕДУРЫ ДЛЯ ОПРЕДЕЛЕНИЯ ДАННЫХ
;--------------------------------------------------------------------------------
FindAvailableMemory PROC NEAR
	push ax
	push bx
	push dx
	push si
	xor ax, ax ;очищение ax
	mov ah, 4Ah ;функця 4Ah прерывания 21h
	mov bx, 0FFFFh ;размер памяти в параграфах (заведомо большая память)
	int 21h ;в bx - размер доступной памяти в параграфах
	mov ax, 10h ;1 параграф=16 байт
	mul bx ;перевод в байты
	mov si, offset AvailableMemory
	add si, 21h
	call WRD_TO_DEC	
	pop si
	pop dx
	pop bx
	pop ax
	ret
FindAvailableMemory ENDP
;--------------------------------------------------------------------------------
FindExtendedMemory PROC NEAR
	push ax
	push bx
	push dx
	push si
	xor dx, dx ;очищение dx
	mov al, 30h ;запись адреса ячейки CMOS
    out 70h, al
    in al, 71h ;чтение младшего байта
    mov bl, al ;размер расширенной памяти
    mov al, 31h ;запись адреса ячейки CMOS
    out 70h, al
    in al, 71h ;чтение старшего байта размера расширенной памяти 
	mov ah, al
	mov al, bl
	mov si, offset ExtendedMemory
	add si, 1Dh
	call WRD_TO_DEC	
	pop si
	pop dx
	pop bx
	pop ax
	ret
FindExtendedMemory ENDP
;--------------------------------------------------------------------------------
FindMCB PROC near 
	mov di, offset MCB ;адрес MCB
	mov ax, es ;MCB распологается с адреса, кратного 16
	add di, 8h
	call WRD_TO_HEX
	mov di, offset MCB ;тип MCB
	add di, 15h
	xor ah, ah ;очищение ah
	mov al, es:[00h] ;тип MCB: 5Ah, если последний в списке; 4Dh, если не последний
	call WRD_TO_HEX
	mov al, 20h
	mov [di], al
	inc di
	mov [di], al
	mov di, offset MCB ;сегментный адрес PSP владельца участка памяти
	mov ax, es:[01h] ;0000h - свободный участок, 0006h - участок принадлежит драйверу OS XMS UMB,
					 ;0007h - участок является исключенной верхней памятью драйверов, 0008h - участок принадлежит MS DOS,
					 ;FFFAh - участок занят управляющим блоком 386MAX UMB, FFFDh - участок заблокирован 386MAX
					 ;FFFEh - участок принадлежит 386MAX UMB
	add di, 23h
	call WRD_TO_HEX
	mov di, offset MCB ;размер участка в параграфах
	mov ax, es:[03h] ;размер участка в параграфах
	mov bx, 10h ;1 параграф=16 байт
	mul bx ;перевод в байты
	add di, 32h 
	push si
	mov si, di
	call WRD_TO_DEC
	pop si
	mov di, offset MCB ;SC/SD
	add di, 3Ah
    mov bx, 0h ;счётчик байтов
	For8bytes: ;цикл взятия 8 байтов
        mov dl, es:[bx + 8] ;смещение поля
		mov [di], dl
		inc di ;di++
		inc bx ;bx++
		cmp bx, 8h ;проверка на 8 байт
	jne For8bytes ;пока не равно 8
	mov ax, es:[03h]
	mov bl, es:[00h]
	ret
FindMCB ENDP
;--------------------------------------------------------------------------------
PRINT PROC NEAR ;печать на экран
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
;КОД
BEGIN:
	;1) количество доступной памяти
	call FindAvailableMemory
	mov dx, offset AvailableMemory
	call PRINT
	;Освобождение памяти, которую не занимает программа
	mov ah, 4ah ;функция 4Ah прерывания 21h для освобождения памяти
	mov bx, offset MemSize ;смещение на конец программы - размер памяти программы
	int 21h
	;Запрос 64Кб памяти
	mov ah,48h ;функция 48h прерывания int 21h для выделения памяти
	mov bx,1000h ;запрошенное количество памяти в 16-байтовых параграфах 1000=64Кб
	int 21h
	;2) размер расширенной памяти
	call FindExtendedMemory
	mov dx, offset ExtendedMemory
	call PRINT
	;3) вывод цепочки блоков управления памятью
	mov dx, offset Line
	call PRINT
	mov dx, offset MCBData	
	call PRINT
	mov dx, offset Line
	call PRINT

	mov ah,52h ;доступ к указателю на структуру список списков
	int 21h ;ES:BX будет указывать на список списков
	sub bx,2h ;Слово по адресу ES:[BX-2] и есть адрес самого первого MCB
	mov es,es:[bx]
PrintMCB:
	call FindMCB
	mov dx,offset MCB 
	call PRINT
	mov cx,es
	add ax,cx
	inc ax
	mov es,ax
	cmp bl,5Ah ;если bl(тип MCB) = 5Ah, то он последний
	jne PrintMCB
	mov dx, offset Line
	call PRINT
	
; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h

MemSize db 0
TESTPC 	ENDS
		END START	; конец модуля