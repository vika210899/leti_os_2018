ASSUME CS:CODE, DS:DATA, SS:SSTACK, ES:NOTHING

SSTACK SEGMENT STACK 
	DW 64 DUP(?)
SSTACK ENDS

CODE SEGMENT

ROUTINE PROC FAR
	jmp BEGIN
	PSP1   		DW ? 
	PSP2   		DW ?
	KEEP_IP 	DW ?
	KEEP_CS 	DW ? 
	SIGN 		DW 01234h
	INT_STACK	DW 64 dup (?)
	KEEP_SS		DW ?
	KEEP_AX		DW ?
	KEEP_SP		DW ?

BEGIN:
	mov 	KEEP_SS, SS
 	mov 	KEEP_SP, SP
 	mov 	KEEP_AX, AX
 	mov 	AX, seg INT_STACK
 	mov 	SS, AX
 	mov 	SP, 0
 	mov 	AX, KEEP_AX  
	in 	AL,60h
	cmp 	AL,1Eh
	jne 	STAND_INT
	jmp 	DO_REQ
STAND_INT:
	pop 	ES
	pop 	DS
	pop 	DX
	mov 	AX,CS:KEEP_AX
	mov 	SP,CS:KEEP_SP
	mov 	SS,CS:KEEP_SS
	jmp 	dword ptr CS:[KEEP_IP]	
DO_REQ:
	push 	AX
	in 	AL,61h   
	mov 	AH,AL     
	or 	AL,80h    
	out 	61h,AL    
	xchg 	AH,AL   
	out 	61h,AL    
	mov 	AL,20h     
	out 	20h,AL    
	pop 	AX
_PUSH:
	mov 	AH,05h
	mov 	CL,'D'
	mov 	CH,00h
	int 	16h
	or 	AL,AL
	jz 	_QUIT 
	CLI
	mov 	AX,ES:[1Ah]
	mov 	ES:[1Ch],AX 
	STI
	jmp 	_PUSH	
_QUIT:
	pop 	ES
	pop 	DS
	pop 	DX
	mov 	AX,CS:KEEP_AX
	mov 	AL,20h
	out 	20h,AL
	mov 	SP,CS:KEEP_SP
	mov 	SS,CS:KEEP_SS
	iret
ROUTINE ENDP

_LASTBT:
CHECK_INT PROC NEAR
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h
	mov 	AL,09h
	int 	21h
	mov 	DX,ES:[BX + 11]
	cmp 	DX,01234h
	je 	_INSTALL
	mov	 AL,00h
	jmp 	_END
_INSTALL:
	mov 	AL,01h
	jmp 	_END
_END:
	pop 	ES
	pop 	DX
	pop 	BX
	ret
CHECK_INT ENDP

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

SET_INT PROC NEAR
	push 	AX
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h
	mov 	AL,09h
	int 	21h
	mov 	KEEP_IP,BX
	mov 	KEEP_CS,ES
	push 	DS
	lea 	DX,ROUTINE
	mov 	AX,seg ROUTINE
	mov 	DS,AX
	mov 	AH,25h
	mov 	AL,09h
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

UNLOAD_INT PROC NEAR	
	push 	AX
	push 	BX
	push 	DX
	push 	ES
	mov 	AH,35h
	mov 	AL,09h
	int 	21h
	cli
	push 	DS            
	mov 	DX,ES:[BX + 7]   
	mov 	AX,ES:[BX + 9]   
	mov 	DS,AX
	mov 	AH,25h
	mov 	AL,09h
	int 	21h
	pop 	DS
	sti
	lea 	DX, STR_UNLOAD
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
	pop	AX
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
	je 	_UNLOAD		
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
	je 	_NOT2
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
	STR_INSTALL    		DB 'is installed', 0dh, 0ah, '$'
    	STR_NOT_INSTALL 	DB 'is not installed', 0dh, 0ah, '$'
   	STR_IS_ALR_INSTALL 	DB 'is already installed', 0dh, 0ah, '$'
	STR_UNLOAD		DB 'was unloaded', 0dh, 0ah, '$'
DATA ENDS

END Main 
