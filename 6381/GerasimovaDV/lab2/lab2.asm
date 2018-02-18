TESTPC	SEGMENT
        ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        org 100H	; использовать смещение 100h (256 байт) от начала
				; сегмента, в который загружена наша программа
START:  JMP BEGIN	; START - точка входа

; ДАННЫЕ:
; дополнительные данные
EOF	EQU '$'
_endl	db ' ',0DH,0AH,'$' ; новая строка

_seg_inaccess	db 'Сегментный адрес недоступной памяти:     ',0DH,0AH,EOF
_seg_env		db 'Сегментный адрес среды:    ',0DH,0AH,EOF
_tail		db 'Хвост командной строки: ', EOF
_env 		db 'Содержимое области среды:',0DH,0AH,EOF
_dir	db 'Путь загружаемого модуля:',0DH,0AH,EOF
_symb  db 'нет символов',0DH,0AH,EOF

; ПРОЦЕДУРЫ:
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

;байт AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;в AL - старшая, в AH - младшая
	pop CX
	ret
BYTE_TO_HEX ENDP

;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

;перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

; функция определения сегментного адреса недоступной памяти
SEGMENT_INACCESS PROC NEAR
	push ax
	push di

	mov ax, ds:[02h] ; загружаем адрес
	mov di, offset _seg_inaccess
	add di, 40 ; загружаем адрес последнего символа _seg_inacces
	call WRD_TO_HEX ; переводим ax в 16СС

	pop di
	pop ax
	ret
SEGMENT_INACCESS ENDP

; функция определения сегментного адреса среды, передаваемого программе
SEGMENT_ENVIRONMENT PROC NEAR
	push ax
	push di

	mov ax, ds:[2Ch] ; загружаем адрес
	mov di, offset _seg_env
	add di, 27 ; загружаем адрес последнего символа _seg_env
	call WRD_TO_HEX

	pop di
	pop ax
	ret
SEGMENT_ENVIRONMENT ENDP

; функция определяет хвост программной строки в символьном виде
TAIL PROC NEAR
	push ax
	push cx
	push dx
	push si
	push di

	mov ch, ds:[80h] ; загружаем в ch число символов в конце командной строки
	mov si, 81h
	mov di, offset _tail
	add di, 20
CopyCmd:
	cmp ch, 0h
	je NoCmd ; если число символов в хвосте командной строки = 0
;No NoCmd
	mov al, ds:[si] ; копируем в di очередной элемент (по адресу si)
	mov [di], al    ; хвоста командной строки
	inc di ; смещаем адреса si и di
	inc si ;  на один символ вправо
	dec ch ; --ch
	jmp CopyCmd ; циклически копируем командную строку
NoCmd:
  mov al, 0h
  mov [di], al
	mov dx, offset _symb
	call PRINT

	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
TAIL ENDP

; функция определяет содержимое области среды
CONTENT PROC NEAR
	push ax
	push dx
	push ds
	push es

	; вывод содержимого области среды
	mov dx, offset _env
	call PRINT

	mov ah, 02h ; будем выводить посимвольно dl
	mov es, ds:[2Ch]
	xor si, si
WriteCont:
	mov dl, es:[si]
	int 21h			; вывод
	cmp dl, 0h		; проверяем на конец строки
	je	EndOfLine
	inc si			; переходим к рассмотрению след. символа
	jmp WriteCont
EndOfLine:
	mov dx, offset _endl ; прыжок на новую строчку
	call PRINT
	inc si
	mov dl, es:[si]
	cmp dl, 0h		; проверяем на конец содержимого области среды (если два подряд 0 байта)
	jne WriteCont

	mov dx, offset _endl
	call PRINT

	pop es
	pop ds
	pop dx
	pop ax
	ret
CONTENT ENDP

; вывод пути загружаемого модуля
PATH PROC NEAR
	push ax
	push dx
	push ds
	push es
	mov dx, offset _dir
	call PRINT

	add si, 3h
	mov ah, 02h
	mov es, ds:[2Ch]
	WriteDir:
	mov dl, es:[si]
	cmp dl, 0h
	je EndOfDir
	int 21h
	inc si
	jmp WriteDir
	EndOfDir:

	pop es
	pop ds
	pop dx
	pop ax
	ret
PATH ENDP

; функция вывода на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; КОД
BEGIN:
	call SEGMENT_INACCESS
  mov dx, offset _seg_inaccess
	call PRINT
	call SEGMENT_ENVIRONMENT
  mov dx, offset _seg_env
	call PRINT
  mov dx, offset _tail
	call PRINT
	call TAIL
  mov dx, offset _endl
	call PRINT
	call CONTENT
	call PATH
	mov dx, offset _endl
	call PRINT

; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h

TESTPC 	ENDS
		END START	; конец модуля
