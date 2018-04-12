TESTPC SEGMENT
ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG	100H
START:	JMP	BEGIN
S_ENDSTR    db  0DH,0AH,'$'
S_MEM_ADDR  db  'Unavailable memory address:     h$'
S_ENV_ADDR  db  'Segment environment address:     h$'
S_TAIL      db  'Tail: $'
S_ENV_PARM  db  'Environment params: $'
S_PATH      db  'Path: $'
;-----------------------------------------------------

TETR_TO_HEX	PROC	near
    and	    AL,0Fh
    cmp	    AL,09
    jbe	    NEXT
    add	    AL,07
    NEXT:
    add	    AL,30h
    ret
TETR_TO_HEX	ENDP
;-------------------------------
BYTE_TO_HEX	PROC	near
    push    CX
    mov	    AH,AL
    call	TETR_TO_HEX
    xchg	AL,AH
    mov	    CL,4
    shr	    AL,CL
    call	TETR_TO_HEX 
    pop	CX	
    ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX	PROC	near
    push	BX
    mov	    BH,AH
    call	BYTE_TO_HEX
    mov	    [DI],AH
    dec	    DI
    mov	    [DI],AL
    dec	    DI
    mov	    AL,BH
    call	BYTE_TO_HEX
    mov	    [DI],AH
    dec	    DI
    mov	    [DI],AL
    pop	    BX
    ret 
WRD_TO_HEX ENDP

;--------------------------------------------------
BYTE_TO_DEC	PROC	near
    push    ax
    push	CX
    push	DX
    xor	    AH,AH
    xor	    DX,DX
    mov	    CX,10 
    loop_bd:
    div	    CX
    or	    DL,30h
    mov	    [SI],DL
    dec	    SI
    xor	    DX,DX
    cmp	    AX,10
    jae	    loop_bd
    cmp	    AL,00h
    je	    end_l
    or	    AL,30h
    mov	    [SI],AL
    end_l:
    pop	    DX
    pop	    CX
    pop     ax
    ret
BYTE_TO_DEC	ENDP

PRINT_STR PROC near
    push ax
    push ds
	mov AH,09h
	int 21h
    test cl, cl
    je new_line
    
    dec cl
    jmp quit

new_line:
    push es
    pop ds
    mov dx, OFFSET S_ENDSTR
    int 21h

quit:    
    pop ds
    pop ax
	ret
PRINT_STR ENDP

PRINT_MEM PROC NEAR
	mov ax, ds:[02h]
	mov di, offset S_MEM_ADDR
	add di, 31
	call WRD_TO_HEX
	mov dx, offset S_MEM_ADDR
	call PRINT_STR
	ret
PRINT_MEM ENDP

PRINT_ENV PROC NEAR
	mov ax, ds:[2Ch]
	mov di, offset S_ENV_ADDR
	add di, 32
	call WRD_TO_HEX
	mov dx, offset S_ENV_ADDR
	call PRINT_STR
	ret
PRINT_ENV ENDP

PRINT_ARGS PROC NEAR
    mov dx, OFFSET S_TAIL
    inc cl
    call PRINT_STR

	mov bx, 80h
	mov al, [bx]
	cmp al, 0
	je empty
		mov ah, 0
		mov di, ax
		mov bl, [di+81h]
		mov byte ptr [di+81h], '$'
		mov dx, 82h
        call PRINT_STR
		mov [di+81h], bl
	empty:
		ret
PRINT_ARGS ENDP

PRINT_ENV_PARAMS PROC NEAR
    test ch, ch
    jne only_path

	mov dx, offset S_ENV_PARM
	call PRINT_STR
    jmp pep_begin
    
only_path:
    mov dx, offset S_PATH
    inc cl
    call PRINT_STR

pep_begin:
    mov bx, 2Ch
	mov ax, [bx]
	mov ds, ax
	mov di,0
	mov dx, di
	
    check_for_env_end:
	cmp byte ptr [di], 0
	je exit
	
    check_for_param_endl:
	inc di
	cmp byte ptr [di], 0
	jne check_for_param_endl
	
    mov byte ptr [di], '$'
    call PRINT_STR
	
    mov byte ptr [di], 0
	inc di
	mov dx, di
    test ch, ch
    jne exit
	jmp check_for_env_end
	
    exit:
	push es
	pop ds
	ret
PRINT_ENV_PARAMS ENDP

BEGIN:

    xor cl, cl
    
    call PRINT_MEM
    call PRINT_ENV
    call PRINT_ARGS
    mov ch, 0
    call PRINT_ENV_PARAMS
    mov ch, 1
    call PRINT_ENV_PARAMS

    xor	AL,AL
    mov	AH,4Ch
    int	21H

    TESTPC	ENDS
END	START
