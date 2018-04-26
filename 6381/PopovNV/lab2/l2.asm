TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	JMP BEGIN
	SegAdrUntouchMem DB 'Segment address of untouchable memory -     ',10,13,'$'
	SegAdrEnvir DB 'Segment address of environment -     ',10,13,'$'
	TailComStr DB 'Tail of command string - $'
	EndStr DB 10,13,'$'
	ContEnvAr DB 'Contents of the environment area - $'
	WayMod DB 'Way of module - $'
	;--------------------------------------------------
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
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в AX
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
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;AX - число, DI - адрес последего символа
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
PRINT_STR PROC near ;Печать строки, помещенной в DX
	mov ah,09h
	int 21h
	ret
PRINT_STR ENDP
;--------------------------------------------------
CHECK_ASUM PROC near
	mov ax,ds:[02h]
	mov di,offset SegAdrUntouchMem+43
	call WRD_TO_HEX
	mov dx,offset SegAdrUntouchMem
	call PRINT_STR
	ret
CHECK_ASUM ENDP
;--------------------------------------------------
CHECK_SAE PROC near
	mov ax,ds:[02ch]
	mov di,offset SegAdrEnvir+36
	call WRD_TO_HEX
	mov dx,offset SegAdrEnvir
	call PRINT_STR
	ret
CHECK_SAE ENDP
;--------------------------------------------------
CHECK_TCS PROC near
	mov dx,offset TailComStr
	call PRINT_STR
	mov cl,ds:[080h]
	cmp cl,0
	je empty
	mov ah,02h
	xor di,di
newSymb:
	mov dl,ds:[081h + di]
	int 21h
	inc di
	loop newSymb
empty:
	mov dx,offset EndStr
	call PRINT_STR	
	ret
CHECK_TCS ENDP
;--------------------------------------------------
CHECK_CEA_WM PROC near
	lea	dx,ContEnvAr 
	call PRINT_STR
	mov	bx,1 ;checker
	mov	es,es:[2ch] 
	mov	si,0
nextEl:
	lea	dx,EndStr
	call PRINT_STR
	mov	ax,si 

endNotFound:
	cmp byte ptr es:[si], 0
	je endElemArea 
	inc	si
	jmp endNotFound 
endElemArea:
	push es:[si]
	mov	byte ptr es:[si], '$' 
	push ds 
	mov	cx,es 
	mov	ds,cx 
	mov	dx,ax 
	call PRINT_STR
	pop	ds 
	pop	es:[si] 
	cmp	bx,0 
	je final
	inc si
	cmp byte ptr es:[si], 01h 
	jne nextEl 
	lea	dx,WayMod
	call PRINT_STR
	mov	bx,0
	add si,2 
	jmp nextEl
final:
	ret
CHECK_CEA_WM ENDP
;--------------------------------------------------
BEGIN:
	call CHECK_ASUM
	call CHECK_SAE
	call CHECK_TCS
	call CHECK_CEA_WM
	
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
	END START