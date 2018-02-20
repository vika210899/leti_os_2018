.286
CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

; данные
TITLE_TAB DB 'ADDR TYPE     SIZE OWNR NAME ',0AH,0DH, '$'
SIZE_STR DB  '                         ', '$'
SIZE_EXT DB  'size of extended memory =       KB',0AH,0DH,'$'
SIZE_AVL DB  'size of available memory =        B',0AH,0DH,'$' 
STR_ERROR_48H DB 'ERROR! 48H INT 21H',0AH,0DH,'$'

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
	pop CX           ;в AH младшая
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

DWORD_TO_DEC PROC near ; перевод ax в 10с/с, SI - адрес поля младшей цифры
	pusha              ; DX:AX содержит исходное число
	mov cx, 10000
	div cx
	push ax
	mov ax, dx
	mov di, si
	sub di, 3
	call WRD_TO_DEC
	pop ax
	cmp ax, 0
	je skip_H
	cmp di,si
	je next_part
	dec si
	mov byte ptr [si], '0'
	cmp di,si
	je next_part
	dec si
	mov byte ptr [si], '0'
	cmp di,si
	je next_part
	dec si
	mov byte ptr [si], '0'
	next_part:
	dec si
	call WRD_TO_DEC
	skip_h:
	popa
	ret
DWORD_TO_DEC ENDP

CLEAR_STR_FOR_DEC PROC NEAR ; cx number of bytes to be cleared
                            ; ds:si ptr to str
	pusha
	l:
	mov byte ptr ds:[si], ' '
	dec si
	loop l
	popa
	ret
CLEAR_STR_FOR_DEC ENDP

PRINT_MCB PROC near ; input - es
	pusha
	mov ax, es:[03h]
	shl ax, 4
	
	mov di, offset SIZE_STR+3
	mov ax, es
	call WRD_TO_HEX
	
	mov al, es:[0h]
	call BYTE_TO_HEX
	mov di, offset SIZE_STR+7
	mov ds:[di], ax
	
	mov di, offset SIZE_STR+22
	mov ax, es:[01h]
	call WRD_TO_HEX
	
	mov si, offset SIZE_STR + 17
	mov ax, es:[03h]
	mov cx, 16
	mul cx
	call DWORD_TO_DEC
	
	mov dx, offset SIZE_STR
	mov ah, 09h
	int 21h
	
	mov si, offset SIZE_STR+17
	mov cx, 7
	call CLEAR_STR_FOR_DEC
	
	mov ah, 02h
	mov dl, es:[08h] 
	int 21h
	mov dl, es:[09h]
	int 21h
	mov dl, es:[0Ah] 
	int 21h
	mov dl, es:[0Bh]
	int 21h
	mov dl, es:[0Ch] 
	int 21h
	mov dl, es:[0Dh]
	int 21h
	mov dl, es:[0Eh] 
	int 21h
	mov dl, es:[0Fh]
	int 21h
	mov dl, 0AH 
	int 21h
	mov dl, 0DH
	int 21h

	popa
	ret
PRINT_MCB ENDP

PRINT_MCB_LIST PROC near
	pusha
	push es
	mov dx, offset TITLE_TAB
	mov ah, 09h
	int 21h
	
	mov ah, 52h  ; "Get List of Lists" 
	int 21h      ; ES:[BX-2] is address first mcb
	mov bx, es:[BX-2]
	mov es, bx
	
	cicl:
		add bx, es:[03h] ; ax = size of block in paragraphs
		inc bx
		
		call PRINT_MCB
		
		mov cl, es:[0h]
		cmp cl, 5Ah
		je exit
		mov es, bx
		jmp cicl
	exit:
	
	pop es
	popa
	ret
PRINT_MCB_LIST ENDP

PRINT_EXT_MEM PROC NEAR
    pusha
	
	mov al,30h
	out 70h, al
	in al, 71h
	mov bl,al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov bh, al
	
	mov ax, bx
	mov si, offset SIZE_EXT+30
	call WRD_TO_DEC
	
	mov dx, offset SIZE_EXT
	mov ah, 09h
	int 21h
	
	mov si, offset SIZE_EXT+30
	mov cx, 5
	call CLEAR_STR_FOR_DEC
    popa
	ret
PRINT_EXT_MEM ENDP

PRINT_AVL_MEM PROC NEAR
    pusha
	
	mov ah, 4AH
	mov bx, 0FFFFh
	int 21h
	mov ax, bx
	mov bx, 10h
	mul bx
	
	mov si, offset SIZE_AVL+32
	call DWORD_TO_DEC
	
	mov dx, offset SIZE_AVL
	mov ah, 09h
	int 21h
	
	mov si, offset SIZE_AVL+32
	mov cx, 6
	call CLEAR_STR_FOR_DEC
	popa
	ret
PRINT_AVL_MEM ENDP

FREE_MEMORY PROC NEAR
	pusha
	mov ax, offset end_byte_of_program
	mov bx,10h
	xor dx,dx
	div bx
	inc ax
	add ax,040h ; 200 á«®¢ ­  PSP
	add ax,020h ; 100 á«®¢
	mov bx,ax
	mov ah,4Ah
	int 21h
	popa
	ret
FREE_MEMORY ENDP

ALLOC_MEMORY PROC NEAR
	pusha
	mov ah, 48h
	mov bx, 4096 ; 4096*16 = 64KB
	int 21h
	jnc ok
		mov dx, offset STR_ERROR_48H
		mov ah, 09h
		int 21h
	ok:
	popa
	ret
ALLOC_MEMORY ENDP

BEGIN:
	push DS 
	sub AX,AX 
	push AX 
    ; my code
	
	call PRINT_AVL_MEM
	call PRINT_EXT_MEM
	;call FREE_MEMORY        ; step2
	call ALLOC_MEMORY       ; step3
	call FREE_MEMORY
	call PRINT_MCB_LIST
   
	; end of program
	xor AL,AL
	mov AH,4Ch
	int 21H
end_byte_of_program:
CODE ENDS

END START