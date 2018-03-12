AStack    SEGMENT  STACK
          DW 12 DUP(?)
AStack    ENDS

DATA SEGMENT
;ДАННЫЕ
STRtypepc			db		'?',10,13,'$'
STRsystemversion	db		'?.?',10,13,'$'
TypePC				db		'Type IBM PC: $'
SystemVersion		db		'System version: $'
STRnumberOEM		db		'???',10,13,'$'
STRnumberUser		db		'??????',10,13,'$'
NumberUser			db		'Serial number of user: $'
NumberOEM			db		'OEM serial number: $'
PC					db		'PC',10,13,'$'
PCORXT				db		'PC/XT',10,13,'$'
ATPC				db		'AT',10,13,'$'
PS2model30			db		'PS2 model 30',10,13,'$'
PS2model80			db		'PS2 model 80',10,13,'$'
PCjr				db		'PCjr',10,13,'$'
PCConvertible		db		'PC Convertible',10,13,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack
;ПРОЦЕДУРЫ
;----------------------------------------------------- 
TETR_TO_HEX   PROC  near
			and      AL,0Fh
			cmp      AL,09
			jbe      NEXT
			add      AL,07 
NEXT:      	add      AL,30h
			ret 
TETR_TO_HEX   ENDP 
;------------------------------- 
BYTE_TO_HEX   PROC  near 
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
BYTE_TO_HEX  ENDP
;------------------------------- 
WRD_TO_HEX   PROC  near 
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
WRD_TO_HEX ENDP 
;-------------------------------------------------- 
BYTE_TO_DEC   PROC  near 
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
			mov 	AH,09h
            int 	21h
			ret
PRINT_A_STR		ENDP
;--------------------------------------------------
CONDITION_TYPE_PC	PROC near
			mov 	BX,0F000h
			mov 	ES,BX
			mov 	AL,ES:[0FFFEh]
			
			mov 	DX,offset TypePC
			call 	PRINT_A_STR
			
CHOICE1:
			mov 	DX,offset PC
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE2:
			mov 	DX,offset PCORXT
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE3:
			mov 	DX,offset ATPC
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE4:
			mov 	DX,offset PS2model30
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE5:
			mov 	DX,offset PS2model80
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE6:
			mov 	DX,offset PCjr
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE7:
			mov 	DX,offset PCConvertible
			call 	PRINT_A_STR
			jmp 	END_CONDITION
CHOICE8:			
			mov 	DI,offset STRtypepc
			inc 	DI
			call 	WRD_TO_HEX
			mov 	DX,offset STRtypepc
			call 	PRINT_A_STR
END_CONDITION:
			ret
CONDITION_TYPE_PC ENDP
;--------------------------------------------------
SYSTEM_VERSION	PROC near
			push 	BX
			push 	CX
			mov 	DX,offset SystemVersion
			call 	PRINT_A_STR
			mov 	SI,offset STRsystemversion
			call 	BYTE_TO_DEC
			xchg 	AH,AL
			add 	SI,3
			call 	BYTE_TO_DEC
			mov 	DX,offset STRsystemversion
			call 	PRINT_A_STR
			pop 	CX
			pop 	BX
			ret
SYSTEM_VERSION ENDP
;--------------------------------------------------
NUMBER_OEM	PROC near
			mov 	SI,offset STRnumberOEM
			mov 	DX,offset NumberOEM
			call 	PRINT_A_STR
			push 	BX
			push 	CX
			mov 	AL,BH
			add 	SI,2
			call 	BYTE_TO_DEC
			mov 	DX,offset STRnumberOEM
			call 	PRINT_A_STR
			pop 	CX
			pop 	BX
			ret
NUMBER_OEM ENDP
;--------------------------------------------------
NUMBER_USER	PROC near
			mov 	DI,offset STRnumberUser
			mov 	DX,offset NumberUser
			call 	PRINT_A_STR
			mov 	AX,CX
			add 	DI,5
			call 	WRD_TO_HEX
			sub 	DI,2
			mov 	AL,BL
			call 	BYTE_TO_HEX
			mov		[DI],AX
			mov 	DX,offset STRnumberUser
			call 	PRINT_A_STR	
			ret
NUMBER_USER ENDP
;--------------------------------------------------
;КОД
Main	PROC  near
			mov   	AX,DATA
			mov   	DS,AX
			
			call  	CONDITION_TYPE_PC
			xor 	AX,AX
			mov 	AH,30h
			int 	21h
			call 	SYSTEM_VERSION
			call 	NUMBER_OEM
			call 	NUMBER_USER			
;Вывод в DOS
			xor     AL,AL   
			mov     AH,4Ch   
			int     21H
Main      ENDP
CODE      ENDS
          END Main
