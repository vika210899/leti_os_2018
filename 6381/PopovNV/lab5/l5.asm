INT_STACK SEGMENT
	DW 100h DUP(?)
INT_STACK ENDS
;////////////////////////////////////////////////////////
STACK SEGMENT
	DW 100h DUP(?)
STACK ENDS
;////////////////////////////////////////////////////////
DATA SEGMENT
	INT_ALR_LOADED db 'Interruption is already loaded',13,10,'$'
	INT_UNLOADED db 'Interruption is unloaded',13,10,'$'
	INT_LOADED db 'Interruption is loaded',13,10,'$'
	INT_NO_LOADED db 'Interruption isnt loaded',13,10,'$'
DATA ENDS
;////////////////////////////////////////////////////////
CODE SEGMENT	
ASSUME CS:CODE, DS:DATA, SS:STACK
;---------------------------------------------------------------
ROUT PROC FAR ;обработчик прерывания
	jmp ROUT_CODE

	SIGNATURE db '0000'
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_PSP DW 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
ROUT_CODE:
	mov KEEP_AX,ax
	mov KEEP_SS,ss
	mov KEEP_SP,sp
	mov ax, seg INT_STACK
	mov ss, ax
	mov sp, 100h
	mov ax,KEEP_AX
	push ax
	push dx
	push ds
	push es
	
	in al,60h
	cmp al,01h
	je my_key
	pushf
	call dword ptr CS:KEEP_IP
	jmp ROUT_FIN

my_key:
	push ax
	in AL,61h
	mov ah,al
	or al,80h
	out 61h,al
	xchg ah,al
	out 61h,al
	mov al,20h
	out 20h,al
	pop ax
	
add_to_buf:
	mov ah,05h
	mov cl,'Z'
	mov ch,00h
	int 16h
	or al,al
	jz ROUT_FIN
	
	CLI
	mov ax,es:[1Ah]
	mov es:[1Ch],ax
	STI
	jmp add_to_buf

ROUT_FIN:
	pop es
	pop ds
	pop dx
	pop ax 
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov al,20h
	out 20h,al
	iret
END_ROUT:
ROUT ENDP
;---------------------------------------------------------------
CHECK_INT PROC near
	mov AH,35h 
	mov AL,09h 
	int 21h 
			
	mov SI, offset SIGNATURE
	sub SI, offset ROUT
	
	mov AX,'00' ;сравнивание известных значений сигнатуры
	cmp AX,ES:[BX+SI]
	jne NO_LOADED
	cmp AX,ES:[BX+SI+2]
	jne NO_LOADED
	mov AL,1h
	ret
NO_LOADED:
	mov AL,0h
	ret
CHECK_INT ENDP
;---------------------------------------------------------------
LOAD_INT PROC near ;загрузка прерывания
	push ax
	push cx
	push dx
	push ds
	mov ah, 35h
    mov al, 09h
    int 21h
    
    mov KEEP_IP, bx
    mov KEEP_CS, es
	mov ax, SEG ROUT
	mov dx, OFFSET ROUT
	mov ds,ax
	mov ah, 25h
    mov al, 09h
    int 21h
    
    mov dx, OFFSET END_ROUT
    mov cl,4
    shr dx,cl
    inc dx
    add dx, CODE
    sub dx, KEEP_PSP
    mov ah, 31h
    int 21h
    pop ds
	pop dx
	pop cx
	pop ax
	ret
LOAD_INT ENDP
;---------------------------------------------------------------
IS_UNLOAD PROC near ;проверка на выгрузку прерывания
	push di
	mov di, 81h
	cmp byte ptr [di+0], ' '
	jne bad_key
	cmp byte ptr [di+1], '/'
	jne bad_key
  	cmp byte ptr [di+2], 'u'
 	jne bad_key
  	cmp byte ptr [di+3], 'n'
  	jne bad_key
  	cmp byte ptr [di+4], 0Dh
  	jne bad_key
  	cmp byte ptr [di+5], 0h
  	jne bad_key
	pop di
	mov al,1
	ret
bad_key:
	pop di
	mov al,0
	ret
IS_UNLOAD ENDP
;---------------------------------------------------------------
UNLOAD_INT PROC near ;выгрузка прерывания
	push ax
	push dx
	mov ah, 35h
    mov al, 09h
    int 21h
    cli
    push ds
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
	mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

	mov es, es:KEEP_PSP
	push es
    mov es, es:[2Ch] 
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

	sti	
	pop dx
	pop ax
	ret
UNLOAD_INT ENDP
;---------------------------------------------------------------
MAIN PROC FAR
	push ds
    xor ax,ax
    push ax
    mov cs:KEEP_PSP, es
	call CHECK_INT
	cmp al, 1
	je loaded
	
	call IS_UNLOAD
	cmp al, 1
	je not_loaded
	
	mov dx, offset INT_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h	
	call LOAD_INT
	jmp end_prog
	
not_loaded:
	mov dx, offset INT_NO_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h	
	jmp end_prog
	
loaded:
	call IS_UNLOAD
	cmp al, 1
	je need_to_unload
	
	mov dx, offset INT_ALR_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h	
	jmp end_prog
	
need_to_unload:
	call UNLOAD_INT
	mov dx, offset INT_UNLOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h	
	jmp end_prog
	
end_prog:	
	xor al,al
	mov ah,4ch
	int 21h
MAIN ENDP	
CODE ENDS
END MAIN