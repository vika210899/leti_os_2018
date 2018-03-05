ASSUME CS:CODE, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK 
	DW 64 DUP(?)
ASTACK ENDS

CODE SEGMENT
;----------------------------
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push ax
		mov  ah, 09h
	    int  21h
	    pop	 ax
	    ret
OUTPUT_PROC ENDP
;----------------------------
INTERRUPTION PROC FAR
	jmp begin
	ADDR_PSP1   dw 0 ;offset 3
	ADDR_PSP2   dw 0 ;offset 5
	KEEP_CS 	dw 0 ;offset 7
	KEEP_IP 	dw 0 ;offset 9
	INTER_SET 	dw 0ABCDh ;offset 11
	COUNT 		db 'Interrupts: 0000 $' ;offset 13                              
begin:
	push ax      
	push bx
	push cx
	push dx
	
	mov ah, 3h ;Cчитывание позиции курсора
	mov bh, 0h
	int 10h
	push dx 
	
	mov ah,02h ;Установка курсора в определённую позицию
	mov bh,0h
	mov dx,216h 
	int 10h
	
	push si ;Считаем количество прерываний
	push cx
	push ds
	mov ax, SEG COUNT
	mov ds, ax
	lea si, COUNT
	add si, 0Fh

	mov ah,[si]
	inc ah 
	mov [si], ah
	cmp ah, 3Ah
	jne output
	mov ah, 30h
	mov [si], ah

	mov bh, [si - 1] 
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah                    
	jne output
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne output
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne output
	mov dh, 30h
	mov [si - 3],dh
	
output: 
    pop ds
    pop cx
	pop si	

	push es ;Вывод на экран	
	push bp	
	mov ax, SEG COUNT   
	mov es, ax
	lea ax, COUNT
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 10h 
	mov bh, 0h
	int 10h
	pop bp
	pop es

	pop dx ;Возвращаем курсор
	mov ah, 02h
	mov bh, 0h
	int 10h 

	pop dx
	pop cx
	pop bx
	pop ax
	iret
INTERRUPTION ENDP
;----------------------------
inter_end:
INSTALL_CHECK PROC NEAR	;Проверка установки прерывания
	push bx
	push dx
	push es

	mov ah, 35h	;Получение вектора прерываний
	mov al, 1Ch	;Функция выдает значение сегмента в ES, смещение в BX
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0ABCDh ;Проверка на совпадение кода прерывания 
	je install_
	mov al, 00h
	jmp end_install

install_:
	mov al, 01h
	jmp end_install

end_install:
	pop es
	pop dx
	pop bx
	ret
INSTALL_CHECK ENDP
;----------------------------
UN_CHECK PROC NEAR ;Проверка на то, не ввёл ли пользователь /un
	push es
	mov ax, ADDR_PSP1
	mov es, ax

	cmp byte ptr es:[82h], '/'		
	jne not_enter
	cmp byte ptr es:[83h], 'u'		
	jne not_enter
	cmp byte ptr es:[84h], 'n'
	jne not_enter
	mov al, 1h

not_enter:
	pop es
	ret
UN_CHECK ENDP
;----------------------------
INSTALL_INTER PROC NEAR ;Загрузка  обработчика прерывания
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx	;Запоминаем смещение и сегмент
	mov KEEP_CS, es

	push ds
	lea dx, INTERRUPTION
	mov ax, seg INTERRUPTION
	mov ds, ax

	mov ah, 25h
	mov al, 1Ch
	int 21h 
	pop ds

	lea dx, INSTALL 
	call OUTPUT_PROC 

	pop es
	pop dx
	pop bx
	pop ax
	ret
INSTALL_INTER ENDP
;----------------------------
UNLOAD_INTER PROC NEAR	;Выгрузка обработчика прерывания
	push ax
	push bx
	push dx
	push es
	
	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds            
	mov dx, es:[bx + 9]   
	mov ax, es:[bx + 7]   
		
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	sti
	
	lea dx, UNLOAD
	call OUTPUT_PROC 

	push es ;Удаление MCB
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
	
	mov ah, 4Ch	;Выход из программы через функцию 4C
	int 21h
	ret
UNLOAD_INTER ENDP
;----------------------------
MAIN  PROC FAR
    mov bx,2Ch
	mov ax,[bx]
	mov ADDR_PSP2,ax
	mov ADDR_PSP1,ds  ;сохраняем PSP
	mov dx, ds 
	sub ax,ax    
	xor bx,bx
	mov ax,data  
	mov ds,ax 
	xor dx, dx

	call UN_CHECK ;Проверка на введение /un 
	cmp al, 01h
	je unload_		

	call INSTALL_CHECK  ;Проверка не является ли программа резидентной
	cmp al, 01h
	jne not_resident
	
	lea dx, ALR_INSTALL ;Программа уже загружена
	call OUTPUT_PROC
	jmp quit

;Загрузка резидента
not_resident: 
	call INSTALL_INTER 
	lea dx, inter_end
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h
	
;Выгрузка резидента      
unload_:
	call INSTALL_CHECK
	cmp al, 0h
	je not_install_
	call UNLOAD_INTER
	jmp quit

;Прерывание выгружено
not_install_: 
	lea dx, UNLOAD
	call OUTPUT_PROC
	
quit:
	mov ah, 4Ch
	int 21h
MAIN  	ENDP
CODE 	ENDS

DATA SEGMENT
	INSTALL    	db 'Interrupt handler is installed', 0dh, 0ah, '$'
    NOT_INSTALL db 'Interrupt handler is not installed', 0dh, 0ah, '$'
   	ALR_INSTALL db 'Interrupt handler is already installed', 0dh, 0ah, '$'
	UNLOAD		db 'Interrupt handler was unloaded', 0dh, 0ah, '$'
DATA ENDS

END Main 