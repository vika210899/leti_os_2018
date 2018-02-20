TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN

MEM db 13, 10, "HIDDEN MEMORY ADDRESS:     $" ; 17 symbols
ENV db 13, 10, "ENVIRONMENT ADDRESS:     $" ; 23 symbols
TAIL db 13, 10, "COMAND LINE TAIL:        $" ; 21 symbols
CONT db 13, 10, "CONTENT: ", "$"
PATH db 13, 10, "PATH: ", "$" ; 8 symbols


;-------------------------------
PRINT PROC near
	mov ah, 09h
	int 21h
	ret
PRINT ENDP
;-------------------------------
INFO PROC near 
	; Hidden memory
	mov ax, ds:[02h]
	mov di, offset MEM
	add di, 28
	call WRD_TO_HEX
	mov dx, offset MEM
	call PRINT
	
	; Environment
	mov ax, ds:[2Ch]
	mov di, offset ENV
	add di, 26
	call WRD_TO_HEX
	mov dx, offset ENV
	call PRINT
	
	; Tail
	xor cx, cx
	mov cl, ds:[80h]
	mov si, offset TAIL
	add si, 20
	cmp cl,0
	jz empty
	xor di, di
	xor ax, ax
	read_write_tail: 
		mov al, ds:[81h+di]
		mov [si], al
		inc di
		inc si
                jmp read_write_tail
		mov dx, offset TAIL
		call PRINT
		jmp content
	empty:
		mov dx, offset TAIL
		call PRINT
	content: 
	
	; Content
	mov dx, offset CONT
	call PRINT
	xor di, di
	mov bx, 2Ch
	mov ds, [bx]
	readcontent:
		cmp byte ptr [di], 00h
		mov dl, [di]
		mov ah, 02h
		int 21h
		
		inc di
		cmp word ptr [di], 0001h
		jz readpath
		jmp readcontent
	readpath:
		push ds
		mov ax, cs
		mov ds, ax
		mov dx, offset PATH
		call PRINT
		pop ds
		add di, 2
	pathloop:
		cmp byte ptr [di], 00h
		jz end
		mov dl, [di]
		mov ah, 02h
		int 21h
		inc di
		jmp pathloop
	end:
		ret
INFO ENDP
;-------------------------------

;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near

           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------
; КОД
BEGIN:   
		   call INFO
		   mov ah, 10h
		   int 16h
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START     ;конец модуля, START - точка входа
