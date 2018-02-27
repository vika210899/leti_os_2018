STACK	SEGMENT STACK
	DB 100h DUP(?)
STACK	ENDS

		
DATA	SEGMENT

	MODEL	db	'IBM PC type: $'

	PC		db	'PC', 0Dh,0Ah,'$'
	PCXT	db	'PC/XT', 0Dh,0Ah,'$'
	ModAT	db	'AT || PS2 model 50 or 60', 0Dh,0Ah,'$'
	PS23	db	'PS2 model 30', 0Dh,0Ah,'$'
	PS28	db	'PS2 model 80', 0Dh,0Ah,'$'
	PCjr	db	'PCjr', 0Dh,0Ah,'$'
	PCC		db	'PC Convertible', 0Dh,0Ah,'$'
	El		db	'!! - unknown type', 0Dh,0Ah,'$'

	Version	db	'MS DOS ver.:   .  ', 0Dh, 0Ah
	OEM		db	'OEM:   ', 0Dh, 0Ah
	Number	db	'User number: !!!!!!', 0Dh, 0Ah, '$'

DATA	ENDS



CODE		SEGMENT
			ASSUME  CS:CODE, DS:DATA, SS:STACK
			
TETR_TO_HEX		PROC near
		and  AL, 0Fh
		cmp  AL, 09h
		jbe  NEXT
		
		add  AL, 07h
NEXT:	add  AL, 30h
		ret
TETR_TO_HEX		ENDP
;--------------------;

; AL ---> AX
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
;------------------------;

;DI
WRD_TO_HEX		PROC near
		push BX
		
		mov  BH, AH
		call BYTE_TO_HEX
		mov  [DI], AH
		dec  DI
		mov  [DI], AL
		dec  DI
		mov  AL, BH
		call BYTE_TO_HEX
		mov  [DI], AH
		dec  DI
		mov  [DI], AL
		
		pop  BX
		ret
WRD_TO_HEX		ENDP
;-------------------------------;


;SI
BYTE_TO_DEC		PROC near
		push CX
		push DX
		
		xor  AH, AH
		xor  DX, DX
		mov  CX, 0Ah
loop_bd:
		div  CX
		or   DL, 30h
		mov  [SI], DL
		dec  SI
		xor  DX, DX
		cmp  AX, 0Ah
		jae  loop_bd
		cmp  AL, 00h
		je   end_l
		or   AL, 30h
		mov  [SI], AL
end_l:
		pop  DX
		pop  CX
		ret
BYTE_TO_DEC		ENDP
;----------------------;


MAIN	PROC far
	
	push  DS
	sub   AX,AX
	push  AX
    mov   AX,DATA
    mov   DS,AX
	
		mov  DX, offset MODEL
		mov  AH, 09h
		int  21h

		mov  AX, 0F000h
		mov  ES, AX
		
		mov  AL, ES:[0FFFEh]
;Check model
		cmp  AL, 0FCh
		ja   DEF
		jb   AB89

		mov  DX, offset ModAT
		jmp  Write_Model

	DEF:
		cmp  AL, 0FEh
		ja   F
		je   EB

			mov  DX, offset PCjr
			jmp  Write_Model
		
		F:	
			cmp  AL, 0FFh
			ja   NotM

			mov  DX, offset PC
			jmp  Write_Model

	AB89:
		cmp  AL, 0FAh
		ja   EB
		je   A

		cmp  AL, 0F8h
		je   Eight
		jb   NotM

			mov  DX, offset PCC
			jmp  Write_Model

		Eight:
			mov  DX, offset PS28
			jmp  Write_Model

		EB:
			mov  DX, offset PCXT
			jmp  Write_Model

		A:
			mov  DX, offset PS23
			jmp  Write_Model

		NotM:
			mov  DI, offset EL
			inc  DI
			call WRD_TO_HEX
			mov  DX, offset EL

Write_Model:
		mov  AH, 09h
		int  21h
;==========
	

		mov  AH, 30h
		int  21h
		
	;Version:
		mov  SI, offset Version
		add  SI, 16
		
		push AX
		
		xchg AH, AL
		call BYTE_TO_DEC
		
		pop  AX
		dec  SI
		call BYTE_TO_DEC
		
	;OEM:
		mov  AL, BH
		mov  DI, offset OEM
		add  DI, 5
		call BYTE_TO_HEX
		mov  [DI], AX

	;NUMER
		mov  DI, offset Number
		add  DI, 18
		mov  AX, CX
		call WRD_TO_HEX

		mov  AL, BL
		call BYTE_TO_HEX
		mov  [DI-2], AX

		mov  DX, offset Version
		

		mov  AH, 09h
		int  21h
; exit into DOS
		xor  AL, AL
		mov  AH, 4Ch
		int  21h
MAIN	ENDP
		
CODE	ENDS
		END   MAIN


		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		