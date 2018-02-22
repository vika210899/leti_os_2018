.386
; ДАННЫЕ
DATA SEGMENT
	STRINACCESSMEMADDRINFO db 'Addres of a segment with first byte of inaccesible memory: $'
	STRINACCESSMEMADDR db '    $'
	STRENVADDRINFO db 'Address of an environment segment: $'
	STRENVADDR db '    $'
	STRTAILPRNTINFO db 'Tail:$'
	STRTAIL db 50h DUP(' '),'$'
	STRNOTAIL db 'There is no tail$'
	STRENVCONTENTINFO db 'Environment contents:',0DH,0AH,'$'
	STRPRGRMPATHINFO db 'App path:',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS

TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:DATA, ES:NOTHING, SS:NOTHING
; ПРОЦЕДУРЫ
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	mov AH,09h
	int 21h
	ret
PRINT ENDP
	
;---------------------------------------
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
;---------------------------------------
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
;---------------------------------------
; перевод в 10с/с, SI - адрес поля младшей цифры
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
;---------------------------------------
; Чтение 3,4 байтов PSP(сегментного адреса первого байта недоступной памяти) и их вывод в консоль
GET_INACCESS_MEM_ADDR PROC near
	push es
	mov ax,es:[2]
	mov es,ax
	mov di,offset STRINACCESSMEMADDR+3
	call WRD_TO_HEX
	mov dx,offset STRINACCESSMEMADDRINFO
	call PRINT
	mov dx,offset STRINACCESSMEMADDR
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	;mov ax,01000h 
	;mov es:[0h],ax ; works in dos
	pop es
	ret
GET_INACCESS_MEM_ADDR ENDP
;---------------------------------------
; Чтение из PSP сегментного адреса среды, передаваемой программе и его вывод в консоль
GET_ENV_ADDR PROC near
	mov ax,es:[2Ch]
	mov di,offset STRENVADDR+3
	call WRD_TO_HEX
	mov dx,offset STRENVADDRINFO
	call PRINT
	mov dx,offset STRENVADDR
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	ret
GET_ENV_ADDR ENDP
;---------------------------------------
PRINT_TAIL PROC near
	xor ch,ch
	mov cl,es:[80h]
	
	cmp cl,0
	jne notnil
		mov dx,offset STRNOTAIL
		call PRINT
		mov dx,offset STRENDL
		call PRINT
		ret
	notnil:
	
	mov dx,offset STRTAILPRNTINFO
	call PRINT
	
	mov ah,02h
	mov di,81h
	cycle:
		mov dl,es:[di]
		int 21h
		inc di
	loop cycle
	
	ret
PRINT_TAIL ENDP
;---------------------------------------
; Печатает содержимое области среды
PRINT_ENV PROC near
	mov dx, offset STRENDL
	call PRINT
	mov dx, offset STRENVCONTENTINFO
	call PRINT
	push es
	mov ax,es:[2ch]
	mov es,ax
	
	xor bp,bp
	PE_cycle1:
		cmp word ptr es:[bp],0001h
		je PE_exit1
		cmp byte ptr es:[bp],00h
		jne PE_noendl
			mov dx,offset STRENDL
			call PRINT
			inc bp
		PE_noendl:
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle1
	PE_exit1:
	add bp,2
	
	mov dx, offset STRENDL
	call PRINT
	mov dx, offset STRPRGRMPATHINFO
	call PRINT
	
	PE_cycle2:
		cmp byte ptr es:[bp],00h
		je PE_exit2
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle2
	PE_exit2:
	pop es
	ret
PRINT_ENV ENDP
;---------------------------------------
_BEGIN:
	mov ax,DATA
	mov ds,ax
	call GET_INACCESS_MEM_ADDR
	call GET_ENV_ADDR
	call PRINT_TAIL
	call PRINT_ENV
	; xor AL,AL
	mov dx,offset STRENDL
	call PRINT
	mov ah,01h
	int 21h
	;mov dl,al
	;mov ah,02h
	;int 21h
	call PRINT
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END _BEGIN