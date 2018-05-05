PROG SEGMENT
		ASSUME CS:PROG, DS:PROG, ES:NOTHING, SS:NOTHING
		ORG 100H
START:
		jmp main
;Данные
		avail_mem db 13,10,"Size of available memory: $"
		exten_mem db 13,10,"Size of extended memory: $"
		str_MCB db "MCB #0   Addr:       Owner: $"
		str_size db 13, 10, "Size: $"
		str_own_name db "  Name: $"
		str_own_1 db "Empty area$"
		str_own_2 db "Area belongs to OS XMS UMB driver $"
		str_own_3 db "Area of excluded upper driver memory $"
		str_own_4 db "Area belongs to MS DOS $"
		str_own_5 db "Area occuped by control block 386MAX UMB $"
		str_own_6 db "Area blocked 386MAX $"
		str_own_7 db "Area belongs 386MAX UMB$"
		str_owner db "    $"
		str_Byte db " byte$"
		str_enter db 13,10,"$"
		fr_mem db "Freeing memory: $"
		al_mem db "Allocating memory: $"
		er7 db "Failed. Memory management blocks destroyed",13,10,"$"
		er8 db "Failed. Not enough memory",13,10,"$"
		er9 db "Failed. ES contains invalid address",13,10,"$"
		er_unk db "Failed. Unknown error",13,10,"$"
		success db "Success",13,10,"$"
;---------------------Procedures-------------------
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
BYTE_TO_HEX PROC near;байт в AL переводится в два символа шестн. числа в AX
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX ; в AL старшая цифра
		pop CX           ; в AH младшая
		ret
BYTE_TO_HEX ENDP
;--------------------------------------------------
WRD_TO_HEX PROC near  ;перевод в 16 с/с 16-ти разрядного числа
		push BX       ;AX - число, DI - адрес последего символа
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
BYTE_TO_DEC PROC near ; перевод в 10с/с, SI - адрес поля младшей цифры
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
;--------------------------------------------------
PRINT_STR PROC near ;Печать строки, помещенной в DX
		push ax
		mov ah,09h
		int 21h
		pop ax
		ret
PRINT_STR ENDP
;--------------------------------------------------
PRINT_SIZE PROC near
		mov bx,10h
		mul bx
		mov bx,0ah
		xor cx,cx
	del:
		div bx
		push dx
		inc cx
		xor dx,dx
		cmp ax,0
		jnz del
	writeSymb:
		pop dx
		or dl,30h
		mov ah,02h
		int 21h
		loop writeSymb
		ret
PRINT_SIZE ENDP
;--------------------------------------------------
AMOUNT_OF_AVAILABLE_MEMORY PROC NEAR
		mov ah,4Ah
		mov bx,0FFFFh
		int 21h
		mov ax,bx
		lea dx,avail_mem
		call PRINT_STR
		call PRINT_SIZE
		lea dx,str_Byte
		call PRINT_STR
		ret
AMOUNT_OF_AVAILABLE_MEMORY ENDP
;--------------------------------------------------
EXTENDED_MEMORY_SIZE PROC NEAR
		mov al,30h
		out 70h,al
		in al,71h
		mov bl,al
		mov al,31h
		out 70h,al
		in al,71h
		mov bh,al
		mov ax,bx
		lea dx,exten_mem
		call PRINT_STR
		call PRINT_SIZE
		lea dx,str_Byte
		call PRINT_STR
		ret
EXTENDED_MEMORY_SIZE ENDP
;--------------------------------------------------
CHAIN_OF_MEMORY_CONTROL_BLOCKS PROC NEAR
		mov ah,52h
		int 21h
		mov ax,es:[bx-2]
		mov es,ax
		xor cx,cx
		inc cx
		lea dx, str_enter
		call PRINT_STR
		
	nextMCB:
		lea si, str_MCB
		add si, 6
		mov al,cl
		push cx
		call BYTE_TO_DEC
		
		mov ax,es
		lea di,str_MCB
		add di,18
		call WRD_TO_HEX
		
		xor ah,ah
		mov al,es:[0]
		push ax
		mov ax,es:[1]
		lea dx,str_MCB
		call PRINT_STR
		cmp ax,0000h
		je g1
		cmp ax,0006h
		je g2
		cmp ax,0007h
		je g3
		cmp ax,0008h
		je g4
		cmp ax,0FFFAh
		je g5
		cmp ax,0FFFDh
		je g6
		cmp ax,0FFFEh
		je g7
		lea di,str_owner
		add di, 3
		call WRD_TO_HEX
		lea dx,str_owner
		call PRINT_STR
		jmp go
	g1:
		lea dx,str_own_1
		call PRINT_STR
		jmp go
	g2:
		lea dx,str_own_2
		call PRINT_STR
		jmp go
	g3:
		lea dx,str_own_3
		call PRINT_STR
		jmp go
	g4:
		lea dx,str_own_4
		call PRINT_STR
		jmp go
	g5:
		lea dx,str_own_5
		call PRINT_STR
		jmp go
	g6:
		lea dx,str_own_6
		call PRINT_STR
		jmp go
	g7:
		lea dx,str_own_7
		call PRINT_STR
	go:
		mov ax,es:[3]	
		lea dx,str_size
		call PRINT_STR
		call PRINT_SIZE
		lea dx,str_Byte
		call PRINT_STR
		lea dx,str_own_name
		call PRINT_STR
		mov cx,8
		xor di,di
	write:
		mov dl,es:[di+8]
		mov ah,02h
		int 21h
		inc di
	loop write	
		mov ax,es:[3]	
		mov bx,es
		add bx,ax
		inc bx
		mov es,bx
		pop ax
		pop cx
		inc cx
		cmp al,5ah
		je exit
		cmp al,4dh 
		jne exit
		lea dx,str_enter
		call PRINT_STR
		jmp nextMCB
		
	exit:
		ret
CHAIN_OF_MEMORY_CONTROL_BLOCKS ENDP
;--------------------------------------------------
FREE_MEM PROC NEAR
		lea dx,fr_mem
		call PRINT_STR
		lea BX, newstk
		mov CL,04h
		add BX,10Fh
		shr BX, CL
		mov AH,4Ah
		int 21h
		call TEST_ERROR
		ret
FREE_MEM ENDP
;--------------------------------------------------
MEMORY_ALLOCATION PROC NEAR
		lea dx,al_mem
		call PRINT_STR
		mov ah,48h
		mov bx,1000h
		int 21h
		call TEST_ERROR
		ret
MEMORY_ALLOCATION ENDP
;--------------------------------------------------
TEST_ERROR PROC NEAR
		jnc ok
		
		cmp ax,07h
		lea dx,er7
		call PRINT_STR
		jmp ex
		
		cmp ax,08h
		lea dx,er8
		call PRINT_STR
		jmp ex
		
		cmp ax,09h
		lea dx,er9
		call PRINT_STR
		jmp ex
		
		lea dx,er_unk
		call PRINT_STR
		jmp ex
	ok:
		lea dx,success
		call PRINT_STR
	ex:
		ret
TEST_ERROR ENDP
;------------------------CODE----------------------
	main:
		; call FREE_MEM
		; call MEMORY_ALLOCATION
		call AMOUNT_OF_AVAILABLE_MEMORY
		call EXTENDED_MEMORY_SIZE
		call CHAIN_OF_MEMORY_CONTROL_BLOCKS
	
		xor AL,AL
		mov AH,4Ch
		int 21H
		
		dw 64 dup(?)
		newstk=$
PROG ENDS
END START