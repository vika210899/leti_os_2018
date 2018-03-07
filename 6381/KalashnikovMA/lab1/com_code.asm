TESTPC SEGMENT
ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG	100H
START:	JMP	BEGIN
S_PC	    db	'PC',0DH,0AH,'$'
S_PC_XT	    db	'PC/XT',0DH,0AH,'$'
S_AT	    db	'AT',0DH,0AH,'$'
S_PS2_30	db	'PS2_30',0DH,0AH,'$'
S_PS2_80	db	'PS2_80',0DH,0AH,'$'
S_PCjr	    db	'PCjr',0DH,0AH,'$'
S_PC_conv	db	'PC_conv',0DH,0AH,'$'
S_ERR	    db	'Error reading IBM PC type. Bytes read: $'
S_IBMPC     db	'IBM PC type: $'
S_SYS_VER   db  'System version:  . ',0DH,0AH,'$'
S_OEM       db  'OEM number:    ',0DH,0AH,'$'
S_USER_NUM  db  'User number:       ',0DH,0AH,'$'
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
;-------------------------------

PRINT_STR PROC near
    push ax
	mov AH,09h
	int 21h
    pop ax
	ret
PRINT_STR ENDP

PC_TYPE PROC near
    
    mov dx, OFFSET S_IBMPC
    call PRINT_STR

    mov ax,0F000h
	mov es,ax
	mov al,es:0FFFEh

    cmp al, 0FFh
        jne switch_1
        mov dx, OFFSET S_PC
        jmp l_PC_TYPE_END

switch_1:
    cmp al, 0FCh
        jne switch_2
        mov dx, OFFSET S_AT
        jmp l_PC_TYPE_END

switch_2:
    cmp al, 0FAh
        jne switch_3
        mov dx, OFFSET S_PS2_30
        jmp l_PC_TYPE_END

switch_3:
    cmp al, 0F9h
        jne switch_4
        mov dx, OFFSET S_PC_conv
        jmp l_PC_TYPE_END

switch_4:
    cmp al, 0FDh
        jne switch_5
        mov dx, OFFSET S_PCjr
        jmp l_PC_TYPE_END

switch_5:
    cmp al, 0F8h
        jne switch_6
        mov dx, OFFSET S_PS2_80
        jmp l_PC_TYPE_END

switch_6:
    cmp al, 0FEh
        je switch_7
    cmp al, 0FBh
        je switch_7

        mov dx, OFFSET S_ERR
        call PRINT_STR

        call BYTE_TO_HEX
        mov cx, ax
        mov dl,cl
        mov ah,02h
        int 21h
        mov dl,ch
        int 21h

        jmp l_PC_TYPE_END_BYPASS_PRINT

switch_7:
        mov dx, OFFSET S_PC

l_PC_TYPE_END:
        call PRINT_STR

l_PC_TYPE_END_BYPASS_PRINT:
    ret
PC_TYPE ENDP

GET_VERS PROC near

    xor ax,ax
    MOV AH,30h
    INT 21h 

    mov si, OFFSET S_SYS_VER
    add si, 16 

    call BYTE_TO_DEC

    add si, 3
    xchg al, ah

    call BYTE_TO_DEC

    mov dx, OFFSET S_SYS_VER
    call PRINT_STR

    mov si, OFFSET S_OEM
    add si, 14 

    mov al, bh
    call BYTE_TO_DEC

    mov dx, OFFSET S_OEM
    call PRINT_STR

    mov di, offset S_USER_NUM
	add di, 16
	mov ax, cx
	call WRD_TO_HEX

	mov al, bl
	call BYTE_TO_HEX

	mov di, offset S_USER_NUM
	add di, 17
	mov [di], ax	

    mov dx, OFFSET S_USER_NUM
    call PRINT_STR

    ret
GET_VERS ENDP

BEGIN:

    call PC_TYPE

    call GET_VERS


    xor	AL,AL
    mov	AH,4Ch
    int	21H

    TESTPC	ENDS
END	START
