STACK	SEGMENT
          DW 36 DUP(?)
STACK   ENDS



; data      

DATA    SEGMENT
TYPE_OF_PC		db	'Type of IBM PC: ','$'
TYPE_PC			db 	'PC$'
TYPE_PCXT		db	'PC/XT$'
TYPE_AT			db	'AT',13,10,'$'
TYPE_PS2m30		db	'PS2 model 30','$'
TYPE_PS2m50		db	'PS2 model 50 or 60','$'
TYPE_PS2m80		db	'PS2 model 80','$'
TYPE_PCJR		db	'PCjr','$'
TYPE_PCC		db	'PC Convertible','$'
TYPE_CODE		db	'PC code:   ','$'
DOS_VER			db	'MS DOS version: 00.00      ',13,10,'$'
SERIAL_NUM		db	'Serial number OEM:     ',13,10,'$'
USER_SER_NUM	db	'User serial number: 000000',13,10,'$'

DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, SS:STACK
;----------------------------------------------------- 
TETR_TO_HEX PROC near
		and      AL,0Fh
		cmp      AL,09
		jbe      NEXT
		add      AL,07
NEXT: 	add      AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
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
;-------------------------------
WRD_TO_HEX PROC near                     
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
BYTE_TO_DEC PROC near
        push     CX
        push     DX
        xor      AH,AH
        xor      DX,DX
        mov      CX,10
loop_bd:div      CX
        or       DL,30h
		mov      [SI],DL
		dec      SI
		xor      DX,DX
		cmp      AX,10
		jae      loop_bd
		cmp      AL,00h
		je       end_l
		or       AL,30h
		mov      [SI],AL
end_l:	pop      DX
		pop CX
        ret
BYTE_TO_DEC    ENDP
;-------------------------------
PCTYPE	PROC	NEAR
		push	AX
		push	BX
		push	DX
		push	ES
		;mov 	es,ds
		mov     DX,offset TYPE_OF_PC
    	mov     AH,09h
    	int     21h
    	mov		BX,0F000H
		mov		ES,BX
		mov		AL,ES:[0FFFEH]
		cmp al,0FFh
		je PC
		cmp al,0FEh
		je PCXT
		cmp al,0FBh
		je PCXT
		cmp al,0FCh
		je AT	
		cmp al,0FAh
		je PS2m30	
		cmp al,0FCh
		je PS2m50
		cmp al,0F8h
		je PS2m80
		cmp al,0FDh
		je PCJR
		cmp al,0F9h
		je PCC
		mov		AL,ES:[0FFFEH]
		call 	BYTE_TO_HEX
		lea		BX,TYPE_CODE
		mov		[BX+9],AX
		mov     DX,offset TYPE_CODE
		jmp 	end1
	
PC:		mov     DX,offset TYPE_PC
		jmp		end1
PCXT:	mov     DX,offset TYPE_PCXT
		jmp		end1
AT:		mov     DX,offset TYPE_AT
		jmp		end1
PS2m30:	mov     DX,offset TYPE_PS2m30
		jmp		end1
PS2m50: mov     DX,offset TYPE_PS2m50
		jmp		end1
PS2m80:	mov     DX,offset TYPE_PS2m80
		jmp		end1
PCJR:	mov     DX,offset TYPE_PCJR
		jmp		end1
PCC:	mov     DX,offset TYPE_PCC
end1:   mov     AH,09h
		int     21h
		pop		ES
		pop		DX
		pop		BX
		pop		AX
		ret
PCTYPE	ENDP
;--------------------------------
VERNUM PROC NEAR
		push	ax
		push 	bx
		push 	dx
		push 	cx
		lea si,DOS_VER
		add si,17
		call BYTE_TO_DEC
		add si,3
		mov al,ah
		call BYTE_TO_DEC
		mov dx, offset DOS_VER
		mov ah,09h
		int 21h
		pop cx
		pop dx
		pop bx
		pop ax
		ret
VERNUM ENDP
;--------------------------------
SERNUM PROC NEAR
		push	ax
		push 	si
		push 	dx
		lea si,SERIAL_NUM
		add si,21
		;sub bh,1
		mov al,bh
		call BYTE_TO_DEC
		mov dx, offset SERIAL_NUM
		mov ah,09h
		int 21h
		pop dx
		pop si
		pop ax
		ret
SERNUM ENDP
;---------------------------------
USERNUM PROC NEAR
		lea di,USER_SER_NUM
		add di,20
		mov al,bl
		call BYTE_TO_HEX
		mov [di],ax
		lea di,USER_SER_NUM
		add di,25
		mov ax,cx
		call WRD_TO_HEX
		mov dx, offset USER_SER_NUM
		mov ah,09h
		int 21h
		ret
USERNUM ENDP
;---------------------------------
MAIN PROC FAR
		push  ds
    	sub   ax,ax
    	push  ax
    	mov   ax,DATA
    	mov   ds,ax
    	
		;mov dx, offset TYPE_OF_PC
		;mov ah,9
		;int 21h
		call	PCTYPE
		mov bx,0
		mov	AH,30H
		int	21h
		call 	VERNUM
		call 	SERNUM
		call	USERNUM

        xor     AL,AL
        mov     AH,4Ch
        int     21H
MAIN ENDP
CODE     ENDS
END     MAIN