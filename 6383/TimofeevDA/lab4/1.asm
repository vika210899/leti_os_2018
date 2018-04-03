.286
SSEG SEGMENT stack
db 100h dup(?)
SSEG ENDS

DATA SEGMENT
	HANDLER_SET DB 'HANDLER WILL BE SET',0AH,0DH,'$'
    HANDLER_ALREADY_SET DB 'HANDLER ALREADY SET !!!',0AH,0DH,'$'
    HANDLER_DELETED DB 'HANDLER DELETED',0AH,0DH,'$'
    HANDLER_NOT_SET DB 'HANDLER NOT SET!!!',0AH,0DH,'$'
	VAR_STR DB 'count of interruptions=    h', 0AH, 0DH, '$'
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:CODE, SS:SSEG     
; процедуры
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX ;в AH младшая
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ;перевод в 16 с/с 16-ти разрядного числа
	push BX          ; в AX - число, DI - адрес последнего символа
	mov BH,AH        ;  now it aclually converts byte to string, last sybmol adress is di
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

BYTE_TO_DEC PROC near ; перевод байта в 10с/с, SI - адрес поля младшей цифры
	push	AX        ; AL содержит исходный байт
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
	end_l: pop DX
	pop CX
	pop	AX
	ret
BYTE_TO_DEC ENDP

HANDLER PROC FAR
    jmp entry
    SIGN DB 'HANDLE'
    entry:
    ; используем свой стек ;
    cli                    ;
    mov cs:KEEP_SS, ss     ;
    mov cs:KEEP_SP, sp     ;
    mov sp, SSEG           ;
    mov ss, sp             ;
    mov sp, 100h           ;
    sti                    ;
    ; ----------------------
    pusha
	push es
	push ds
    ; code
		; GET CURSOR ;
		mov ah,03h   ;
		mov bh, 0    ;
		int 10h      ;
		push dx      ;
		push cx      ; 
		;------------;        	
		
		mov dx, DATA
		mov es, dx
		mov ds, dx
		mov bp, offset VAR_STR	; es:bp - наша строка
		mov di, offset VAR_STR+26
		mov ax, cs:COUNTER
		call WRD_TO_HEX
		
		; PRINT STRING----;
		mov ah, 13h		  ;
		mov al, 1h        ;
		mov dh, 22        ;
		mov dl, 40        ;
		mov cx, 28        ; 
		mov bl, 99h       ;
		mov bh, 0         ;
		int 10h           ;
		;-----------------;
		
		; SET CURSOR BACK ;
		pop cx            ;
		pop dx            ;
		mov ah, 02h       ;
		int 10h           ;
		;------------------    
		inc cs:COUNTER
    ; end of code
	pop ds
	pop es
    popa
    mov al, 20h
    out 20h, al
    
    ;переключаем стек обратно ;
    cli                       ;
    mov sp, cs:KEEP_SS        ;              ;
    mov ss, sp                ;
    mov sp, cs:KEEP_SP        ;
    sti                       ;
    ; -------------------------
    
    iret
    KEEP_CS DW 0
    KEEP_IP DW 0
    KEEP_PSP DW 0h
    KEEP_SS DW 0h
    KEEP_SP DW 0h
	COUNTER DW 0h
    last_byte:
HANDLER ENDP


print_is_unload_key_entered proc near ; ds on PSP!
  pusha                               ; if "/ul" then al=1 else al=0 
  mov di, 81h
  cmp byte ptr [di+0], ' '
  jne exit_0_print_is_unload_key_entered
  cmp byte ptr [di+1], '/'
  jne exit_0_print_is_unload_key_entered
  cmp byte ptr [di+2], 'u'
  jne exit_0_print_is_unload_key_entered
  cmp byte ptr [di+3], 'n'
  jne exit_0_print_is_unload_key_entered
  cmp byte ptr [di+4], 0Dh
  jne exit_0_print_is_unload_key_entered
  cmp byte ptr [di+5], 0h
  jne exit_0_print_is_unload_key_entered
  popa
  mov al, 1
  ret
  exit_0_print_is_unload_key_entered:
  popa
  mov al, 0
  ret 
print_is_unload_key_entered endp 

SET_HANDLER PROC NEAR
    pusha
    push ds
    push es
   
    mov ah, 35h
    mov al, 1Ch
    int 21h
 
    mov cs:KEEP_IP, bx    ; 
    mov cs:KEEP_CS, es
    
    ; поскольку наш обработчик
    ; использует стек начиная с вершины (100h)
    ; то чтобы иметь гарантию, что 
    ; он не затрет наш стек, если произойдет 
    ; прерывание от таймера После установки 
    ; нашего прерывания но До выхода из программы.
    ;      Для этого перед установкой прерывания 
    ;      перемещаем указатель на вершину стека 
    ;      вперед.
    mov sp, 50h
    
    mov ax, SEG HANDLER     ; устанавливаем обработчик
    mov ds, ax
    mov dx, offset HANDLER
    mov ah, 25h
    mov al, 1Ch
    int 21h
    
    mov dx, offset last_byte ; выходим в dos
    shr dx, 4
    inc dx
    add dx, CODE
    sub dx, cs:KEEP_PSP
    mov ah, 31h
    int 21h
    
    pop es
    pop ds
    popa
    ret
SET_HANDLER ENDP


REMOVE_HANDLER PROC NEAR
    cli
    pusha
    push ds
    push es
    mov ah, 35h
    mov al, 1Ch
    int 21h
    push es
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
    mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h
    pop es
    mov es, es:KEEP_PSP
    push es
    mov es, es:[2Ch] ; MCB среды
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h
    pop es
    pop ds
    popa
    sti
    ret
REMOVE_HANDLER ENDP

CHECK_HANDLER PROC NEAR ; if set then al=1, else al=0
    cli
    pusha
    push ds
    push es
    mov ah, 35h
    mov al, 1Ch
    int 21h
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
    
    cmp word ptr es:SIGN+0, 'AH'
    jne false
    cmp word ptr es:SIGN+2, 'DN'
    jne false
    cmp word ptr es:SIGN+4, 'EL'
    jne false
    
    true:
    pop es
    pop ds
    popa
    mov al, 1
    sti
    ret
    false:
    pop es
    pop ds
    popa
    mov al, 0
    sti
    ret
CHECK_HANDLER ENDP

PRINT PROC NEAR ; dx = OFFSET TO STR
    pusha
    push ds
    mov ax, DATA
    mov ds, ax
    mov ah, 09h
    int 21h
    pop ds
    popa
    ret
PRINT ENDP

START:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds
    
    
    call print_is_unload_key_entered
    cmp al, 1
    je unload
        call CHECK_HANDLER
        cmp ax, 0
        jne already
            mov dx, offset HANDLER_SET
            call PRINT
            call SET_HANDLER
            jmp exit
        already:
            mov dx, offset HANDLER_ALREADY_SET
            call PRINT
            jmp exit
    unload:
        call CHECK_HANDLER
        cmp al, 1
        jne already_d
            call REMOVE_HANDLER
            mov dx, offset HANDLER_DELETED
            call PRINT
            jmp exit
        already_d:
            mov dx, offset HANDLER_NOT_SET
            call PRINT
	; end of program
    exit:
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END START