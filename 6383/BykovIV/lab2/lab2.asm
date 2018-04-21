TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN
; DATA
MEMORY_ db 13, 10, "Locked memory address:     h$" ; 17 symbols
ENVIRONMENT_ db 13, 10, "Environment address:     h$" ; 23 symbols
TAIL_ db 13, 10, "Command line tail:        $" ; 21 symbols
EMPTY_ db 13, 10, "There are no sybmols$"
CONTENT_ db 13, 10, "Content:", 13, 10, "$"
ENT_ db 13, 10, "$"
PATH_ db 13, 10, "Path:", 13, 10, "$" ; 8 symbols

;PROCEDURES
;-------------------------------
WRITE_MSG PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE_MSG ENDP
;-------------------------------
INFO PROC near 
	; MEMORY
	mov ax, ds:[02h]
	mov di, offset MEMORY_
	add di, 28
	call WRD_TO_HEX
	mov dx, offset MEMORY_
	call WRITE_MSG
	
	; ENVIRONMENT
	mov ax, ds:[2Ch]
	mov di, offset ENVIRONMENT_
	add di, 26
	call WRD_TO_HEX
	mov dx, offset ENVIRONMENT_
	call WRITE_MSG
	
	; TAIL
	xor cx, cx
	mov cl, ds:[80h]
	mov si, offset TAIL_
	add si, 20
	test cl, cl
	jz empty
	xor di, di
	xor ax, ax
	readtail: 
		mov al, ds:[81h+di]
		mov [si], al
		inc di
		inc si
		loop readtail
		mov dx, offset TAIL_
		call WRITE_MSG
		jmp nextaction
	empty:
		mov dx, offset EMPTY_
		call WRITE_MSG
	nextaction: nop
	
	; ENVIRONMENT CONTENT
	mov dx, offset CONTENT_
	call WRITE_MSG
	xor di, di
	mov bx, 2Ch
	mov ds, [bx]
	readstring:
		cmp byte ptr [di], 00h
		jz pressenter
		mov dl, [di]
		mov ah, 02h
		int 21h
		jmp findend
	pressenter:
		push ds
		mov cx, cs
		mov ds, cx
		mov dx, offset ENT_
		call WRITE_MSG
		pop ds
	findend:
		inc di
		cmp word ptr [di], 0001h
		jz readpath
		jmp readstring
	readpath:
		push ds
		mov ax, cs
		mov ds, ax
		mov dx, offset PATH_
		call WRITE_MSG
		pop ds
		add di, 2
	pathloop:
		cmp byte ptr [di], 00h
		jz final
		mov dl, [di]
		mov ah, 02h
		int 21h
		inc di
		jmp pathloop
	final:
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
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX
           pop      CX          
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near

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
; CODE
BEGIN:   
		   call INFO
		   mov ah, 10h
		   int 16h
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START   
