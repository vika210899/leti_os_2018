TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H ;использовать смещение 100h (256 байт) от начала
				 ;сегмента, в который загружена программа
START: 	JMP	BEGIN ; START - точка входа

;ДАННЫЕ
SAofInaccessibleMemory	db 'The segment address of the inaccessible memory (from PSP):     ', 0DH, 0AH, '$'
SAofEnvironment			db 0DH, 0AH, 'The segment address of the environment passed to the program:     ', 0DH, 0AH, '$'
TailOfComandLine		db 0DH, 0AH,'The tail of comand line:                                                   ', 0DH, 0AH, '$'
ContentsOfEnvironment 	db 0DH, 0AH, 'The contents of the environment:', 0DH, 0AH, '$'
PathOfModule			db 0DH, 0AH, 0AH, 'The path of the loaded module:', 0DH, 0AH, '$'

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
;ПРОЦЕДУРЫ ДЛЯ ОПРЕДЕЛЕНИЯ ДАННЫХ
;--------------------------------------------------------------------------------
FindSAofInaccessibleMemory PROC NEAR ;определение адреса недоступной памяти, взятого из PSP, в шестнадцатиричном виде
	push ax
	push di
	mov ax, ds:[02h] ;сегментный адрес первого байта недоступной памяти
	mov di, offset SAofInaccessibleMemory
	add di, 3Eh 
	call WRD_TO_HEX ;переводим адрес в 16-ричн. вид
	pop di
	pop ax
	ret
FindSAofInaccessibleMemory ENDP
;--------------------------------------------------------------------------------
FindSAofEnvironment PROC NEAR ;определение сегментного адреса среды, передаваемой программе, в шестнадцатиричном виде
	push ax
	push di
	mov ax, ds:[02Ch] ;(44) сегментный адрес среды, передаваемой программе
	mov di, offset SAofEnvironment
	add di, 43h 
	call WRD_TO_HEX ;переводим адрес в 16-ричн. вид
	pop di
	pop ax
	ret
FindSAofEnvironment ENDP
;--------------------------------------------------------------------------------
FindTailOfComandLine PROC NEAR ;определение хвоста командной строки в символьном виде
	push ax
	push cx
	push dx	
	push si
	push di
	xor cx, cx ;очищаем cx для дальнейшей работы
	mov si, 80h ;смещение хвоста командной строки (для дальнейшего использования)
	mov ch, byte ptr cs:[si] ;число символов в хвосте командной строки
	mov di, offset TailOfComandLine
	add di, 1Bh
	inc si
Copy:
	cmp ch, 0h ;пока не закончится количество незаписанных символов хвоста командной строки
	je StopCopy ;если число незаписанных символов в хвосте командной строки = 0
	xor ax, ax
	mov al, byte ptr cs:[si] ;копируем в di очередной элемент хвоста командной строки(по адресу si)
	mov [di], al ;записываем в строку
	inc di ;di++ - переход к месту для записи следующего символа
	inc si ;si++ - переход к следующему символу
	dec ch ;ch-- - уменьшаем количество незаписанных символов хвоста командной строки на 1
	jmp Copy ;копируем хвост командной строки пока все символы не будут переписаны
StopCopy: ;когда все символы переписаны
	xor ax, ax
	mov al, 0Ah ;нулевой байт
	mov [di], al
	inc di
	mov al, '$'
	mov [di], al
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
FindTailOfComandLine ENDP
;--------------------------------------------------------------------------------
Find_4_5 PROC NEAR ;определение содержимого области среды в символьном виде и пути загружаемого модуля
	push ax
	push dx
	push ds
	push es
;4) Содержимое области среды в символьном виде
	mov dx, offset ContentsOfEnvironment 
	call PRINT
	mov ah, 02h ;для посимвольного выведения dl (AH = 02H; DL = символ, выводимый на стандартный вывод)
	mov es, ds:[02Ch] ;сегментный адрес среды, передаваемой программе
	xor si, si ;очищение si
CopyContents:
	mov dl, es:[si] ;берём очередной символ
	int 21h			;выводим его на экран
	cmp dl, 0h		;проверяем на то что это конец строки
	je	StopCopyContents ;если конец строки
	inc si	;для перехода к следующему символу
	jmp CopyContents
StopCopyContents: ;конец строки+проверка на это (конец среды - 2 0-х байта подряд)
	inc si ;для перехода к следующему символу
	mov dl, es:[si]  ;берём очередной символ
	cmp dl, 0h		;проверяем на то что это конец строки
	jne CopyContents 	;если всё таки не конец строки (не 2 0-х байта подряд)
;5) Путь загружаемого модуля
	mov dx, offset PathOfModule
	call PRINT
	add si, 3h ;два 0-х байта, а потом 00h и 01h
	mov ah, 02h ;для посимвольного выведения dl (AH = 02H; DL = символ, выводимый на стандартный вывод)
	mov es, ds:[2Ch] ;сегментный адрес среды, передаваемой программе
CopyPath:
	mov dl, es:[si] ;берём очередной символ
	cmp dl, 0h  ;проверяем на то что это конец строки
	je StopCopyPath ;если конец строки, то прекращаем вывод
	int 21h ;выводим на экран
	inc si ;для перехода к следующему символу
	jmp CopyPath
StopCopyPath:
	pop es
	pop ds
	pop dx
	pop ax
	ret
Find_4_5 ENDP
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
	;1) Сегментный адрес недоступной памяти, взятый из PSP
	call FindSAofInaccessibleMemory
	mov dx, offset SAofInaccessibleMemory
	call PRINT
	;2) Сегментный адрес среды, передаваемой программе
	call FindSAofEnvironment
	mov dx, offset SAofEnvironment
	call PRINT
	;3) Хвост командной строки 
	call FindTailOfComandLine
	mov dx, offset TailOfComandLine
	call PRINT
	;4) Содержимое области среды в символьном виде и 5) Путь загружаемого модуля
	call Find_4_5
					
; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h
	
TESTPC 	ENDS
		END START	; конец модул