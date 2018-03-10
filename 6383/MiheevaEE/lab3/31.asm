.286
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

SIZE_OF_AV_MEM db 'Size of available memory: $'
SZAVM db '       B$'
SIZE_OF_EXP_MEM db 'Size of expanded memory: $'
SZEXM db '      KB$'
HEAD DB 'ADDR TYPE     SIZE OWNR NAME ',0AH,0DH, '$'
SKP DB  '                         ', '$'
ERROR db 'Error.$'
STRENDL db 0DH,0AH,'$'

PRINT_SMB PROC near

mov ah, 02h
int 21h
RET
PRINT_SMB ENDP

PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
	
;---------------------------------------
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

BYTE_TO_DEC PROC near
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
	ret
BYTE_TO_DEC ENDP

WRD_TO_DEC PROC near ; перевод ax в 10с/с, SI - адрес поля младшей цифры
	push AX          ; AX содержит исходный байт
	push CX
	push DX
	xor DX,DX
	mov CX,10
	loop_bdw: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bdw
	cmp AL,00h
	je end_lw
	or AL,30h
	mov [SI],AL
	end_lw: pop DX
	pop CX
	pop	AX
	ret
WRD_TO_DEC ENDP
;---------------------------------------


DWORD_TO_DEC PROC near ; перевод ax в 10с/с, SI - адрес поля младшей цифры
	
	pusha         
	mov cx, 10000
	div cx
	push ax
	mov ax, dx
	mov di, si
	sub di, 3
	;push bx
	call WRD_TO_DEC
	pop ax
	cmp bx, 0
	je end_dw
		lp:
		cmp di,si
		je next_dw
		dec si
		mov byte ptr [si], '0'
		jmp lp

	next_dw:

	dec si
	call WRD_TO_DEC
	end_dw:
	popa
	ret


DWORD_TO_DEC ENDP



AV_MEM PROC near

mov dx,offset SIZE_OF_AV_MEM
	call PRINT
	mov si,offset SZAVM+5
	mov ah,4Ah
	mov bx,0FFFFh ; 
	int 21h ; 
	mov ax,bx
	xor dx,dx
	mov bx,10h
	mul bx
	call DWORD_TO_DEC
	mov dx,offset SZAVM
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	ret	
AV_MEM ENDP

MCB PROC near

	pusha
	push es
	mov dx, offset head
	call PRINT
	
	mov ah, 52h  
	int 21h     
	mov bx, es:[BX-2]
	mov es, bx
	
	cycle:
		add bx, es:[03h] 
		inc bx
		
		call PRINT_MCB
		
		mov cl, es:[0h]
		cmp cl, 5Ah
		je exit
		mov es, bx
		jmp cycle
	exit:
	
	pop es
	popa
	ret
MCB ENDP

EX_MEM PROC near
	
    mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov ah,al
	mov al,bl ; 
	mov dx,0 ; 
	mov si,offset SZEXM+4
	call WRD_TO_DEC
	
	mov dx,offset SIZE_OF_EXP_MEM
	call PRINT
	mov dx,offset SZEXM
	call PRINT
	mov dx,offset STRENDL
	call PRINT

	ret
EX_MEM ENDP

PRINT_MCB PROC near
	
	pusha
	mov ax, es:[03h]
	shl ax, 4
	
	mov di, offset Skp+3
	mov ax, es
	call WRD_TO_HEX
	
	mov al, es:[0h]
	call BYTE_TO_HEX
	mov di, offset Skp+7
	mov ds:[di], ax
	
	mov di, offset Skp+22
	mov ax, es:[01h]
	call WRD_TO_HEX
	
	mov si, offset Skp + 17
	mov ax, es:[03h]
	mov cx, 10h
	mul cx
	call DWORD_TO_DEC
	
	mov dx, offset Skp
	call PRINT
	
	mov si, offset Skp+17
	mov cx, 07h
	
	mov dl, es:[08h] 
	call PRINT_SMB
	mov dl, es:[09h]
	call PRINT_SMB
	mov dl, es:[0Ah] 
	call PRINT_SMB
	mov dl, es:[0Bh]
	call PRINT_SMB
	mov dl, es:[0Ch] 
	call PRINT_SMB
	mov dl, es:[0Dh]
	call PRINT_SMB
	mov dl, es:[0Eh] 
	call PRINT_SMB
	mov dl, es:[0Fh]
	call PRINT_SMB
	mov dl, 0AH 
	call PRINT_SMB
	mov dl, 0DH
	call PRINT_SMB

	popa
	ret
	popa	
	
	ret
PRINT_MCB ENDP
;---------------------------------------
BEGIN:
	call AV_MEM
	call EX_MEM
	call MCB
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START
