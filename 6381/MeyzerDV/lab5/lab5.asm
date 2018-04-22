ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
; Процедура обработчика прерывания
ROUT PROC FAR
	jmp INT_CODE
	SIGNATURE db 'AAAB'
	KEEP_IP DW 0
	KEEP_CS DW 0 ; Переменные для хранения CS и IP старого обработчика
	KEEP_PSP DW 0 ; Переменная для хранения адреса PSP у пользовательского обработчика
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	INT_CODE:
	
	mov CS:KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
			; Статья 28 Рудаков
	; Проверяем пришедший scan-код
		in al,60h
		cmp al,11h ; 11h - клавиша w
		jne ROUT_STNDRD ; Если пришел другой скан-код, идём в стандартный обработчик
	; Проверяем, нажат ли левый Alt(12 бит состояния)
		mov ax,0040h
		mov es,ax
		mov al,es:[18h]
		and al,00000010b
		jz ROUT_STNDRD ; Если не нажат, идем в стандартный обработчик
	jmp ROUT_USER

	
	ROUT_STNDRD:
	; Переходим в стандартный обработчик прерывания:
		pop es
		pop ds
		pop dx
		mov ax, CS:KEEP_AX
		mov sp, CS:KEEP_SP
		mov ss, CS:KEEP_SS
		jmp dword ptr CS:KEEP_IP
		; jmp ROUT_END
	
	ROUT_USER:
	; Пользовательский обработчик:
	push ax
	;следующий код необходим для отработки аппаратного прерывания
		in al, 61h   ;взять значение порта управления клавиатурой
		mov ah, al     ; сохранить его
		or al, 80h    ;установить бит разрешения для клавиатуры
		out 61h, al    ; и вывести его в управляющий порт
		xchg ah, al    ;извлечь исходное значение порта
		out 61h, al    ;и записать его обратно
		mov al, 20h     ;послать сигнал "конец прерывания"
		out 20h, al     ; контроллеру прерываний 8259
	pop ax

	ROUT_PUSH_TO_BUFF:
	; Запись символа в буфер клавиатуры:
		mov ah,05h
		mov cl,'D'
		mov ch,00h
		int 16h
		or al,al
		jz ROUT_END ; Проверяем переполнение буфера клавиатуры
		; Очищаем буфер клавиатуры:
			CLI
			mov ax,es:[1Ah]
			mov es:[1Ch],ax ; Помещаем адрес начала буфера в адрес конца
			STI
			jmp ROUT_PUSH_TO_BUFF
		
	ROUT_END:
	pop es
	pop ds
	pop dx
	mov ax, CS:KEEP_AX
	mov al,20h
	out 20h,al
	mov sp, CS:KEEP_SP
	mov ss, CS:KEEP_SS
	iret
ROUT ENDP
	LAST_BYTE:
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
;
CHECK_INT PROC
	; Проверка, установлено ли пользовательский обработчик прерывания с вектором 09h
		mov ah,35h
		mov al,09h
		int 21h ; Получаем в es сегмент прерывания, а в bx - смещение
	
	mov si, offset SIGNATURE
	sub si, offset ROUT ; В si хранится смещение сигнатуры относительно начала функции ROUT
	
	; Проверка сигнатуры ('AAAB'):
	; ES - сегмент функции прерывания
	; BX - смещение функции прерывания
	; SI - смещение сигнатуры относительно начала функции прерывания
		mov ax,'AA'
		cmp ax,es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		mov ax,'BA'
		cmp ax,es:[bx+si+2]
		jne LABEL_INT_IS_NOT_LOADED
		jmp LABEL_INT_IS_LOADED 
	
	LABEL_INT_IS_NOT_LOADED:
	; Установка пользовательской функции прерывания
		mov dx,offset STR_INT_IS_LOADED
		call PRINT
		call SET_INT ; Установили пользовательское прерывание
		; Вычисление необходимого количества памяти для резидентной программы:
			mov dx,offset LAST_BYTE ; Кладём в dx размер части сегмента CODE, содержащей пользовательское прерывание и необходимые код и данные для него
			mov cl,4
			shr dx,cl
			inc dx	; Перевели его в параграфы
			add dx,CODE ; Прибавляем адрес сегмента CODE
			sub dx,CS:KEEP_PSP ; Вычитаем адрес сегмента PSP, сохраненного в KEEP_PSP
		xor al,al
		mov ah,31h
		int 21h ; Оставляем нужное количество памяти(dx - кол-во параграфов) и выходим в DOS, оставляя программу в памяти резидентно
		
	LABEL_INT_IS_LOADED:
	; Смотрим, есть ли в хвосте /un
		push es
		push bx
		mov bx,KEEP_PSP
		mov es,bx
		cmp byte ptr es:[82h],'/'
		jne CI_DONT_DELETE
		cmp byte ptr es:[83h],'u'
		jne CI_DONT_DELETE
		cmp byte ptr es:[84h],'n'
		je CI_DELETE ; Если есть, значит идем удалять наш обработчик
		CI_DONT_DELETE:
		pop bx
		pop es
	
	mov dx,offset STR_INT_IS_ALR_LOADED
	call PRINT
	ret
	
	; Убираем пользовательский обработчик прерывания
		CI_DELETE:
		pop bx
		pop es
		; ES - сегмент функции прерывания
		; BX - смещение функции прерывания
		; SI - смещение сигнатуры относительно начала функции прерывания
		call DELETE_INT
		mov dx,offset STR_INT_IS_UNLOADED
		call PRINT
		ret
CHECK_INT ENDP
;---------------------------------------
; Установка пользовательского обработчика прерывания ROUT
SET_INT PROC
	push ds
	mov ah,35h; Сохраняем старый обработчик
	mov al,09h
	int 21h
	mov CS:KEEP_IP,bx
	mov CS:KEEP_CS,es
	
	mov dx,offset ROUT ; Устанавливаем новый
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	pop ds
	ret
SET_INT ENDP 
;---------------------------------------
; Удаление пользовательского обработчика прерывания ROUT
DELETE_INT PROC
	push ds
	; Восстанавливаем стандартный вектор прерывания:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		
		mov ax,2509h
		int 21h 
	; Освобождаем память:
		push es
		mov ax,ES:[BX+SI+8] ; PSP
		mov es,ax 
		mov es,es:[2Ch] ; Блока переменных среды
		mov ah,49h         
		int 21h
		pop es
		mov es,ES:[BX+SI+8] ; PSP ; Блока резидентной программы
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DELETE_INT ENDP 
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	mov CS:KEEP_PSP,es
	
	call CHECK_INT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	STR_INT_IS_ALR_LOADED DB 'User interruption is already loaded',0DH,0AH,'$'
	STR_INT_IS_UNLOADED DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	STR_INT_IS_LOADED DB 'User interruption is loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	dw 50 dup (?)
STACK ENDS
 END START