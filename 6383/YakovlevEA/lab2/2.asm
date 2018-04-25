TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN
; ДАННЫЕ
STRING0      db  '            Laboratornaya 2.  Sdelal Yakovlev EGOR. Gruppa 6383', 0DH, 0AH, '$'
STRING_f1 db 'Segmentniy adress pamyati:            ',0DH,0AH,'$'
STRING_f2 db 'Segmentniy adress sredi:       ',0DH,0AH,'$'
STRING_tail db 'Hvost kommandnoy stroki:       ',0DH,0AH,'$'
STRING_envir db 'The contents of the environment:  ',0DH,0AH,'$'
STRING db '                                   ',0DH,0AH,'$'
STRING_way db 'Way:                              ',0DH,0AH,'$'
String_t db '                                     ',0DH,0AH,'$'
;ПРОЦЕДУРЫ
;-------------------------------------------
WRITE PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;---------------------------------------------
INACCESSIBLE_MEMORY PROC near 
            mov 	AX, ES:[0002h]
			lea     di, STRING_f1
		    add     di, 38
			call 	WRD_TO_HEX	
			mov		AH, 09h
			lea 	DX, STRING_f1
			int 	21h
			ret
INACCESSIBLE_MEMORY ENDP	
;------------------------------------------------
ENVIRONMENT_SEGADR PROC near 
	
	mov ax, ds:[2Ch]
	mov di, offset STRING_f2
	add di, 31
	call WRD_TO_HEX
	mov dx, offset STRING_f2
	call WRITE
ENVIRONMENT_SEGADR ENDP	
;-----------------------------------------------
TAIL PROC near 	
;Получение хвоста командной строки
	xor cx, cx
	mov	bx,080h
	xor	cx,cx
	mov	cl,[bx]
	mov dx, offset STRING_tail
	call WRITE
	test cx,cx
	mov	si,081h
	mov	ah,02h
	jz not_simvol
	mov	si, offset String_t
	xor di, di
	xor ax, ax
	read_tail: 		mov al, es:[81h+di]
					mov [si], al
					inc di
					inc si
					mov dx,ax
					loop read_tail
	not_simvol:
	mov dx,offset String_t
	call WRITE	
TAIL ENDP	
;-------------------------------------------------
ENV_CONTENTS PROC near 		
	mov dx, offset STRING_envir
	call WRITE
	xor di, di
	mov bx, 2Ch
	mov ds, [bx]
	
	read:		cmp byte ptr [di], 00h
					jz pressenter
					mov dl, [di]
					mov ah, 02h
					int 21h
					jmp find_exit
					
	pressenter:		push ds
					mov cx, cs
					mov ds, cx
					mov dx, offset STRING
					call WRITE
					pop ds
					
	find_exit:		inc di
					cmp word ptr [di], 0001h
					jz read_path
					jmp read
					
	read_path:		push ds
					mov ax, cs
					mov ds, ax
					mov dx, offset STRING_way
					call WRITE
					pop ds
					add di, 2
					
	path_mesh:		cmp byte ptr [di], 00h
					jz exit
					mov dl, [di]
					mov ah, 02h
					int 21h
					inc di
					
					jmp path_mesh
					
	exit:	
		   xor     AL,AL
           mov     AH,4Ch
           int     21H
	ret
ENV_CONTENTS ENDP
;---------------------------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;------------------------------------------------------
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
;--------------------------------------------------------
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
;---------------------------------------------------------
; КОД
BEGIN:  
;Вывод приветственной строки
           lea     dx, STRING0
           mov     ah, 09h 
           int     21h  
		   
		   call INACCESSIBLE_MEMORY   		   
		   call ENVIRONMENT_SEGADR
		   mov ah, 10h
		   int 16h
		   
		   call TAIL
		   mov ah, 10h
		   int 16h
		   
		   call ENV_CONTENTS
		   mov dx,offset String_t
		   call WRITE
		   mov ah, 10h
		   int 16h
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
TESTPC    ENDS
END       START     ;конец модуля, START - точка входа
