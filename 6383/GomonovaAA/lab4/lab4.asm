.286

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACK_S	
	
	TETR_TO_HEX		PROC near
		and  AL, 0Fh
		cmp  AL, 09h
		jbe  NEXT
		
		add  AL, 07h
NEXT:	add  AL, 30h
		ret
TETR_TO_HEX		ENDP
BYTE_TO_HEX		PROC near
		push CX
		mov  AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov  CL, 04h
		shr  AL, CL
		call TETR_TO_HEX		
		pop CX
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC near
		push BX
		mov  BH, AH
		call BYTE_TO_HEX
		mov  ES:[DI], AH
		dec  DI
		mov  ES:[DI], AL
		dec  DI
		mov  AL, BH
		call BYTE_TO_HEX
		mov  ES:[DI], AH
		dec  DI
		mov  ES:[DI], AL
		pop  BX
		ret
WRD_TO_HEX		ENDP
	
INTERRUPT	PROC far
mov  CS:KEEP_AX, AX
mov  CS:KEEP_SS, SS
mov  CS:KEEP_SP, SP

mov  AX, SEG NEW_STACK
mov  SS, AX
mov  SP, offset QWE

	pusha
	push ES
		
		inc CS:COUNTER
		
		mov  AX, CS
		mov  ES, AX
		
		mov  AH, 03h				
		mov  BH, 0h					
		int  10h					
		push DX				
		push CX		
		mov  AX, CS:COUNTER			 
		mov  DI, offset STRING + 20	
		call WRD_TO_HEX				
		mov  AH, 13h					
		mov  AL, 1h					
		mov  BH, 0h					
		mov  BL, 99h
		mov  CX, 21				
		mov  DH, 22					
		mov  DL, 40					
		mov  BP, offset CS:STRING	
	    int  10h					 
		pop  CX			
		pop  DX				
		mov  AH, 02h		
		int  10h			
	pop  ES
	popa
mov  AX, CS:KEEP_SS
mov  SS, AX
mov  SP, CS:KEEP_SP

	mov al, 20h
	out 20h, al
	
mov  AX, CS:KEEP_AX

	iret	
	nop
	INT_KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	STRING		db 'Number of calls:     '
	KEEP_CS		dw 0h
	KEEP_IP		dw 0h
	KEEP_PSP	dw 0h
	COUNTER		dw 0h
	KEEP_SP		dw 0h
	KEEP_SS		dw 0h
	KEEP_AX		dw 0h
	NEW_STACK	db 20h DUP(0)
INTERRUPT	ENDP
QWE:		
	
MAIN PROC far
	push DS
		mov  CS:KEEP_PSP, DS
	and  AX, 0
	push AX
	mov  AX, DATA
	mov  DS, AX
	
	mov  ah, 35h					
	mov  al, 1Ch					
	int  21h		
	
	mov  DI, BX						
	mov  DI, offset ES:INT_KEY		
	mov  SI, offset KEY				 
	mov  CX, 42						
	repe cmpsb						
	cmp  CX, 0						
	jz   nqwe 					
	
	mov  DX, offset INT_SET
	mov  AH, 09h
	int  21h

	mov  CS:KEEP_IP, BX
	mov  CS:KEEP_CS, ES

	push DS
		mov  DX, offset INTERRUPT 	
		mov  AX, SEG    INTERRUPT 		
		mov  DS, AX				  	
		mov  AH, 25h 			  	
		mov  AL, 1Ch 			  
		int  21h 				  
	pop  DS
	
	mov  DX, offset QWE				
	shr  DX, 4						
	inc  DX							
	add  DX, CODE				
	sub  DX, CS:KEEP_PSP			
	mov  AH, 31h			
	int  21h			
	
nqwe:
	push ES
		mov  ES, CS:KEEP_PSP		
		mov  DI, 82h				
		mov  SI, offset TCL_KEY		
		mov  CX, 3					
	
		repe cmpsb					
		cmp  CX, 0					
		jne  alr_inst				
	pop  ES
	
	mov  DX, offset INT_RES
	mov  AH, 09h
	int  21h	
	
	CLI
	push DS
		mov  DX, ES:KEEP_IP
		mov  AX, ES:KEEP_CS
		mov  DS, AX
		mov  AH, 25h 				
		mov  AL, 1Ch 				
		int  21h 					
	pop  DS
	STI
	
	mov  ES, ES:KEEP_PSP			
	
	push ES							
		mov  ES, ES:[2Ch]			
		mov  AH, 49h  				
		int  21h					
	pop  ES						
	int  21h						

	jmp exit
	
alr_inst:
	mov  DX, offset INT_ALR		 
	mov  AH, 09h				
	int 21h							
exit:
	mov  AH, 4Ch
	int  21h
MAIN ENDP
CODE ENDS
DATA SEGMENT
	KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	INT_ALR	db 'Custom interrupt already installed', 0Ah, '$'
	INT_SET	db 'Setting the custom interrupt', 0Ah, '$'
	INT_RES	db 'Restore system interrupt', 0Ah, '$'
	TCL_KEY	db '/un'
DATA ENDS

STACK_S SEGMENT STACK
	DW 100h DUP(?)
STACK_S ENDS

END MAIN