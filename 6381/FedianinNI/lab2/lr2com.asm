TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	jmp BEGIN
;ДАННЫЕ
saUnavailableMemory		db		'Segment address of unavailable memory: $'
STRsaUnavailableMemory	db		'????',10,13,'$'
saEnvironment			db		'Segment address of the environment: $'
STRsasaEnvironment		db		'????',10,13,'$'
TailCommandStr			db		'Tail of command string:$'
STRempty				db		' ',10,13,'$'
ContentEnvironment		db		'Content of the environment: $'
WayModule				db		'Way to module: $'
;ПРОЦЕДУРЫ
;----------------------------------------------------- 
TETR_TO_HEX		PROC  near
			and      AL,0Fh
			cmp      AL,09
			jbe      NEXT
			add      AL,07 
NEXT:      	add      AL,30h
			ret 
TETR_TO_HEX		ENDP 
;------------------------------- 
BYTE_TO_HEX		PROC  near 
;байт в AL переводится в два символа шестн. числа в AX
            push     CX
            mov      AH,AL
            call     TETR_TO_HEX 
			xchg     AL,AH      
			mov      CL,4      
			shr      AL,CL    
			call     TETR_TO_HEX ;в AL старшая цифра
			pop      CX          ;в AH младшая           
			ret 
BYTE_TO_HEX		ENDP
;------------------------------- 
WRD_TO_HEX		PROC  near 
;перевод в 16 с/с 16-ти разрядного числа
;в AX-число, DI-адрес последнего символа
            push     BX
			mov      BH,AH
			call     BYTE_TO_HEX 
			mov      [DI],AH   
			dec      DI       
			mov      [DI],AL    
			dec      DI        
			mov      AL,BH      
			call     BYTE_TO_HEX   
			mov      [DI],AH       
			dec      DI           
			mov      [DI],AL        
			pop      BX          
			ret 
WRD_TO_HEX		ENDP 
;-------------------------------------------------- 
BYTE_TO_DEC		PROC  near 
;перевод в 10 с/с, SI-адрес поля младшей цфиры    
			push     CX      
			push     DX         
			xor      AH,AH     
			xor      DX,DX     
			mov      CX,10 
loop_bd:    div      CX 
            or       DL,30h
            mov      [SI],DL
            dec      SI
            xor      DX,DX  
			cmp      AX,10  
			jae      loop_bd   
			cmp      AL,00h    
			je       end_l     
			or       AL,30h    
			mov      [SI],AL 
end_l:      pop      DX 
            pop      CX 
			ret 
BYTE_TO_DEC		ENDP
;--------------------------------------------------
PRINT_A_STR		PROC near
			mov AH,09h
            int 21h
			ret
PRINT_A_STR		ENDP
;--------------------------------------------------
; Сегментный адрес недопустимой памяти, взятый из PSP
SAUM			PROC	near
			mov 	dx,offset saUnavailableMemory
			call 	PRINT_A_STR
			push 	ax
			mov 	ax,es:[2]
			mov		di, offset STRsaUnavailableMemory
			add 	di,3
			call 	WRD_TO_HEX	;в шестнадцатеричном виде
			pop 	ax
			mov 	dx,offset STRsaUnavailableMemory
			call 	PRINT_A_STR
			ret
SAUM			ENDP
;--------------------------------------------------
; Сегментный адрес среды, передаваемой программе
SAE				PROC	near
			mov 	dx,offset saEnvironment
			call 	PRINT_A_STR
			push	ax
			mov 	ax,es:[2Ch]
			mov		di,offset STRsasaEnvironment
			add 	di,3
			call	WRD_TO_HEX ;в шестнадцатеричном виде
			pop		ax
			mov 	dx,offset STRsasaEnvironment
			call 	PRINT_A_STR
			ret
SAE				ENDP
;--------------------------------------------------
; Хвост командной строки в символьном виде
TCS				PROC	near
			mov 	dx,offset TailCommandStr
			call 	PRINT_A_STR 
			push	ax
			push	cx
			xor 	ax, ax
			xor 	cx, cx
			mov 	cl, es:[80h]
			cmp 	cl, 0
			je		Empty
			xor 	di,	di
NextCharacter:
			mov 	dl, es:[81h+di]
			mov 	ah, 02h
			int 	21h
			inc 	di
			loop	NextCharacter

Empty:
			mov 	dx, offset STRempty
			call 	PRINT_A_STR
			pop		cx
			pop		ax
			ret
TCS				ENDP
;--------------------------------------------------
; Cодержимое области среды
CE				PROC	near
			mov 	dx,offset ContentEnvironment
			call 	PRINT_A_STR
			push 	es 
			push	ax 
			push	bx 
			push	cx
			mov		es,es:[2ch] 
			mov		si,0
NextParameter:
			mov		dx, offset STRempty
			call	PRINT_A_STR
			mov		ax,si 
Cycle:
			cmp 	byte ptr es:[si], 0
			je 		PrintParameter
			inc		si
			jmp 	Cycle 
PrintParameter:
			push	es:[si]
			mov		byte ptr es:[si], '$' 
			push	ds 
			mov		cx,es 
			mov		ds,cx 
			mov		dx,ax 
			call	PRINT_A_STR
			pop		ds 
			pop		es:[si]
			inc		si
			cmp 	byte ptr es:[si], 01h 
			jne 	NextParameter
			call 	WM

			pop		cx 
			pop		bx 
			pop		ax 
			pop		es 
			ret
CE				ENDP
;--------------------------------------------------
; Путь загружаемого модуля
WM				PROC near
			mov		dx, offset WayModule
			call	PRINT_A_STR
			add 	si,2
			mov		ax,si 
Cycle2:
			cmp 	byte ptr es:[si], 0
			je 		PrintParameter2 
			inc		si
			jmp 	Cycle2

PrintParameter2:			
			push	es:[si]
			mov		byte ptr es:[si], '$' 
			push	ds 
			mov		cx,es 
			mov		ds,cx 
			mov		dx,ax 
			call	PRINT_A_STR
			pop		ds 
			pop		es:[si]
			
			ret
WM				ENDP
;--------------------------------------------------
;КОД
BEGIN:			
			call 	SAUM
			call 	SAE
			call 	TCS
			call 	CE
;Вывод в DOS
			xor     AL,AL   
			mov     AH,4Ch   
			int     21H
TESTPC 		ENDS           
			END START     ;конец модуля , START - точка входа