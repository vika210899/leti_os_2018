.model small
; ДАННЫЕ
.data
version db "OS version number:  $"
modification db 13, 10, "Modification number:  $"
serial db 13, 10, "Serial number:         $" 
oem db 13, 10, "OEM serial number:     $"

type_pc_string db 13, 10, "PC type: $"
type_pc db "PC$"
type_pc_xt db "PC/XT$"
type_at db "AT$"
type_ps2_m30 db "PS2 (30 model)$"
type_ps2_m5060 db "PS2 (50 or 60 model)$"
type_ps2_m80 db "PS2 (80 model)$"
type_pc_jr db "PC jr$"
type_pc_conv db "PC Convertible$"

.stack 100h

.code
;ПРОЦЕДУРЫ
;-------------------------------
WRITE PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-------------------------------
OSVER PROC near
	
	mov ah, 30h
	int 21h
	
	mov si, offset version
	add si, 19
	call BYTE_TO_DEC
	mov dx, offset version
	call WRITE
	
	mov si, offset modification
	add si, 23
	mov al, ah
	call BYTE_TO_DEC
	mov dx, offset modification
	call WRITE
	
	mov si, offset oem
	add si, 23
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset oem
	call WRITE
	
	mov di, offset serial
	add di, 22
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset serial
	call WRITE
	ret
OSVER ENDP
;-------------------------------
PCTYPE PROC near
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
	mov dx, offset type_pc_string
	call WRITE
	cmp al, 0ffh
	jz pc
	cmp al, 0feh
	jz pcxt
	cmp al, 0fbh
	jz pcxt
	cmp al, 0fch
	jz pcat
	cmp al, 0fah
	jz pcps2m30
	cmp al, 0f8h
	jz pcps2m80
	cmp al, 0fdh
	jz pcjr
	cmp al, 0f9h
	jz pcconv
	pc:
		mov dx, offset type_pc
		jmp writestring
	pcxt:
		mov dx, offset type_pc_xt
		jmp writestring
	pcat:
		mov dx, offset type_at
		jmp writestring
	pcps2m30:
		mov dx, offset type_ps2_m30
		jmp writestring

	pcps2m80:
		mov dx, offset type_ps2_m80
		jmp writestring
	pcjr:
		mov dx, offset type_pc_jr
		jmp writestring
	pcconv:
		mov dx, offset type_pc_conv
		jmp writestring
	writestring:
		call WRITE
	ret
PCTYPE ENDP
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
; перевод в 10с/с, SI - адрес поля младшей цифры
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
; КОД
BEGIN:
		   mov ax, @data
		   mov ds, ax
		   call OSVER
		   call PCTYPE

; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
END       BEGIN     ;конец модуля, START - точка входа
