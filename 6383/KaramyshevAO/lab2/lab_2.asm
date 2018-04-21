TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN
; ДАННЫЕ
OFF_MEM_ db 'Segment address of the first byte of inaccessible memory: '
OFF_MEM db '    ',0DH,0AH,'$'
SEGSR_ db 'Segmental address of the environment passed to the program: '
SEGSR db '    ',0DH,0AH,'$'
TAIL_ db 'Command-line tail: ',0DH,0AH,'$'
SREDA_ db 'The contents of the environment area in the symbolic form: ',0DH,0AH,'$'
PATH_ db 'Load module path: ',0DH,0AH,'$'
ENDL db 0DH,0AH,'$'
; ПРОЦЕДУРЫ
;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
GET_ADRESS_OFF_MEM PROC
	mov ax,es:[2]
	mov di,offset OFF_MEM+3
	call WRD_TO_HEX
	lea dx,OFF_MEM_
	call PRINT
	ret
GET_ADRESS_OFF_MEM ENDP	
;---------------------------------------
GET_SEGSR PROC
	mov ax,es:[2Ch]
	mov di,offset SEGSR+3
	call WRD_TO_HEX
	lea dx,SEGSR_
	call PRINT
	ret
GET_SEGSR  ENDP
;---------------------------------------
TAIL PROC
	mov dx,offset TAIL_
	call PRINT
	mov cx,0
	mov cl,es:[80h]
	cmp cl,0
	je TAIL_END
	mov dx,81h
	mov bx,0
	mov ah,02h
	TAIL_loop:
		mov dl,es:[bx+81h]
		int 21h
		inc	bx
	loop TAIL_loop
	mov dx,offset ENDL
	call PRINT
	TAIL_END:
	ret
TAIL ENDP
;--------------------------------------
SREDA PROC
	mov dx,offset SREDA_
	call PRINT
	push es
	; кладём в es адрес области среды
	mov ax,es:[2Ch]
	mov es,ax
	mov ah,02h
	mov bx,0
	SREDA_loop:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop
		mov dx,offset ENDL
		call PRINT
		cmp word ptr es:[bx],0000h
		jne SREDA_loop
		
	add bx,4 ; пропускаем 0001
	mov dx,offset PATH_
	call PRINT
	
	SREDA_loop2:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop2
	mov dx,offset ENDL
	call PRINT
	
	pop es
	ret
SREDA ENDP
;--------------------------------------
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
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
;---------------------------------------
; перевод в 10с/с, SI - адрес поля младшей цифры
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
;---------------------------------------
BEGIN:
	call GET_ADRESS_OFF_MEM
	call GET_SEGSR
	call TAIL
	call SREDA
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START 