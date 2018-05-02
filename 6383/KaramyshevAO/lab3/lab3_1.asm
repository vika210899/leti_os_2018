TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN

DOST_MEM_STR db 'Доступная память:'
DOST_MEM_STR_ db '       байт',0DH,0AH,'$'
RASS_MEM_STR db 'Расширенная память:'
RASS_MEM_STR_ db '      Кбайт',0DH,0AH,'$'
BU_MEM_STR 	db 'Адресс Владелец   Размер   Наименование',0DH,0AH,'$'
BU_MEM		db '                             $'
STRENDL db 0DH,0AH,'$'


;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
DOST_MEM PROC
	mov ax,0
	mov ah,4Ah
	mov bx,0FFFFh 
	int 21h
	mov ax,bx 
	mov bx,16
	mul bx 
	mov si,offset DOST_MEM_STR_+5
	call TO_DEC
	mov dx,offset DOST_MEM_STR
	call PRINT
	ret
DOST_MEM ENDP
;--------------------------------------
RAS_MEM PROC
	
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov bh,al
	
	mov ax,bx
	mov dx,0
	mov si,offset RASS_MEM_STR_+4
	call TO_DEC
	mov dx,offset RASS_MEM_STR
	call PRINT
	
	ret
RAS_MEM ENDP
;--------------------------------------
MCB PROC
	mov dx,offset BU_MEM_STR
	call PRINT
	push es
	mov ah,52h
	int 21h
	mov bx,es:[bx-2]
	mov es,bx
	CYCLE:
		mov ax,es
		mov di,offset BU_MEM+4
		call WRD_TO_HEX
		mov ax,es:[01h]
		mov di,offset BU_MEM+14
		call WRD_TO_HEX
		mov ax,es:[03h]
		mov si,offset BU_MEM+26
		mov dx, 0
		mov bx, 10h
		mul bx
		call TO_DEC
		mov dx,offset BU_MEM
		call PRINT
		mov cx,8
		mov bx,8
		mov ah,02h
		CYCLE2:
			mov dl,es:[bx]
			add bx,1
			int 21h
		loop CYCLE2
		mov dx,offset STRENDL
		call PRINT
		mov ax,es
		add ax,1
		add ax,es:[03h]
		mov bl,es:[00h]
		mov es,ax
		
		push bx
		mov ax,'  '
		mov bx,offset BU_MEM
		mov [bx+19],ax
		mov [bx+21],ax
		mov [bx+23],ax
		pop bx

		cmp bl,4Dh
		je CYCLE
	pop es
	ret
MCB ENDP
;--------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
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

BYTE_TO_DEC PROC near
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
	ret
BYTE_TO_DEC ENDP

TO_DEC PROC near
	push CX
	push DX
	mov CX,10
loop_bd2: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd2
	cmp AL,00h
	je end_l2
	or AL,30h
	mov [SI],AL
end_l2: pop DX
	pop CX
	ret
TO_DEC ENDP

BEGIN:
	call DOST_MEM
	call RAS_MEM
	call MCB
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START
