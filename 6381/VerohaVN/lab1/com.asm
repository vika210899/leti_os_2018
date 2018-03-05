CODESEG    SEGMENT
           ASSUME  CS:CODESEG, DS:CODESEG, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN

; ДАННЫЕ
TYPE_PC		db	'Тип IBM PC:   ',0DH,0AH,'$'

MSDOS_VER 	db  'Версия MS-DOS:   .  ',0DH,0AH,'$'

OEM_NUM		db	'Серийный номер OEM:    ',0DH,0AH,'$'

USER_NUM	db	'Серийный номер пользователя:         H',0DH,0AH,'$'

        

;ПРОЦЕДУРЫ

; Процедура печати строки
WriteMsg  PROC  NEAR
          mov   AH,09h
          int   21h  ; Вызов функции DOS по прерыванию
          ret
WriteMsg  ENDP
            
;-----------------------------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
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
; в AX - число, DI - адрес последнего символа
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
; перевод байта в 10с/с, SI - адрес поля младшей цифры
; AL содержит исходный байт
	   push	    AX
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
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
end_l:     pop      DX
           pop      CX
	   pop	    AX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------

; Процедура определения типа PC
PC_INFO PROC	NEAR
	push	AX
	push	BX
	push	DX
	push	ES
	mov	BX,0F000H
	mov	ES,BX
	mov	AL,ES:[0FFFEH]
	call	BYTE_TO_HEX
	lea	BX,TYPE_PC
	mov	[BX+12],AX
	pop	ES
	pop	DX
	pop	BX
	pop	AX
	ret

PC_INFO	ENDP

; Процедура определения версии MS-DOS
SYSTEM_INFO	PROC	NEAR
	push	AX
	push	SI
	
	lea	SI,MSDOS_VER
	add	SI,16
	call	BYTE_TO_DEC

	lea	SI,MSDOS_VER
	add	SI,19
	mov	AL,AH
	call	BYTE_TO_DEC

	pop	SI
	pop	AX
	ret
SYSTEM_INFO	ENDP
        

; Процедура определения номера OEM
OEM_INFO	PROC	NEAR
	push	AX
	push	BX
	push	SI
	
	mov	AL,BH
	lea	SI,OEM_NUM
	add	SI,22
	call	BYTE_TO_DEC

	pop	SI
	pop	BX
	pop	AX
	ret
OEM_INFO	ENDP

; Процедура определения номера пользователя
USER_INFO	PROC	NEAR
	push	AX
	push	BX
	push	CX
	push	DI
	
	mov	AX,CX
	lea	DI,USER_NUM
	add	DI,36
	call	WRD_TO_HEX

	mov	AL,BL
	call	BYTE_TO_HEX
	lea	DI,USER_NUM
	add	DI,31
	mov	[DI],AX

	pop	DI
	pop	CX
	pop	BX
	pop	AX
	ret

USER_INFO	ENDP


; КОД
BEGIN:

	call	PC_INFO

	mov	AH,30H
	INT	21H	

	call	SYSTEM_INFO
	call	OEM_INFO
	call	USER_INFO
        
; Вывод версии PC
	lea	DX,TYPE_PC
	call	WriteMsg

; Вывод версии MS-DOS
	lea	DX,MSDOS_VER
	call	WriteMsg	

; Вывод номена OEM
	lea	DX,OEM_NUM
	call	WriteMsg

; Вывод номера пользователя
	lea	DX,USER_NUM
	call	WriteMsg
        
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
CODESEG     ENDS
            END     START     ;конец модуля, START - точка входа
