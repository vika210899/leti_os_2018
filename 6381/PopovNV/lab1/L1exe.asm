AStack SEGMENT STACK
DW 10 DUP(?)
AStack ENDS
;//////////////////////////////////////////////////
DATA SEGMENT
	TypePC_FF DB 'Тип IBM PC - PC',10,13,'$'
	TypePC_FEFB DB 'Тип IBM PC - PC/XT',10,13,'$'
	TypePC_AT DB 'Тип IBM PC - AT',10,13,'$'
	TypePC_FA DB 'Тип IBM PC - PS2 модель 30',10,13,'$'
	TypePC_FC DB 'Тип IBM PC - PS2 модель 50 или 60',10,13,'$'
	TypePC_F8 DB 'Тип IBM PC - PS2 модель 80',10,13,'$'
	TypePC_FD DB 'Тип IBM PC - PCjr',10,13,'$'
	TypePC_F9 DB 'Тип IBM PC - PC Convertible',10,13,'$'
	ErTypePC DB '    $'
	ErrorType DB 'Код не совпадает ни с одним значением',10,13,'Код = $'
	VersionSyst DB 'Версия системы MS DOS -   .  $'
	SerNumOEM DB 10,13,'Серийный номер OEM -    $'
	SerNumUser DB 10,13,'Серийный номер пользователя - $'
	SerNumUserStr DB '    $'
DATA ENDS
;//////////////////////////////////////////////////
CODE SEGMENT
ASSUME SS:AStack, DS:DATA, CS:CODE
TETR_TO_HEX PROC NEAR
	and al,0fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
    push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
	push CX            
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd:   
	div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l:
    pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-------------------------------
PRINT_STR PROC near
	mov ah,09h
	int 21h
	ret
PRINT_STR ENDP
;-------------------------------
FIND_TYPE_PC PROC near 
	mov ax, 0f000h 
	mov es,ax 
	mov dl,es:[0fffeh]	
	
	cmp dl, 0FFh
	jne x1
	mov DX,offset TypePC_FF
	jmp wrType
x1:
	cmp dl, 0feh
	jne x2
	mov DX,offset TypePC_FEFB
	jmp wrType
x2:
	cmp dl,  0fbh
	jne x3
	mov DX,offset TypePC_FEFB
	jmp wrType
x3:
	cmp dl, 0fch
	jne x4
	mov DX,offset TypePC_AT
	jmp wrType
x4:
	cmp dl, 0fah
	jne x5
	mov DX,offset TypePC_FA
	jmp wrType
x5:
	cmp dl, 0fch
	jne x6
	mov DX,offset TypePC_FC
	jmp wrType
x6:
	cmp dl, 0f8h
	jne x7
	mov DX,offset TypePC_F8
	jmp wrType
x7:
	cmp dl, 0fdh 
	jne x8
	mov DX,offset TypePC_FD
	jmp wrType
x8:
	cmp dl, 0f9h
	jne x9
	mov DX,offset TypePC_F9
	jmp wrType
x9:
	mov DX,offset ErrorType
	call PRINT_STR
	mov al, dl
	mov ah, 0
	mov di,offset ErTypePC+3
	call WRD_TO_HEX
	mov DX,offset ErTypePC

wrType:
	call PRINT_STR
	ret
FIND_TYPE_PC ENDP
;-------------------------------
FIND_VERSION_MS_DOS PROC near
	mov ah,30h
	int 21h
	
	cmp al,0
	mov si,offset VersionSyst+25
	mov dl,02h
	mov [si],dl
	je numBasVer0
	call BYTE_TO_DEC
numBasVer0:
	mov si,offset VersionSyst+28
	mov al,ah
	call BYTE_TO_DEC
	
	mov DX,offset VersionSyst
	call PRINT_STR
	
	mov si,offset SerNumOEM+25
	mov al,bh
	call BYTE_TO_DEC
	mov dx,offset SerNumOEM
	call PRINT_STR
	
 	mov dx,offset SerNumUser
	call PRINT_STR
	mov  al,bl
 	call BYTE_TO_HEX
 	mov bx,ax
 	mov dl,bl
 	mov ah,02h
 	int 21h
 	mov dl,bh
 	int 21h
 	
 	mov di,offset SerNumUserStr+3
 	mov ax,cx
 	call WRD_TO_HEX
 	mov dx,offset SerNumUserStr
	call PRINT_STR
	ret
FIND_VERSION_MS_DOS ENDP
;-------------------------------
Main PROC near
	push DS
	sub AX, AX
	push AX
	mov AX, DATA
	mov DS,AX
	call FIND_TYPE_PC
	call FIND_VERSION_MS_DOS
	
	xor AL,AL
	mov AH,4Ch
	int 21H
Main ENDP
CODE ENDS
END Main