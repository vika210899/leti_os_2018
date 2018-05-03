.286
		

ASSUME  DS:DATA, CS:CODE, SS:SSTACK, ES:NOTHING

SSTACK SEGMENT STACK 
	DW 64 DUP(?)
SSTACK ENDS

CODE SEGMENT
		
ROUTINE PROC FAR
	jmp		BEGIN
	PSP1   			DW 	?
	PSP2   			DW 	?
	KEEP_CS 		DW 	?
	KEEP_IP 		DW 	?
	SIGN 			DW 	01234h
	COUNTER 		DB 	'Num of call: 000 $'
	INT_STACK		DW 	64 dup (?)
	KEEP_SS			DW 	?
	KEEP_AX			DW 	?
	KEEP_SP			DW 	?
	
BEGIN:
	mov 	KEEP_SS, SS
 	mov 	KEEP_SP, SP
 	mov 	KEEP_AX, AX
 	mov 	AX,seg INT_STACK
 	mov 	SS,AX
 	mov 	SP,0
 	mov 	AX,KEEP_AX  
	push 	BX
	push 	CX
	push 	DX
	mov 	AH,3h
	mov 	BH,0h
	int 	10h
	push 	DX 
	mov 	AH,04h
	mov 	BH,0h
	mov 	DX,216h 
	int 	10h
	push 	SI
	push 	CX
	push 	DS
	mov 	AX,SEG COUNTER
	mov 	DS,AX
	lea 	SI,COUNTER
	add 	SI,0Fh
	mov 	AH,[SI]
	inc 	AH 
	mov 	[SI], AH
	cmp 	AH, 3Ah
	jne 	_OUT
	mov 	AH,30h
	mov 	[SI],AH
	mov 	BH,[SI - 1] 
	add 	BH,1
	mov 	[SI - 1],BH
	cmp 	BH,3Ah                    
	jne 	_OUT
	mov 	BH,30h
	mov 	[SI - 1],BH
	mov 	CH,[SI - 2]
	inc 	CH
	mov 	[SI - 2], CH
	cmp 	CH,3Ah
	jne 	_OUT
	mov 	CH,30h
	mov 	[SI - 2],CH
	mov 	DH,[SI - 3]
	inc 	DH
	mov 	[SI - 3],DH
	cmp 	DH,3Ah
	jne 	_OUT
	mov 	DH,30h
	mov 	[SI - 3],DH
_OUT: 
    pop 	DS
    pop 	CX
	pop 	SI	
	push 	ES
	push	BP	
	mov 	AX,SEG COUNTER   
	mov 	ES,AX
	lea 	AX,COUNTER
	mov 	BP,AX
	mov 	AH,13h
	mov 	AL,00h
	mov 	CX,10h 
	mov 	BH,0h
	int 	10h
	pop 	BP
	pop 	ES
	pop 	DX
	mov 	AH,02h
	mov		BH,0h
	int 	10h 
	pop 	DX
	pop 	CX
	pop 	BX
	mov 	AX,KEEP_SS
 	mov 	SS,AX
 	mov 	AX,KEEP_AX
 	mov 	SP,KEEP_SP
	iret
ROUTINE ENDP

_LASTBT:
CHECK_INT PROC NEAR	
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h	
	mov 	AL,1Ch	
	int 	21h
	mov 	DX,ES:[BX + 11]
	cmp 	DX,01234h
	je 		_INSTALL
	mov 	AL,00h
	jmp 	_END
_INSTALL:
	mov 	AL, 01h
	jmp 	_END
_END:
	pop 	ES
	pop 	DX
	pop 	BX
	ret
CHECK_INT ENDP

SET_INT PROC NEAR
	push 	AX
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h
	mov 	AL,1Ch
	int 	21h
	mov 	KEEP_IP,BX
	mov 	KEEP_CS,ES
	push 	DS
	lea 	DX,ROUTINE
	mov 	AX,seg ROUTINE
	mov 	DS,AX
	mov 	AH,25h
	mov 	AL,1Ch
	int 	21h 
	pop 	DS
	lea 	DX,STR_INSTALL 
	call 	OUTPUT_ALL 
	pop 	ES
	pop 	DX
	pop 	BX
	pop 	AX
	ret
SET_INT ENDP

CHECK_UN PROC NEAR
	push 	ES
	mov 	AX,PSP1
	mov 	ES,AX
	cmp 	byte ptr ES:[82h], '/'		
	jne 	_WITHOUT
	cmp 	byte ptr ES:[83h], 'u'		
	jne 	_WITHOUT
	cmp 	byte ptr ES:[84h], 'n'
	jne 	_WITHOUT
	cmp 	byte ptr ES:[85h], 0Dh
	jne 	_WITHOUT
	cmp 	byte ptr ES:[86h], 0h
	jne 	_WITHOUT
	mov 	AL,1h
_WITHOUT:
	pop 	ES
	ret
CHECK_UN ENDP

UNLOAD_INT PROC NEAR	
	push 	AX
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h
	mov 	AL,1Ch
	int 	21h
	cli
	push 	DS            
	mov 	DX,ES:[BX + 9]   
	mov 	AX,ES:[BX + 7]   
	mov 	DS,AX
	mov 	AH,25h
	mov 	AL,1Ch
	int 	21h
	pop 	DS
	sti
	lea 	DX,STR_UNLOAD
	call 	OUTPUT_ALL 
	push 	ES
	mov 	CX,ES:[BX+3]
	mov 	ES,CX
	mov 	AH,49h
	int 	21h
	pop 	ES
	mov 	CX,ES:[BX+5]
	mov 	ES,CX
	int 	21h
	pop 	ES
	pop 	DX
	pop 	BX
	pop 	AX
	mov 	AH,4Ch
	int 	21h
	ret
UNLOAD_INT ENDP

OUTPUT_ALL PROC NEAR
	push 	AX
	mov  	AH,09h
	int  	21h
	pop	 	AX
	ret
OUTPUT_ALL ENDP

MAIN  	PROC FAR
    mov 	BX,2Ch
	mov 	AX,[BX]
	mov 	PSP2,AX
	mov 	PSP1,DS 
	mov 	DX,DS 
	sub 	AX,AX    
	xor 	BX,BX
	mov 	AX,data  
	mov 	DS,AX 
	xor 	DX,DX
	call 	CHECK_UN 
	cmp 	AL,01h
	je 		_UNLOAD		
	call 	CHECK_INT 
	cmp 	AL,01h
	jne 	_NOT
	lea 	DX,STR_IS_ALR_INSTALL
	call 	OUTPUT_ALL
	jmp 	_EXIT
_NOT: 
	call 	SET_INT 
	lea 	DX,_LASTBT
	mov 	CL,04h
	shr 	DX,CL
	add 	DX,1Bh
	mov 	AX,3100h
	int 	21h
_UNLOAD:
	call 	CHECK_INT
	cmp 	AL,0h
	je 		_NOT2
	call 	UNLOAD_INT
	jmp 	_EXIT
_NOT2: 
	lea 	DX, STR_UNLOAD
	call 	OUTPUT_ALL	
_EXIT:
	mov 	AH,4Ch
	int 	21h
	
MAIN  	ENDP
CODE 	ENDS

DATA SEGMENT
	STR_INSTALL	    	DB 'is installed', 0dh, 0ah, '$'
    	STR_NOT_INSTALL 	DB 'not installed', 0dh, 0ah, '$'
   	STR_IS_ALR_INSTALL 	DB 'is already installed', 0dh, 0ah, '$'
	STR_UNLOAD		DB 'was unloaded', 0dh, 0ah, '$'
DATA ENDS

END Main 
