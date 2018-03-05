
CODESEG SEGMENT

ASSUME CS:CODESEG, DS:CODESEG, ES:NOTHING, SS:NOTHING

ORG 100H

START:  JMP BEGIN


isPC db 'PC TYPE: PC', 0dh, 0ah, '$';
isPC_XT db 'PC TYPE: PC/XT', 0dh, 0ah, '$';
isAT db 'PC TYPE: AT', 0dh, 0ah, '$';
isPS2_30 db 'PC TYPE: PS2 model 30', 0dh, 0ah, '$';
isPS2_80 db 'PC TYPE: PS2 model 80', 0dh, 0ah, '$';
isPCjr db 'PC TYPE: PCjr', 0dh, 0ah, '$';
isPC_conv db 'PC TYPE: PC Convertible', 0dh, 0ah, '$';


TYPE_PC	db	'PC type:  '
ENDLINE DB 0, 0AH, 0DH,'$'
;label PH db at TYPE_PC

DOS_V	db	'DOS VER: '
;ENDL_DOS_V DB 0, 0AH, 0DH,'$'

MOD_N	db	' .'
END_MOD_N DB 0, 0AH, 0DH,'$'

OEM	db	'OEM:  '
ENDOEM DB 0, 0AH, 0DH,'$'

USERN	db	'USER NUMBER:     '
USERNEND DB 0, 0AH, 0DH,'$'

TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h

ret

TETR_TO_HEX ENDP

;-------------------------------

PRINT PROC near

 mov  ah,9                          
 int  21h
 ret

PRINT ENDP


BYTE_TO_HEX PROC near

	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX ;в AH младшая

ret

BYTE_TO_HEX ENDP

;-------------------------------

WRD_TO_HEX PROC near

;перевод в 16 с/с 16-ти разрядного числа

; в AX - число, DI - адрес последнего символа

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

; перевод байта в 10с/с, SI - адрес поля младшей цифры

; AL содержит исходный байт

	push	AX
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd: div CX
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
	end_l: pop DX
	pop CX
	pop	AX

	ret

BYTE_TO_DEC ENDP

;-------------------------------

; TYPE PC

PCTYPE	PROC	NEAR

	push	BX
	push	ES
	mov	BX,0F000H
	mov	ES,BX
	mov	AL,ES:[0FFFEH]
	pop	ES
	pop	BX
	ret
PCTYPE	ENDP

;;;;;;;;;;;BEGIN

BEGIN:


	push DS 
	sub AX,AX 
	push AX 


	; pc type
	mov di, offset ENDLINE
	call	PCTYPE

	; try to define pc type
	cmp al, 0ffh
		je mPC;
	cmp al, 0feh
		je mPC_XT;
	cmp al, 0fbh
		je mPC_XT;    
	cmp al, 0fch
	        je mAT;
	cmp al, 0fah
	        je mPS2_30;
	cmp al, 0f8h
        	je mPS2_80;
	cmp al, 0fdh
        	je mPCjr;
	cmp al, 0f9h
        	je mPC_conv;
        
jmp mVMSD;
    
;---------if type pc defined----------
mPC:    lea dx, isPC;
        call PRINT
        jmp mVMSD;
        
mPC_XT: lea dx, isPC_XT;
        call PRINT
        jmp mVMSD;
        
mAT:    lea dx, isAT;
         call PRINT
        jmp mVMSD;
        
mPS2_30:    lea dx, isPS2_30;
             call PRINT
            jmp mVMSD;
            
mPS2_80:    lea dx, isPS2_80;
            call PRINT
            jmp mVMSD;
            
mPCjr:  lea dx, isPCjr;
         call PRINT
        jmp mVMSD;
        
mPC_conv:   lea dx, isPC_conv;
             call PRINT
            jmp mVMSD;

;if pc type undefined

	call BYTE_TO_HEX
	mov [di-1],ax 
	;mov [PH],ax 
	mov dx, offset TYPE_PC;
	call PRINT
mVMSD:  

;;;;DOS TYPE
	mov	AH,30H
	INT	21H
	push ax
	mov si, offset MOD_N
	call BYTE_TO_DEC
	pop ax
	mov al,ah
	mov si, offset END_MOD_N
	call BYTE_TO_DEC
	mov dx, offset  DOS_V;
	call PRINT

;;;;oem

	mov al,bh
	mov di, offset ENDOEM
	call BYTE_TO_HEX
	mov [di-1],ax
	mov dx, offset OEM;
	call PRINT

;; user number

	mov ax,cx
	mov di, offset USERNEND
	call WRD_TO_HEX
	mov al,bl
	call BYTE_TO_HEX
	mov [di-2],ax
	mov dx, offset USERN;
	call PRINT

;end of program
xor AL,AL
mov AH,4Ch
int 21H


CODESEG ENDS
END START


