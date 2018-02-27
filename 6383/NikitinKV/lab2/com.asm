TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN

DEFIECY_MEM_MSG db 'Сегментный адрес первого байта недоступной памяти: '
DEFIECY_MEM db '    ',0DH,0AH,'$'
SEG_ADRESS_ENV_MSG db 'Сегментный адрес среды, передаваемой программе: '
SEG_ADRESS_ENV db '    ',0DH,0AH,'$'
TAIL_ db 'Хвост командной строки: ',0DH,0AH,'$'
ENV_ db 'Содержимое области среды в символьном виде: ',0DH,0AH,'$'
PATH_ db 'Путь загружаемого модуля: ',0DH,0AH,'$'
ENDL db 0DH,0AH,'$'

WRITEMSG PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
WRITEMSG ENDP

GET_ADRESS_DEFIECY_MEM PROC
	mov ax,es:[2]
	mov di,offset DEFIECY_MEM+3
	call WRD_TO_HEX
	lea dx,DEFIECY_MEM_MSG
	call WRITEMSG
	ret
GET_ADRESS_DEFIECY_MEM ENDP	

GET_SEG_ADRESS_ENV PROC
	mov ax,es:[2Ch]
	mov di,offset SEG_ADRESS_ENV+3
	call WRD_TO_HEX
	lea dx,SEG_ADRESS_ENV_MSG
	call WRITEMSG
	ret
GET_SEG_ADRESS_ENV  ENDP

TAIL PROC
	mov dx,offset TAIL_
	call WRITEMSG
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
	call WRITEMSG
	TAIL_END:
	ret
TAIL ENDP

ENV PROC
	mov dx,offset ENV_
	call WRITEMSG
	push es
	mov ax,es:[2Ch]
	mov es,ax
	mov ah,02h
	mov bx,0
	ENV_loop:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne ENV_loop
		mov dx,offset ENDL
		call WRITEMSG
		cmp word ptr es:[bx],0000h
		jne ENV_loop
		
	add bx,4
	mov dx,offset PATH_
	call WRITEMSG
	
	ENV_loop2:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne ENV_loop2
	mov dx,offset ENDL
	call WRITEMSG
	
	pop es
	ret
ENV ENDP

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

BEGIN:
	call GET_ADRESS_DEFIECY_MEM
	call GET_SEG_ADRESS_ENV
	call TAIL
	call ENV
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START 