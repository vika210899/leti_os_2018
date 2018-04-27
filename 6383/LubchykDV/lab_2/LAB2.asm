;Nemtyreva Anastasiya
;Group 5381
psp segment
		assume cs:psp, ds: psp, es:nothing, ss:nothing
		org 100h
start: jmp begin

NotAccessedMemory db 'Memory:                  ',  13, 10, '$'
SegmentAddres db 'Addres:                  ',  13, 10, '$'
CommandTail db 'Command line param:', '$'
Envarianment db 'ENV:                  ',  13, 10, '$'
NextLine db 13, 10, '$'
Path db 'Path: ', '$'
ErrorZB db 'Not 1h byte for find load path',  13, 10, '$'

CommadsVar db 256 dup(0) 
EnvVar db ?
LoadPath db ?

push_main macro
	push ax
	push bx
	push cx
	push dx
endm

pop_main macro
	pop dx
	pop cx
	pop bx
	pop ax
endm

print  proc  near
          mov   ah,09h
          int   21h 
          ret
print  endp

TETR_TO_HEX PROC near
	and AL,0Fh 
	cmp AL,09 
	jbe NEXT 
	add AL,07 
NEXT: 
	add AL,30h 
	ret 
TETR_TO_HEX ENDP 
;------------------------------- 

BYTE_TO_HEX PROC near 
;Byte in AL converted to two HEX symbols in AX
	push CX 
	mov AH,AL 
	call TETR_TO_HEX 
	xchg AL,AH 
	mov CL,4 
	shr AL,CL 
	call TETR_TO_HEX ; in AL high order digit
	pop CX ;in AH low
	ret 
BYTE_TO_HEX ENDP 
;------------------------------- 

WRD_TO_HEX PROC near 
;convert to HEx 16 bits num
; ax -num, di - last symbol address
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
; convert to dec, SI - low order digit
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


not_acc_memory  proc  near
	push_main
	push si
	push di
	mov si, 2
	mov ax, word ptr [cs:si]
	mov bx, offset NotAccessedMemory
	add bx, 7
	add bx, 4
	mov	di, bx
	call WRD_TO_HEX
	mov dx, offset NotAccessedMemory
	call print
	pop di
	pop si
	pop_main
	ret
not_acc_memory endp

segment_addres  proc  near
	push_main
	push si
	push di
	mov si, 2Ch
	mov ax, word ptr [cs:si]
	mov bx, offset SegmentAddres
	add bx, 7
	add bx, 4
	mov	di, bx
	call WRD_TO_HEX
	mov dx, offset SegmentAddres
	call print
	pop di
	pop si
	pop_main
	ret
segment_addres endp

set_to_comm_tail macro reg, set
	mov [reg+19], set
endm

command_tail  proc  near
	push_main
	push si
	push di
	mov si, 80h
	xor cx, cx
	mov cl, byte ptr [cs:si]
	mov bx, offset CommadsVar
	; add bx, 013h
	inc si
loop_start:
	cmp cl, 0h
	jz loop_end
	xor ax, ax
	mov al, byte ptr [cs:si]
	mov [bx], al
	add bx, 1
	sub cl, 1
	add si, 1
	jmp loop_start
loop_end:
	xor ax, ax
	mov al, 0Ah
	mov [bx], al
	inc bx
	mov al, '$'
	mov [bx], al
	mov dx, offset CommandTail
	call print
	mov dx, offset CommadsVar
	call print
	pop di
	pop si
	pop_main
	ret
command_tail endp

env_var proc near
	mov si, 2Ch
	mov ds, [es:si]
	xor si,si
loop_start_env: 
	cmp word ptr [si], 0
	je loop_end_env
	lodsb
	cmp al, 0h
	jnz next_env
	mov ax,0Dh
	int 29h
	mov ax,0Ah
next_env:
	int     29h
	jmp     loop_start_env
loop_end_env:
	inc si
	inc si
	lodsb
	cmp al, 1h
	jnz not_found1h_env
	inc si
	push ds
	mov cx, es
	mov ds, cx
	mov dx, offset NextLine
	call print
	mov dx, offset Path
	call print
	pop ds
loop2_start_env:
	lodsb 
	cmp al, 0h
	jz end_all_env
	int 29h
	jmp loop2_start_env
not_found1h_env:
	mov dx, offset ErrorZB
	call print
end_all_env:
	ret
env_var endp

begin:
	call not_acc_memory
	call segment_addres
	call command_tail
	call env_var
	xor al, al
	mov ah, 4Ch
	int 21h
psp ends
		end start
