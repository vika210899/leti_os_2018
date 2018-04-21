ASSUME CS:CODE, DS:DATA, SS:AStack
AStack SEGMENT STACK
	DW 64 DUP(?)
AStack ENDS

CODE SEGMENT

INTERRUPT PROC FAR
	jmp function
;DATA
	AD_PSP dw ?
	SR_PSP dw ?
	keep_cs dw ?
	keep_ip dw ?
	is_loaded dw 0FFDAh
	counter db 'Количество вызовов прерывания: 0000 $'
	ss_keeper dw ?
	sp_keeper dw ?
	ax_keeper dw ?
	inter_stack dw 64 dup (?)


function:
	mov ss_keeper, ss
 	mov sp_keeper, sp
 	mov ax_keeper, ax
 	mov ax, seg inter_stack
 	mov ss, ax
 	mov sp, 0
 	mov ax, ax_keeper
;	push ax
	push bx
	push cx
	push dx

	;Получение курсора
	mov ah,3h
	mov bh,0h
	int 10h
	push dx ;Сохраняем курсор в стеке

	;Установка курсора
	mov ah,02h
	mov bh,0h
	mov dx,0214h
	int 10h
	;Подсчет кол-ва прерываний
	push si
	push cx
	push ds
	mov ax,SEG counter
	mov ds,ax
	mov si,offset counter
	add si,34

	mov ah,[si]
	inc ah
	mov [si],ah
	cmp ah,3Ah
	jne _not
	mov ah,30h
	mov [si],ah

	mov bh,[si-1]
	inc bh
	mov [si-1],bh
	cmp bh,3Ah
	jne _not
	mov bh,30h
	mov [si-1],bh

	mov ch,[si-2]
	inc ch
	mov [si-2],ch
	cmp ch,3Ah
	jne _not
	mov ch,30h
	mov [si-2],ch

	mov dh,[si-3]
	inc dh
	mov [si-3],dh
	cmp dh,3Ah
	jne _not
	mov dh,30h
	mov [si-3],dh

_not:
  pop ds
	pop cx
	pop si
	;Печать строки
	push es
	push bp
	mov ax,SEG counter
	mov es,ax
	mov ax,offset counter
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,35
	mov bh,0
	int 10h
	pop bp
	pop es
	;восстановка курсора
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx

	mov ax, ss_keeper
 	mov ss, ax
 	mov ax, ax_keeper
 	mov sp, sp_keeper
	;pop ax       ;восстановление ax
	iret
INTERRUPT ENDP

LAST_BYTE PROC
LAST_BYTE ENDP

ISLOADED PROC near
	push dx
        push es
	push bx

	mov ax,351Ch ;получение вектора прерываний
	int 21h

	mov dx,es:[bx+11]
	cmp dx,0FFDAh ;проверка на совпадение кода
	je int_is_loaded
	mov al,0h
	pop bx
	pop es
	pop dx
	ret
int_is_loaded:
	mov al,01h
  pop bx
	pop es
	pop dx
	ret
ISLOADED ENDP

CHECK_UNLOAD_FLAG PROC near
	push es
	mov ax,AD_PSP
	mov es,ax
	xor bx,bx
	inc bx


	mov al,es:[81h+bx]
	inc bx
	cmp al,'/'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'u'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'n'
	jne unload_end

	mov al,1h

unload_end:
	pop es
	ret
CHECK_UNLOAD_FLAG ENDP

LOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,351Ch
	int 21h
	mov keep_ip,bx
	mov keep_cs,es

	push ds
	mov dx,offset INTERRUPT
	mov ax,seg INTERRUPT
	mov ds,ax
	mov ax,251Ch
	int 21h
	pop ds

	mov dx,offset int_loaded
	mov ah,09h
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
LOAD ENDP

UNLOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,351Ch
	int 21h

	cli
	push ds
	mov dx,es:[bx+9]   ;IP стандартного
	mov ax,es:[bx+7]   ;CS стандартного
	mov ds,ax
	mov ax,251Ch
	int 21h
	pop ds
	sti

	mov dx,offset int_unload    ;сообщение о выгрузке
	mov ah,09h
	int 21h

;Удаление MCB
	push es

	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h

	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
UNLOAD ENDP

Main PROC far

	mov bx,02Ch
	mov ax,[bx]
	mov SR_PSP,ax
	mov AD_PSP,ds  ;сохраняем PSP
	sub ax,ax
	xor bx,bx

	mov ax,data
	mov ds,ax

	call CHECK_UNLOAD_FLAG   ;Загрузка или выгрузка(проверка параметра)
	cmp al,1h
	je un_load

	call ISLOADED   ;Установлен ли разработанный вектор прерывания
	cmp al,01h
	jne al_loaded

	mov dx,offset int_al_loaded	;Уже установлен(выход с сообщение)
	mov ah,09h
	int 21h

	mov ah,4Ch
	int 21h

al_loaded:

;Загрузка
	call LOAD
;Оставляем обработчик прерываний в памяти
	mov dx,offset LAST_BYTE
	mov cl,4h
	shr dx,cl
	inc dx
	add dx,1Ah

	mov ax,3100h
	int 21h

;Выгрузка
un_load:

	call ISLOADED
	cmp al,0h
	je not_loaded

  call UNLOAD

	mov ax,4C00h
	int 21h

not_loaded:
	mov dx,offset int_not_loaded      ;Если резидент не установлен, то нежелательно выгружать стандартный ВП
	mov ah,09h
	int 21h

	mov ax,4C00h
	int 21h


Main ENDP
CODE ENDS

DATA SEGMENT
	int_not_loaded db 'Резидент не загружен',13,10,'$'
	int_al_loaded db 'Резидент уже загружен',13,10,'$'
	int_loaded db 'Резидент загружен',13,10,'$'
	int_unload db 'Резидент был выгружен',13,10,'$'
DATA ENDS
END Main
