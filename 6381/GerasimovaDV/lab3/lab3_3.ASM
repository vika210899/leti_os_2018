TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

;DATA
_avl_mem  db 'Доступная память (Б):                                              ',0Dh,0Ah,'$'
_ext_mem  db 'Расширенная память (КБ):                                           ',0Dh,0Ah,'$'
_table_MCB db ' Адрес   Тип MCB   Адрес PSP      Размер (Б)      SD/SC            ',0Dh,0Ah,'$'
result      db '                                                                   ',0Dh,0Ah,'$'
a        db '          ',0Dh,0AH,'$'
b        db '          ',0Dh,0AH,'$'
;END DATA

;ПРОЦЕДУРЫ
PRINT PROC near
;Печать строки
		push ax
		mov  ah,09h
		int  21h
		pop  ax
		ret
PRINT ENDP


TETR_TO_HEX PROC near
		and  AL,0Fh
		cmp  AL,09
		jbe  NEXT
		add  AL,07
NEXT:
		add  AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт AL переводится в два символа шестн. числа в AX
		push CX
		mov  AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov  CL,4
		shr  AL,CL
		call TETR_TO_HEX  ;в AL - старшая, в AH - младшая
		pop  CX
		ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
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

WRD_TO_DEC PROC near
		push CX
		push DX
		mov CX,10
loop_b:
		div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_b
		cmp AL,00h
		je endl
		or AL,30h
		mov [SI],AL
endl:
		pop DX
		pop CX
		ret
WRD_TO_DEC ENDP

GET_MCB PROC near
		mov di,offset result
		mov ax,es
		add di,4h
		call WRD_TO_HEX
		mov di,offset result
		;смещение 0h
		add di,0Ch
		xor ah,ah
		mov al,es:[0]
		call WRD_TO_HEX
		mov al,20h
		mov [di],al
		inc di
		mov [di],al
		mov di,offset result
		;смещение 1h
		mov ax,es:[1]
		add di,19h
		call WRD_TO_HEX
		mov di,offset result
		;смещение 3h
		mov ax,es:[3]
		mov bx,10h
		mul bx
		add di,29h
		push si
		mov si,di
		call WRD_TO_DEC
		pop si
		mov di,offset result
		add di,31h
  	mov bx,0h
PRINTS:
    mov dl,es:[8+bx]
		mov [di],dl
		inc di
		inc bx
		cmp bx,8h
		jne PRINTS
		mov ax,es:[3]
		mov bl,es:[0]
		ret
GET_MCB ENDP

BEGIN:
;Доступная память
		mov ah, 4ah
		mov bx, 0ffffh
		int 21h
		mov ax,10h
		mul bx
		mov si,offset _avl_mem
		add si,27
		call WRD_TO_DEC
		mov dx, offset _avl_mem
		call PRINT

		mov ah,4ah
		mov bx,offset sizepr
		int 21h

		mov ah,48h
		mov bx,1000h
		int 21h

;Расширенная память
		xor dx,dx
		mov al,30h
    out 70h,al
    in al,71h
  	mov bl,AL
    mov al,31h
    out 70h,al
    in al,71h
		mov ah,al
    mov al,bl
		mov si,offset _ext_mem
		add si,29
		mov  AL, 30h
		out  70h, AL
		in   AL, 71h
		mov  BL, AL
		mov  AL, 31h
		out  70h, AL
		in   AL, 71h
		call WRD_TO_DEC
		mov dx,offset _ext_mem
		call PRINT


;MCB
    mov dx,offset _table_MCB
		call PRINT
		mov ah,52h
		int 21h
		sub bx,2h
		mov es,es:[bx]
MCB_OUT:
		xor ax,ax
		xor bx,bx
		xor cx,cx
		xor dx,dx
		xor di,di

		call GET_MCB
		mov dx,offset result
		call PRINT
		mov cx,es
		add ax,cx
		inc ax
		mov es,ax
		cmp bl,4Dh
		je MCB_OUT

    mov ah,4ch
		int 21h
sizepr db 0
TESTPC ENDS
	END START
