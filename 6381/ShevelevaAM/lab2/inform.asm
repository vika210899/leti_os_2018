TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN

; ДАННЫЕ
unaccess_mem db 13, 10, "Segment address inaccessible memory:      $"
environment db 13, 10, "Segment address environment:      $"
tail db 13, 10, "Command line tail:                       $"
empty_command_line db 13, 10, "There are no symbols in the command line tail. $";
content db 13, 10, "Content of the field of the environment:", 13, 10, "$"
the_end db 13, 10, "$"
path db 13, 10, "Path:", 13, 10, "$" ; 


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
INFORM PROC near

	mov ax, es:[2]
	mov di, offset unaccess_mem
	add di, 42
	call WRD_TO_HEX
	mov dx, offset unaccess_mem
	call WRITE
	
	mov ax, es:[44]
	mov di, offset environment
	add di, 34
	call WRD_TO_HEX
	mov dx, offset environment
	call WRITE
	
	xor cx, cx
	mov cl, ds:[80h]
	mov si, offset tail
	add si, 20
	cmp cl, 0     ;проверяем, есть ли символы в хвосте командной строки
	jz empty
	xor di, di
	xor ax, ax
	read_tail: 
		mov al, ds:[81h+di]
		mov [si], al
		inc di
		inc si
		loop read_tail
		mov dx, offset tail
		call WRITE
		jmp go_to_next
	empty:
		mov dx, offset empty_command_line
		call WRITE
	go_to_next:
	

	mov dx, offset content
	call WRITE
	xor di, di
	mov bx, 2Ch
	mov ds, [bx]
	read_string:
		cmp byte ptr [di], 00h
		jz next_
		mov dl, [di]
		mov ah, 02h
		int 21h
		jmp find_end
	next_:
		push ds
		mov cx, cs
		mov ds, cx
		mov dx, offset the_end
		call WRITE
		pop ds
	find_end:
		inc di
		cmp word ptr [di], 0001h
		jz read_path
		jmp read_string
	read_path:
		push ds
		mov ax, cs
		mov ds, ax
		mov dx, offset path
		call WRITE
		pop ds
		add di, 2
	path_loop:
		cmp byte ptr [di], 00h
		jz end_
		mov dl, [di]
		mov ah, 02h
		int 21h
		inc di
		jmp path_loop
	end_:

	ret
INFORM ENDP
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
;-------------------------------
; КОД
BEGIN:		   
		   call INFORM
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START     ;конец модуля, START - точка входа
