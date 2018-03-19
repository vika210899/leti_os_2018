.286

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACK_S	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;-------------------------------;
	
INTERRUPT	PROC far
	pusha
	push ES
		
		inc CS:COUNTER
		
		mov  AX, CS
		mov  ES, AX
		
		mov  AH, 03h				; определяем
		mov  BH, 0h					; текущее положение
		int  10h					; курсора
		push DX				; тек. строка и колонка
		push CX				; тек. нач. и конеч. строки
		
		mov  AX, CS:COUNTER			; помещаем 
		mov  DI, offset STRING + 20	; счетчик в
		call WRD_TO_HEX				; строку
		
		mov  AH, 13h				;	
		mov  AL, 1h					; исп. атр. BL; не трогать курсор
		mov  BH, 0h					; видео страница
		mov  BL, 99h
		mov  CX, 21					; символов в строке
		mov  DH, 22					; строка курс.
		mov  DL, 40					; колонка курс.
		mov  BP, offset CS:STRING	; печат. строка
		int  10h					; 
		
		pop  CX				; вост. положение
		pop  DX				; курсора
		mov  AH, 02h		;
		int  10h			;
		
	pop  ES
	popa
	
	mov al, 20h
	out 20h, al
	iret	
	
	nop
	INT_KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	STRING		db 'Number of calls:     '
	KEEP_CS		dw 0h
	KEEP_IP		dw 0h
	KEEP_PSP	dw 0h
	COUNTER		dw 0h
INTERRUPT	ENDP
QWE:		
	
	
MAIN PROC far
	push DS
		mov  CS:KEEP_PSP, DS
	and  AX, 0
	push AX
	mov  AX, DATA
	mov  DS, AX
	

	mov  ah, 35h					; функция получения вектора
	mov  al, 1Ch					; номер вектора
	int  21h						; ES:BX
	
	
	mov  DI, BX						; подготовка к
	mov  DI, offset ES:INT_KEY		; проверке на
	mov  SI, offset KEY				; пользовательское 
	mov  CX, 42						; прерывание
	
	repe cmpsb						;
	cmp  CX, 0						; проверка на польз.
	jz   nqwe 						; прерывание
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov  DX, offset INT_SET
	mov  AH, 09h
	int  21h

	mov  CS:KEEP_IP, BX
	mov  CS:KEEP_CS, ES

	push DS
		mov  DX, offset INTERRUPT 	; смещение для прерывания в DX
		mov  AX, SEG    INTERRUPT 	; сегмент прерывания	
		mov  DX, offset INTERRUPT 	; смещение для прерывания в DX
		mov  AX, SEG    INTERRUPT 	; сегмент прерывания
		mov  DS, AX				  	; помещаем в DS
		mov  AH, 25h 			  	; функция установки вектора
		mov  AL, 1Ch 			  	; номер вектора
		int  21h 				  	; меняем прерывание
	pop  DS
	
	
	
	mov  DX, offset QWE				;
	shr  DX, 4						;
	inc  DX							;
	add  DX, CODE					; воход в DOS
	sub  DX, CS:KEEP_PSP			; с сохранением
	mov  AH, 31h					; программы
	int  21h						; в памяти
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
nqwe:
	push ES
		mov  ES, CS:KEEP_PSP		; подготовка к
		mov  DI, 82h				; проверке
		mov  SI, offset TCL_KEY		; хвоста
		mov  CX, 3					; командной строки
	
		repe cmpsb					; проверка 
		cmp  CX, 0					; хвоста
		jne  alr_inst				; командной строки
	pop  ES
	
	mov  DX, offset INT_RES
	mov  AH, 09h
	int  21h	

	
	CLI
	push DS
		mov  DX, ES:KEEP_IP
		mov  AX, ES:KEEP_CS
		mov  DS, AX
		mov  AH, 25h 			  ; функция установки вектора
		mov  AL, 1Ch 			  ; номер вектора
		int  21h 				  ; меняем прерывание
	pop  DS
	STI
	
	mov  ES, ES:KEEP_PSP		; удаление 
	mov  AH, 49h				; резидентной
	int  21h					; программы
	
	jmp exit
	
alr_inst:
	mov  DX, offset INT_ALR		; Custom 
	mov  AH, 09h				; interrupt
	int 21h						; already installed
	
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