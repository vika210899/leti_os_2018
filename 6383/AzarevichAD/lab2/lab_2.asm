COM_SEG		SEGMENT
		ASSUME CS:COM_SEG, DS:COM_SEG, SS:NOTHING, ES: NOTHING
		ORG 100h
		
MAIN: jmp BEGIN

; DATA:
AIM		db	'The address of the inaccessible memory: !!!!',0Dh,0Ah
SAF		db	'Segment address of environment: !!!!', 0Dh,0Ah		
TCL		db	'The tail of command line: $'
CEP		db	0Dh,0Ah,0Ah, 'Contents of the environment pane:', 0Dh, 0Ah, '$'
PLM		db  0Dh,0Ah, 'The path of the loaded module:', 0Dh, 0Ah, '$'
		
		
; PROCEDURES

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


; CODE:
BEGIN:
		mov  SI, 0h
		
	;1)
		mov  AX, [SI+2]
		mov  DI, offset AIM
		add  DI, 43
		call WRD_TO_HEX
	
	;2)
		mov  AX, [SI+2Ch]
		mov  DI, offset SAF
		add  DI, 35
		call WRD_TO_HEX
				
		mov  DX, offset AIM
		mov  AH, 09h
		int  21h	
	;3)
		mov  AL, [SI+80h]
		cmp  AL, 0
		je   EMPTY
			xor  AH, AH
			mov  DI, AX
			mov  BL, [DI+81h]
			mov  byte ptr [DI+81h], '$'
				mov  DX, 81h
				mov  AH, 09h
				int  21h
			mov  byte ptr [DI+81h], BL
		EMPTY:
		
	;4)
		mov  DX, offset CEP
		mov  AH, 09h
		int  21h
	
		mov  BX, [SI+2Ch]
		mov  DS, BX
		
		mov  DI, 0
		mov  CX, 0
		
	cikl:
		cmp  byte ptr [DI], 0
		jnz  METKA
		
			mov  byte ptr [DI], 0Ah
			inc  CX
			inc  DI
			
			cmp  byte ptr [DI], 0
			jnz  METKA
			
				mov  byte ptr [DI], '$'
				jmp  End_Of_Cikl
			
		
	METKA:
		inc  DI
		jmp  cikl
		
	End_Of_Cikl:
		mov  DX, 0
		mov  AH, 09h
		int  21h
		
		mov  byte ptr [DI], 0
		mov  SI, DI
	clean:
		cmp  byte ptr [SI], 0Ah
		je   dec_clean
			
			dec  SI
			jmp  clean
			
	dec_clean:
		mov  byte ptr [SI], 0
		loop clean

	;5)
		mov  AX, CS
		mov  DS, AX
		mov  DX, offset PLM
		mov  AH, 09h
		int  21h
		
		mov  DS, BX
		add  DI, 3
		mov  DX, DI
		
	cikl_2:	
		cmp  byte ptr [DI], 0
		jnz  METKA_2
			mov  word ptr [DI], 240Ah	;=0Ah, '$'
			
			int  21h
			mov  word ptr [DI], 0000h
			
			jmp FINAL
			
	METKA_2:
		inc  DI
		jmp  cikl_2
	
	
	FINAL:
		mov  AH, 4Ch
		int  21h
		
COM_SEG		ENDS

			END		MAIN