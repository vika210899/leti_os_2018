ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN

setCurs PROC
	push ax
	push bx
	push dx
	push cx
	mov ah,02h
	mov bh,0
	;mov dh,0 ; DH, DL = строка, колонка
	;mov dl,60

	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
setCurs ENDP

getCurs PROC
	push ax
	push bx
	push cx
	mov ah,03h
	mov bh,0
	int 10h
	pop cx
	pop bx
	pop ax
	ret
getCurs ENDP

outputAL PROC
	push ax
	push bx
	push cx
	mov ah,09h  
	mov bh,0  
	mov bl,07h
	mov cx,1  
	int 10h    
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP

ROUT PROC FAR
	jmp INT_CODE
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_PSP DW 0
	COUNT DB 0
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	SIGNATURE db 'ANIME_LOVER_FOREVER$'
	INT_CODE:

	mov KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es

	call getCurs
	push dx
	mov dh,0 ; DH, DL = строка, колонка
	mov dl,79
	call setCurs

	cmp COUNT,0AH
	jl rout_skip
	mov count,0h
	rout_skip:
	mov al,COUNT
	or al,30h
	call outputAL

	pop dx
	call setCurs
	inc COUNT

	pop es
	pop ds
	pop dx
	mov ax, KEEP_AX
	mov al,20h
	out 20h,al
	mov sp, KEEP_SP
	mov ss, KEEP_SS
	
	iret
ROUT ENDP
LAST_BYTE:

CHECK_INT PROC
    mov ah,35h
    mov al,1ch
    int 21h 
	
	mov si, offset SIGNATURE
	sub si, offset ROUT
	mov di, offset STR_SIGNATURE
	mov cx, 19 ; len of SIGNATURE

	label_rabel:
		mov ah, [di]
		cmp ah, es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		inc di
		inc si
	loop label_rabel

	jmp LABEL_INT_IS_LOADED 
	
LABEL_INT_IS_NOT_LOADED:

    lea dx, STR_INT_IS_LOADED
    call PRINT

    call SET_INT

    mov dx,offset LAST_BYTE 
    mov cl,4
    shr dx,cl
    inc dx
    add dx,CODE 
    sub dx,KEEP_PSP 

    xor al,al
    mov ah,31h
    int 21h
		
LABEL_INT_IS_LOADED:
    push es
    push bx
    mov bx,KEEP_PSP
    mov es,bx

    cmp byte ptr es:[82h],'/'
    jne CI_DONT_DELETE
    cmp byte ptr es:[83h],'u'
    jne CI_DONT_DELETE
    cmp byte ptr es:[84h],'n'
    je CI_DELETE

CI_DONT_DELETE:
    pop bx
    pop es
    mov dx,offset STR_INT_IS_ALR_LOADED
    call PRINT

    ret

CI_DELETE:
    pop bx
    pop es
    call DEL_INT

    mov dx,offset STR_INT_IS_UNLOADED
    call PRINT

    ret
CHECK_INT ENDP

DEL_INT PROC
	push ds
	CLI
	mov dx,ES:[BX+3] ; IP
	mov ax,ES:[BX+5] ; CS
	mov ds,ax
	mov ax,251ch
	int 21h 

	push es
	mov ax,ES:[BX+7] ; PSP
	mov es,ax 
	mov es,es:[2Ch]
	mov ah,49h         
	int 21h

	pop es
	mov es,ES:[BX+7] ; PSP
	mov ah, 49h
	int 21h	
	STI
	pop ds

	ret
DEL_INT ENDP

SET_INT PROC
	push ds
	mov ah,35h
	mov al,1ch
	int 21h
	mov KEEP_IP,bx
	mov KEEP_CS,es

	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	
    ret
SET_INT ENDP 

PRINT PROC near
	push ax
	mov al,00h
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

BEGIN:
	mov ax,data
	mov ds,ax
	mov KEEP_PSP,es
	
	call CHECK_INT
	
	mov AX,4C00h
	int 21H
	
CODE ENDS

STACK SEGMENT STACK
	dw 100h dup (?)
STACK ENDS

DATA SEGMENT
    STR_SIGNATURE DB 'ANIME_LOVER_FOREVER$'
	STR_INT_IS_ALR_LOADED DB 'User interruption is already loaded',0DH,0AH,'$'
	STR_INT_IS_UNLOADED DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	STR_INT_IS_LOADED DB 'User interruption is loaded',0DH,0AH,'$'
DATA ENDS

END START