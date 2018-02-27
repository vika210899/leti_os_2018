TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

; ДАННЫЕ
ADD_N			db		'Address not available memory:     ',0dh,0ah,'$'
ASP_N			db		'Address of environment:     ',0dh,0ah,'$'
TAIL			db		'Commandline tail:','$'
SOD_SRED		db		'Environment scope content: ' , '$'
PATH			db		'Path to module: ' , '$'
ENDL			db		0dh,0ah,'$'

NEW_LINE		PROC	near
		lea		dx,ENDL
		call	Write_msg
		ret
NEW_LINE		ENDP

Write_msg		PROC	near
		mov		ah,09h
		int		21h
		ret
Write_msg		ENDP

TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа  в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;----------------------------
; первый байт недоступной памяти
GET_INACCESSIBLE_MEM 	PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,ADD_N
		add 	di,33
		call	WRD_TO_HEX
		pop		ax
		ret
GET_INACCESSIBLE_MEM 		ENDP
;----------------------------
;  сегментный адрес среды передаваемой программе
GET_SEGMENT_ADRESS 		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,ASP_N
		add 	di,27
		call	WRD_TO_HEX
		pop		ax
		ret
GET_SEGMENT_ADRESS 		ENDP
;----------------------------
;  хвост командной строки в символьном виде
GET_COMMANDLINE_TAIL 		PROC	near
	push	ax
		push	cx
    	xor 	ax, ax
    	mov 	al, es:[80h]
    	add 	al, 81h
    	mov 	si, ax
    	push 	es:[si]
    	mov 	byte ptr es:[si+1], '$'
    	push 	ds
    	mov 	cx, es
    	mov 	ds, cx
    	mov 	dx, 81h
    	call	Write_msg
   	 	pop 	ds
    	pop 	es:[si]
    	pop		cx
    	pop		ax
		ret
GET_COMMANDLINE_TAIL 		ENDP
;----------------------------
;  содержимое области среды и путь к модулю
GET_CONTENT_AND_PATH 	PROC	near
		push 	es 
		push	ax  
		push	bx  
		push	cx 
		mov		bx,1 
		mov		es,es:[2ch]
		mov		si,0 
	RE1:
		call	NEW_LINE ; Перенос на новую строчку
		mov		ax,si 
	RE:
		cmp 	byte ptr es:[si], 0 
		je 		NEXT2 
		inc		si 
		jmp 	RE 
	NEXT2:
		push	es:[si] 
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	Write_msg 
		pop		ds 
		pop		es:[si] 
		cmp		bx,0 
		jz 		LAST 
		inc		si 
		cmp 	byte ptr es:[si], 01h 
    	jne 	RE1 
    	lea		dx,PATH 
    	call	Write_msg 
    	mov		bx,0 
    	add 	si,2 
    	jmp 	RE1 
    LAST:
		pop		cx 
		pop		bx 
		pop		ax 
		pop		es 
		ret
GET_CONTENT_AND_PATH 	ENDP
;----------------------------
Write		PROC	near
		mov		ah,09h
		int		21h
		ret
Write		ENDP
BEGIN:
		call	GET_INACCESSIBLE_MEM  
		call	GET_SEGMENT_ADRESS 
		lea		dx,ADD_N   
		call	Write_msg  
		lea		dx,ASP_N   
		call	Write_msg  
		lea 	dx, TAIL   
    		call 	Write_msg 
    		call	GET_COMMANDLINE_TAIL 
    		call	NEW_LINE 
		lea		dx,SOD_SRED 
		call	Write_msg   
		call	GET_CONTENT_AND_PATH 
		xor		al,al
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START