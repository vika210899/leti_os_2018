.model small
; DATA
.data
VERSION db "MS-DOS version:  $"
MODIFICATION db 13, 10, "Modification number:  $"
SERIAL db 13, 10, "Serial number:       $"
OEM db 13, 10, "OEM:     $"
PCSTRING db 13, 10, "PC type: $"
PC db "PC$"
PCXT db "PC/XT$"
PCAT db "AT$"
PS2M_30 db "PS2 30 model$"
PS2M_50_60 db "PS2 50 or 60 model$"
PS2M_80 db "PS2 80 model$"
PCJR db "PC JR$"
PCCONV db "PC Convert$"

.stack 100h

.code
;PROCEDURES
;-------------------------------
WRITE_MSG PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE_MSG ENDP
;-------------------------------
OS_VERSION PROC near
	mov ah, 30h
	int 21h
	; al - version number
	; ah - modification number
	; bh - OEM serial number
	; bl:cx - user serial number
	push ax
	
	mov si, offset VERSION
	add si, 16
	call BYTE_TO_DEC
	mov dx, offset VERSION
	call WRITE_MSG
	
	mov si, offset MODIFICATION
	add si, 23
	pop ax
	mov al, ah
	call BYTE_TO_DEC
	mov dx, offset MODIFICATION
	call WRITE_MSG
	
	mov si, offset OEM
	add si, 9
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	call WRITE_MSG
	
	mov di, offset SERIAL
	add di, 22
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset SERIAL
	call WRITE_MSG
	ret
OS_VERSION ENDP
;-------------------------------
PC_TYPE PROC near
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
	mov dx, offset PCSTRING
	call WRITE_MSG
	cmp al, 0ffh
	jz pc_
	cmp al, 0feh
	jz pcxt_
	cmp al, 0fbh
	jz pcxt_
	cmp al, 0fch
	jz pcat_
	cmp al, 0fah
	jz pcps2m30_
	cmp al, 0f8h
	jz pcps2m80_
	cmp al, 0fdh
	jz pcjr_
	cmp al, 0f9h
	jz pcconv_
	pc_:
		mov dx, offset PC
		jmp write
	pcxt_:
		mov dx, offset PCXT
		jmp write
	pcat_:
		mov dx, offset PCAT
		jmp write
	pcps2m30_:
		mov dx, offset PS2M_30
		jmp write
	pcps2m5060_:
		mov dx, offset PS2M_50_60
		jmp write
	pcps2m80_:
		mov dx, offset PS2M_80
		jmp write
	pcjr_:
		mov dx, offset PCJR
		jmp write
	pcconv_:
		mov dx, offset PCCONV
		jmp write
	write:
		call WRITE_MSG
	ret
PC_TYPE ENDP
;-------------------------------
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
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX 
           pop      CX          
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
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
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------
; CODE
BEGIN:
		   mov ax, @data
		   mov ds, ax
		   call OS_VERSION
		   call PC_TYPE
		   mov ah, 10h
		   int 16h
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
END       BEGIN   
