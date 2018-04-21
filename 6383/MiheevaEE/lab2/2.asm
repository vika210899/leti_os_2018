TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN

MEM db 13, 10, "HIDDEN MEMORY ADDRESS:     $" ; 17 symbols
ENV db 13, 10, "ENVIRONMENT ADDRESS:     $" ; 23 symbols
TAIL db 13, 10, "COMAND LINE TAIL: $" ; 21 symbols
CONT db 13, 10, "CONTENT: ", "$"
PATH db 13, 10, "PATH: ", "$" ; 8 symbols
NEW_LINE DB  0AH, 0DH, '$'

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
	mov dx, offset TAIL
	mov ah, 09h
	int 21h
	mov bx, 80h
	mov al, [bx] 
	cmp al, 0
	je empty
		mov ah, 0
		mov di, ax
		mov al, [di+81h]
		push ax
		mov byte ptr [di+81h], '$'
		mov dx, 81h
		call PRINT
		pop ax
		mov [di+81h], al

	empty:
	
	;content: 
	
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
; áàéò â AL ïåðåâîäèòñÿ â äâà ñèìâîëà øåñòí. ÷èñëà â AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;â AL ñòàðøàÿ öèôðà
           pop      CX          ;â AH ìëàäøàÿ
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;ïåðåâîä â 16 ñ/ñ 16-òè ðàçðÿäíîãî ÷èñëà
; â AX - ÷èñëî, DI - àäðåñ ïîñëåäíåãî ñèìâîëà
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
; ÊÎÄ
BEGIN:   
		   call INFO
		   mov ah, 10h
		   int 16h
; Âûõîä â DOS
           xor     AL,AL
	;	mov ah, 01h
     	;	int 21h
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START     ;êîíåö ìîäóëÿ, START - òî÷êà âõîäà
