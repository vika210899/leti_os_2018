.286
REQ_KEY equ 1Ah ; скан-код нажатого символа '['
SSEG SEGMENT stack
db 100h dup(?)
SSEG ENDS

DATA SEGMENT
	HANDLER_SET DB 'HANDLER WILL BE SET',0AH,0DH,'$'
    HANDLER_ALREADY_SET DB 'HANDLER ALREADY SET !!!',0AH,0DH,'$'
    HANDLER_DELETED DB 'HANDLER DELETED',0AH,0DH,'$'
    HANDLER_NOT_SET DB 'HANDLER NOT SET!!!',0AH,0DH,'$'
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:CODE, SS:SSEG     


HANDLER PROC FAR
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
    in al,60h          ; al = скан-код
    cmp al, REQ_KEY    
    je do_req
    popa
    ;переключаем стек обратно ;
    cli                       ;
    mov sp, cs:KEEP_SS        ;              ;
    mov ss, sp                ;
    mov sp, cs:KEEP_SP        ;
    sti                       ;
    ; -------------------------
    jmp dword ptr cs:[KEEP_IP]  ; стандартный обработчик
    do_req:
        in al, 61h  ; al = значение порта управления клавиатурой
        mov ah, al
        or al, 80h  ; установить бит разрешения для клавиатуры
        out 61h, al ; вывести его в управляющий порт
        xchg ah, al ; извлечь исходное значение порта
        out 61h, al ; записать его обратно
        mov al, 20h ; послать сигнал о конце прерывания
        out 20h, al ; контроллеру прерываний
        
        push ds
        mov ax, 0040h
        mov ds, ax
        mov ax, ds:[17h] ; чтение флагов состояния
        pop ds
        mov cl, '['   ; исходный символ
        and ax, 0000000000000010b ; нажат ли левый SHIFT ?
        jz skip    
        mov cl, 'D' ; если да, меняем '[' на 'D'
        skip:       ; иначе cl = '['
        
        try_push_to_keyboard_buff:
        mov ah, 05h
        mov ch, 00h
        int 16h
        or al, al
        jz push_succes
        cli
        push ds
        mov ax, 0040h
        mov ds, ax
        mov ax, ds:[1Ah]
        mov ds:[1Ch], ax ; конец буффера совпадает с началом,  т.е. буффер очищен
        pop ds
        sti
        jmp try_push_to_keyboard_buff
        push_succes:
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
    ;==== data =====
    SIGN DB 'HANDLE'
    KEEP_IP DW 0
    KEEP_CS DW 0
    KEEP_PSP DW 0h
    KEEP_SS DW 0h
    KEEP_SP DW 0h
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
    mov al, 09h ; прерывание от клавиатуры
    int 21h
 
    mov cs:KEEP_IP, bx    ; 
    mov cs:KEEP_CS, es
    
    mov sp, 50h
    
    mov ax, SEG HANDLER
    mov ds, ax
    mov dx, offset HANDLER
    mov ah, 25h
    mov al, 09h
    int 21h
    
    mov dx, offset last_byte
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
    mov al, 09h
    int 21h
    push es
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
    mov ds, ax
    mov ah, 25h
    mov al, 09h
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
    mov al, 09h
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