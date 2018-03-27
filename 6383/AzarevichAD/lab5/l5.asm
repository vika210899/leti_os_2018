.286
REQ_KEY equ 26h


CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACK_S	
	

	
INTERRUPT	PROC far
pusha

	in   AL, 60h			;al = скан-код
	cmp  AL, REQ_KEY		; требуемый код?
	je   do_req
popa
	jmp  dword ptr CS:[KEEP_IP]
		
do_req:
	in   AL, 61h			; 
	or   AL, 80h			;
	out  61h, AL			; 7 бит ->1
	and  AL, 7Fh			;
	out  61h, AL			; 7 бит ->0
	mov  AL, 20h		;
	out  20h, AL		; 
		
	push DX
		mov  AX, 40h		;
		mov  DS, AX			;
		mov  AX, DS:[17h]	; Флаги состояния
	pop  DX
		
	mov  CL, 'L'
	and  AX, 08h			;зажатие Alt
	je   skip
		mov  CL, 'T'
			
skip:
	mov  AH, 05h				; помещаем символ CX
	and  CH, 0					; в 
	int  16h					; буфер клавиатуры
	
	or  AL, AL					;проверка на переполнение буфера
	jz  INT_EXIT
	
		cli						;
		push DS					;
			mov  AX, 40h		;
			mov  DS, AX			;
								;
			mov  AX, DS:[1Ah]	;
			mov  DS:[1Ch], AX	;
		pop  DS					;
		sti						; Конец буф = Нач. буф.
		jmp  skip
		
		
INT_EXIT:		
popa
	mov al, 20h
	out 20h, al
	iret	
	
	nop
	INT_KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	KEEP_IP		dw 0h
	KEEP_CS 	dw 0h
	KEEP_PSP	dw 0h
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
	mov  al, 09h					; номер вектора
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
		mov  AL, 09h 			  	; номер вектора
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
		mov  AL, 09h 			  ; номер вектора
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