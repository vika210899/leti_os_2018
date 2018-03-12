.286
COM_SEG		SEGMENT
		ASSUME CS:COM_SEG, DS:COM_SEG, SS:NOTHING, ES: NOTHING
		ORG 100h
		
MAIN: jmp BEGIN

; DATA:
AoAM	db	'The amount of available memory:        B', 0Ah
SEM		db	'Size of extended memory:       KB', 0Ah, 0Ah
CMCB	db	'A chain of MCBs: ', 0Ah
HMCB	db  'Type	PSP_Address	Size		SC/SD', 0Ah, '$'
MCB		db	'  !!           !!!!                  !!!!!!!!', 0Ah, '$'
ERR_MES	db	'ERROR of function 48h int 21h', 0Ah, '$'
			
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


;SI
QW_TO_DEC		PROC near
		push CX
		
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
		pop  CX
		ret
QW_TO_DEC		ENDP
;----------------------;


Pr_1			PROC near
		
		mov  AH, 4Ah					;
		mov  BX, 0FFFFh					;
		int  21h						; BX=доступная память
	
		mov  AX, BX						;
		mov  CX, 10h					;
		mul  CX							; Paragraf->Byte
		
		mov  SI, offset AoAM			;
		add  SI, 37						;
		call QW_TO_DEC					; AX->MEM(DEC)

		ret
Pr_1			ENDP
;----------------------;


Pr_2			PROC near

		mov  AL, 30h					; запись адреса ячейки CMOS
		out  70h, AL					;
		
		in   AL, 71h					; чтение младшего байта
		mov  BL, AL						; размера расширенной памяти
		
		mov  AL, 31h					; запись адреса ячейки CMOS
		out  70h, AL					; 
		in   AL, 71h					; чтение старшего байта 
										; размера расшир. памяти
						
		mov  AH, AL						;
		mov  AL, BL						;
		mov  DX, 0						; подготовка к печати
		
		
		mov  SI, offset SEM				;
		add  SI, 29						;
		call QW_TO_DEC					; AX->MEM(DEC)
		
		ret
Pr_2			ENDP
;----------------------;


Pr_3			PROC near

		mov  AH, 52h  					;
		int  21h      					; "Get List of Lists" 
		
		mov  BX, ES:[BX-2]				; first MCB
		
again:		
		mov  ES, BX						; ES = new MCB
		mov  DI, offset MCB				; 
		
		mov  AL, ES:[00h]				;
		call BYTE_TO_HEX				;
		mov  DS:[DI+02h], AX			; тип MCB
		
		add  DI, 18						;
		mov  AX, ES:[01h]				;
		call WRD_TO_HEX					; Адрес PSP


		mov  AX, ES:[03h]				;
		mov  CX, 10h					;
		mul  CX							;
		mov  SI, offset MCB + 27		;
		call QW_TO_DEC					; РАзмер участка
		
		mov  AX, ES:[08h]				;
		mov  word ptr DS:[DI+22], AX	;
		mov  AX, ES:[0Ah]				;
		mov  word ptr DS:[DI+24], AX	;
		mov  AX, ES:[0Ch]				;
		mov  word ptr DS:[DI+26], AX	;
		mov  AX, ES:[0Eh]				;
		mov  word ptr DS:[DI+28], AX	; Копирование 8-байта
		
		mov  DX, offset MCB				;
		mov  AH, 09h					;
		int 21h							; Печать MCB
		
		cmp  byte ptr ES:[0h], 5Ah		;
		je   exit						; if(MCB==last)goto exit
		
		add  BX, ES:[03h]				;
		inc  BX							; BX = след. MCB
		jmp  again
exit:
		ret
Pr_3			ENDP
;----------------------;
FREE_MEM			PROC near
		pusha
		
		mov  AX, offset last_byte		;
		dec  AX							;
		mov  DX, 0						;
		mov  CX, 10						;
		div  CX							; AX = код в парагр.
		
		cmp  DX, 0						; 
		jz   n_i						; 
			inc  AX						; +1 параграф
	n_i:
		
		mov  BX, AX
		mov  AH, 4Ah					;
		int 21h							; освобождение неисп. памяти
		
		popa
		ret
FREE_MEM			ENDP

;-----------------------;
ALLOC_MEM		PROC near
		pusha

		mov  BX, 4096					;4096h=64KB in par.
		mov  AH, 48h
		int  21h
		
		jnc n_er
			mov  DX, offset ERR_MES
			mov  AH, 09h
			int  21h
		n_er:
		
		popa
		ret
ALLOC_MEM		ENDP

;-----------------------;


; CODE:
BEGIN:
		call Pr_1
		call Pr_2
	
		call FREE_MEM
		call ALLOC_MEM
		
			mov  DX, offset AoAM		;
			mov  AH, 09h				; печать пунктов 1,2+
			int 21h						; шапка 3
			
		call Pr_3	
		
		
; exit into DOS
		xor  AL, AL
		mov  AH, 4Ch
		int  21h
		
last_byte db 90h ;==NOP

COM_SEG		ENDS

			END		MAIN