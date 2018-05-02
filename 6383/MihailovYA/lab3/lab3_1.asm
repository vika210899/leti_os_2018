com_segment     SEGMENT
           ASSUME  CS:com_segment, DS:com_segment, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN
;данные
string_key db 13,10,"Press any key...$"
string_l db 13, 10, "Name: $"
string_0 db 13, 10, "MCB #0   $"
string_1 db "Empty area $"
string_2 db "Area belongs to OS XMS UMB driver $"
string_3 db "Area of excluded upper driver memory $"
string_4 db "Area belongs to MS DOS $"
string_5 db "Area occuped by control block 386MAX UMB $"
string_6 db "Area blocked 386MAX $"
string_7 db "Area belongs 386MAX UMB$"
string_8 db 13, 10, "Size: $"
string_9 db 13, 10, "     $"
string_10 db 13,10,"MCB chain: $"
string_11 db 13, 10, "Owner:                $"
string_12 db 13, 10, "Addr:           $"
string_13 db 13,10,"Size of available memory: $"
string_14 db 13,10,"  №        ADDR        OWNER           SIZE                NAME    ",13,10,"$"
string_15 db 13,10,"Size of extended memory: $"
string_16 db 13, 10, "Owner: $"
string_Byte db " byte $"
string_Empty db 13,10,"Empty$"
string_Separator db 13,10,"========================================$"
string_enter db 13,10,"$"

;процедуры

PrintSize PROC
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
PrintSize ENDP
;-------------Clear scr+press key-----------------
Clrscr PROC
	push ax
	lea dx,string_key
	call writestring
	mov ah,01h
	int 21h
	mov ax,3 
	int 10h
	pop ax
	ret
Clrscr EndP
;-----------------Foreach mcb--------------------
Mem_Info PROC
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h

	mov bh,al
	mov ax,bx
	lea dx,string_15
    call writestring
	call PrintSize
	lea dx,string_Byte
    call writestring
	;lea dx,string_14
	;call writestring
	mov ah,52h
	int 21h
	mov ax,es:[bx-2]
	mov es,ax
	xor cx,cx
	inc cx

	feMCB:
	lea dx, string_enter
	call writestring
	lea si, string_0
	add si, 8
	mov al,cl
	push cx
	call byte_to_dec
	lea dx, string_0
	call writestring
	
	mov ax,es
	lea di,string_12
	add di,12
	call wrd_to_hex
	lea dx,string_12
	call writestring
	
	xor ah,ah
	mov al,es:[0]
	push ax
	mov ax,es:[1]
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
	lea di,string_11
	add di, 12
	call wrd_to_hex
	lea dx,string_11
	call writestring
	jmp go
	g1:
	lea dx, string_16
	call writestring
	lea dx,string_1
	call writestring
	jmp go
	g2:
	lea dx, string_16
	call writestring
	lea dx,string_2
	call writestring
	jmp go
	g3:
	lea dx, string_16
	call writestring
	lea dx,string_3
	call writestring
	jmp go
	g4:
	lea dx, string_16
	call writestring
	lea dx,string_4
	call writestring
	jmp go
	g5:
	lea dx, string_16
	call writestring
	lea dx,string_5
	call writestring
	jmp go
	g6:
	lea dx, string_16
	call writestring
	lea dx,string_6
	call writestring
	jmp go
	g7:
	lea dx, string_16
	call writestring
	lea dx,string_7
	call writestring
	go:
	mov ax,es:[3]	
	lea dx,string_8
	call writestring
	call PrintSize
	lea dx,string_Byte
	call writestring
	lea dx , string_l 
	call writestring
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
	jne err
	lea dx,string_enter
	call writestring
	jmp feMCB
	
	err:
	exit:
	call Clrscr
	ret
Mem_Info ENDP

Writestring   PROC
        push ax
        mov ah,09h
        int 21h
        pop ax
        ret
Writestring   ENDP

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
           call     TETR_TO_HEX ;т AL ёЄрЁ°р  ЎшЇЁр
           pop      CX          ;т AH ьырф°р 
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
BEGIN:
              mov ah,4Ah
		  mov bx,0FFFFh
	        int 21h

		  mov ax,bx
		  lea dx,string_13
		  call writestring
		  call PrintSize
		  
		  lea dx,string_Byte
		  call writestring
		  call Mem_Info

; выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
com_segment    ENDS
           END     START