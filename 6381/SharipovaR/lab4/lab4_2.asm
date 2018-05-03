ASSUME CS:CODE, DS:DATA, SS:ASTACK
CODE SEGMENT
DATA SEGMENT
	
	Message1    db 'Resident program has been loaded', 0dh, 0ah, '$'
    	Message2 db 'Resident program unloaded', 0dh, 0ah, '$'
   	Message3 db 'Resident program has already been loaded', 0dh, 0ah, '$'
	Message4 db "Resident has not been loaded now!", 0dh, 0ah, '$'
	myPSP dw 0	
	
	KEEP_SP dw ? ;Выделение памяти под хранение регистра SP
	KEEP_SS DW ? ;Выделение памяти под хранение регистра SS
	NEW_STACK DW 64 DUP(?); Выделение памяти под новый стек
DATA ENDS

ASTACK SEGMENT STACK 
	DW 512 DUP(?)
ASTACK ENDS

Int_1C PROC FAR
	jmp start
	PSP_AD1 dw 0  
	PSP_AD2 dw 0
	KEEP_CS dw 0                           
	KEEP_IP dw 0                           
	INTER_ADR dw 1234h       
	count	    db ' The value of counter: 0000  $' ;счетчик суммарного количества прерываний
start:
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	
	
	mov dx, seg NEW_STACK   ;
	mov ss, dx              ; Помещаем смещение до выделенной памяти под стек
	mov sp, offset NEW_STACK;
	
	push AX
	push BX
	push CX
	push DX

	;считывание позиции курсора
	mov AH, 03h
	mov BH, 0
	int 10h 
	push dx 

	;Установка курсора в определённую в DX позицию
	mov AH, 02h
	mov BH, 0
	mov dx, 0210h	;строка и колонка
	int 10h 

	push si
	push cx
	push ds
	mov ax, SEG count	    
	mov ds, ax
	mov si, offset count	    
	add si, 1Ah

	mov ah,[si]
	inc ah ;накапливаем общее суммарное число прерываний
	mov [si], ah
	cmp ah, 3Ah
	jne show
	mov ah, 30h
	mov [si], ah	

	mov bh, [si - 1] 
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah                    
	jne show
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne show
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne show
	mov dh, 30h
	mov [si - 3],dh
	
show:
	;Выводим строку на экран
    	pop ds
    	pop cx
	pop si	

	push es
	push bp	
	mov ax, SEG count   
	mov es, ax
	mov ax, offset count
	mov bp, ax

	mov ah, 13h
	mov al, 00h
	mov cx, 1Dh
	mov bh, 0
	int 10h
	pop bp
	pop es

	pop dx

	; Возвращаем курсор
	mov AH, 02h
	mov BH, 0
	int 10h 

	pop DX
	pop CX
	pop BX
	pop AX

	
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	
	iret
Int_1C ENDP


unfree_mem:

Is_loaded PROC NEAR	;проверка установки прерывания
	push bx
	push dx
	push es

	mov ah, 35h	;получение вектора
	mov al, 1Ch	; прерываний (функция выдает значение сегмента в ES, смещение в BX)
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 1234h ; проверка на совпадение кода прерывания
	je to_set
	mov al, 00h
	jmp end_set


to_set:
	mov al, 01h
	jmp end_set

end_set:
	pop es
	pop dx
	pop bx

	ret
Is_loaded ENDP

Un_check PROC NEAR
	push es
	
	mov ax, myPSP
	mov es, ax

	cmp byte ptr es:[82h], '/'		;последовательно
	jne not_un
	cmp byte ptr es:[83h], 'u'		;сравниваем символы
	jne not_un
	cmp byte ptr es:[84h], 'n'
	jne not_un

	mov al, 0001h

not_un:
	pop es
	ret
Un_check ENDP

Make_resident PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx	;запоминание смещения
	mov KEEP_CS, es ;и сегмента

	push ds
	mov dx, offset Int_1C
	mov ax, seg Int_1C
	mov ds, ax

	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds

	mov dx, offset Message1    
	call Write_message

	pop es
	pop dx
	pop bx
	pop ax

	ret
Make_resident ENDP

Unload_interr PROC NEAR	; Выгружаем обработчик прерывания
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
	
	mov dx, offset Message2
	call Write_message

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
	
	mov AX, 4C00h	;выход из программы через функцию 4C
	int 21h
	
	ret
Unload_interr ENDP

Write_message	PROC	NEAR
		push ax
		mov		ah,09h
		int		21h
		pop ax
		ret
Write_message	ENDP

Main  PROC FAR
	push ds
	call Is_loaded
	cmp al, 01h
	je start_prog
	
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_AD2, ax
	mov PSP_AD1, ds 

start_prog:
	mov dx, ds 

	sub ax, ax    
	xor bx, bx

	mov ax, DATA  
	mov ds, ax    
	
	mov myPSP, dx 
	xor dx, dx				

	call Un_check  
	cmp al, 01h
	je unload_block		;пользователь ввёл /un

	call Is_loaded  
	cmp al, 01h
	jne not_load_block
	
	mov dx, offset Message3	
	call Write_message
	jmp exit_block

not_load_block: ;программа не является резидентной в памяти
	
	call Make_resident          ; Загрузка резидента.
	
	mov dx, offset unfree_mem
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h
	int 21h
         
unload_block:

	call Is_loaded
	cmp al, 00h
	je not_set_block
	
	call Unload_interr; Выгрузка резидента
	
	jmp exit_block

not_set_block:
	mov dx, offset Message4
	call Write_message
    jmp exit_block
	
exit_block:
	mov ah, 4Ch
	int 21h

Main  	ENDP
CODE 			ENDS
		END Main 
