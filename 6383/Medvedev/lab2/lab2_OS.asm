TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

ADDofMEM			db		'Address of unavailable memory:    ',0dh,0ah,'$'
ADDofENV			db		'Address of environment:     ',0dh,0ah,'$'
TAIL				db		'Tail:','$'
CONTofENV			db		'Content of the environment: ' , '$'
PATHofMOD			db		'PATH of the loadable module: ' , '$'
ENDL				db		0dh,0ah,'$'

SPACE		PROC	near
		lea		dx,ENDL
		call	PRINT
		ret
SPACE		ENDP

PRINT		PROC	near
		mov		ah,09h
		int		21h
		ret
PRINT		ENDP

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
; segment address of unavailable memory
MEMORY_ 	PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,ADDofMEM
		add 	di,33
		call	WRD_TO_HEX
		pop		ax
		ret
MEMORY_ 		ENDP
;  segment address of environment
SEGMENT_ 		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,ADDofENV
		add 	di,27
		call	WRD_TO_HEX
		pop		ax
		ret
SEGMENT_ 		ENDP
;  finding tail
TAIL_ 		PROC	near
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
    	call	PRINT
   	 	pop 	ds
    	pop 	es:[si]
    	pop		cx
    	pop		ax
		ret
TAIL_ 		ENDP
;  path of module
PATH_ 	PROC	near
		push 	es 
		push	ax  
		push	bx  
		push	cx 
		mov		bx,1 
		mov		es,es:[2ch]
		mov		si,0 
	POINT:
		call	SPACE
		mov		ax,si 
	POINT_:
		cmp 	byte ptr es:[si], 0 
		je 		POINT1 
		inc		si 
		jmp 	POINT_ 
	POINT1:
		push	es:[si] 
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	PRINT 
		pop		ds 
		pop		es:[si] 
		cmp		bx,0 
		jz 		POINT1_ 
		inc		si 
		cmp 	byte ptr es:[si], 01h 
    	jne 	POINT 
    	lea		dx,PATHofMOD 
    	call	PRINT 
    	mov		bx,0 
    	add 	si,2 
    	jmp 	POINT 
    POINT1_:
		pop		cx 
		pop		bx 
		pop		ax 
		pop		es 
		ret
PATH_ 	ENDP
;----------------------------
Write		PROC	near
		mov		ah,09h
		int		21h
		ret
Write		ENDP
BEGIN:
		call	MEMORY_  
		call	SEGMENT_ 
		lea		dx,ADDofMEM   
		call	PRINT  
		lea		dx,ADDofENV   
		call	PRINT  
		lea 	dx, TAIL   
    		call 	PRINT 
    		call	TAIL_ 
    		call	SPACE 
		lea		dx,CONTofENV 
		call	PRINT   
		call	PATH_ 
		xor		al,al
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START