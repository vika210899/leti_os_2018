; Шаблон текста программы для модуля типа .COM
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

; ПРОЦЕДУРЫ
;---------------------------------------
; наш обработчик прерывания 
ROUT PROC FAR
	; сохраняем используемые регистры:
	push ax
	push bp
	push es
	push ds
	push dx
	push di
	
	mov ax,cs
	mov ds,ax 
	mov es,ax 
	mov ax,CS:COUNT
	add ax,1
	mov CS:COUNT,ax
	mov di,offset vivod+34
	call WRD_TO_HEX
	mov bp,offset vivod
	call outputBP
	
	; восстанавливаем регистры:
	pop di
	pop dx
	pop ds
	pop es
	pop bp
	mov al,20h
	out 20h,al
	pop ax
	iret
	SIGNATURA dw 0ABCDh
	KEEP_PSP dw 0 ; для хранения psp нашего обработчика
	KEEP_IP dw 0 ; переменная для хранения смещения стандартного обработчика прерывания
	KEEP_CS dw 0 ; для хранения его сегмента 
	COUNT	dw 0 ; для хранения количества вызовов обработчика
	VIVOD db 'Количество вызовов прерывания:     $'
ROUT ENDP 
; --------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
;---------------------------------------
; Функция вывода строки из BP
outputBP PROC near
	push ax
	push bx
	push dx
	push cx
	mov ah,13h
	mov al,0
	mov bl,09h
	mov bh,0
	mov dh,4
	mov dl,22
	mov cx,35
	int 10h  
	pop cx
	pop dx
	pop bx
	pop ax
	ret
outputBP ENDP
LAST_BYTE:
;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
; проверка, установлен ли наш обработчик прерывания:
PROV_ROUT PROC
	mov ah,35h
	mov al,1ch
	int 21h ; получили в ES:BX адрес обработчика прерывания
	mov si,offset SIGNATURA
	sub si,offset ROUT ; в SI - смещение сигнатуры относительно начала обработчика
	mov ax,0ABCDh
	cmp ax,ES:[BX+SI] ; сравниваем сигнатуры
	je ROUT_EST
		call SET_ROUT
		jmp PROV_KONEC
	ROUT_EST:
		call DEL_ROUT
	PROV_KONEC:
	ret
PROV_ROUT ENDP
;---------------------------------------
; установка нашего обработчика:
SET_ROUT PROC
	mov ax,KEEP_PSP 
	mov es,ax ; кладём в es PSP нашей програмы
	cmp byte ptr es:[80h],0
		je UST
	cmp byte ptr es:[82h],'/'
		jne UST
	cmp byte ptr es:[83h],'u'
		jne UST
	cmp byte ptr es:[84h],'n'
		jne UST
	
	mov dx,offset PRER_NE_SET_VIVOD
	call PRINT
	ret
	
	UST:
	; сохраняем стандартный обработчик:
	call SAVE_STAND	
	
	mov dx,offset PRER_SET_VIVOD
	call PRINT
	
	push ds
	; кладём в ds:dx адрес нашего обработчика:
	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	
	; меняем адрес обработчика прерывания 1Ch:
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	
	; оставляем программу резидентно:
	mov dx,offset LAST_BYTE
	mov cl,4
	shr dx,cl ; делим dx на 16
	add dx,1
	add dx,20h
		
	xor AL,AL
	mov ah,31h
	int 21h ; оставляем наш обработчик в памяти
		
	xor AL,AL
	mov AH,4Ch
	int 21H
SET_ROUT ENDP
;---------------------------------------
; удаление нашего обработчика:
DEL_ROUT PROC
	push dx
	push ax
	push ds
	push es
	
	
	mov ax,KEEP_PSP 
	mov es,ax ; кладём в es PSP нашей програмы
	cmp byte ptr es:[80h],0
		je UDAL_KONEC
	cmp byte ptr es:[82h],'/'
		jne UDAL_KONEC
	cmp byte ptr es:[83h],'u'
		jne UDAL_KONEC
	cmp byte ptr es:[84h],'n'
		jne UDAL_KONEC
	
	mov dx,offset PRER_DEL_VIVOD
	call PRINT
	
	mov ah,35h
	mov al,1ch
	int 21h ; получили в ES:BX адрес нашего обработчика
	mov si,offset KEEP_IP
	sub si,offset ROUT
	
	; возвращаем стандартный обработчик:
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	
	; удаляем из памяти наш обработчик:
	mov ax,es:[bx+si-2] ; получили psp нашего обработчика
	mov es,ax
	mov ax,es:[2ch] ; получили сегментный адрес среды
	push es
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	mov ah,49h
	int 21h

	jmp UDAL_KONEC2
	
	UDAL_KONEC:
	mov dx,offset PRER_UZHE_SET_VIVOD
	call PRINT
	UDAL_KONEC2:
	
	pop es
	pop ds
	pop ax
	pop dx
	ret
DEL_ROUT ENDP
;---------------------------------------
; сохранение адреса стандартного обработчика в KEEP_IP и KEEP_CS:
SAVE_STAND PROC
	push ax
	push bx
	push es
	mov ah,35h
	mov al,1ch
	int 21h ; получили в ES:BX адрес обработчика прерывания
	mov KEEP_CS, ES
	mov KEEP_IP, BX
	pop es
	pop bx
	pop ax
	ret
SAVE_STAND ENDP
;---------------------------------------
BEGIN:
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP, es
	call PROV_ROUT
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

; ДАННЫЕ
DATA SEGMENT
	PRER_SET_VIVOD db 'Установка обработчика прерывания','$'
	PRER_DEL_VIVOD db 'Удаление обработчика прерывания',0DH,0AH,'$'
	PRER_UZHE_SET_VIVOD db 'Обработчик прерывания уже установлен',0DH,0AH,'$'
	PRER_NE_SET_VIVOD db 'Обработчик прерывания не установлен',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS
; СТЕК
ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS
 END BEGIN