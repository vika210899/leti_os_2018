
  TESTPC segment
	assume cs:TESTPC, ds:TESTPC, es:nothing, ss:nothing
	org 	100h

start:
    jmp 	begin

    ;data
    type_PC			db 'PC type: $'
    Unknown			db 'Unknown type: 00$'
    PC 				db 'PC$'
    PC_XT 			db 'PC/XT$'
    AT 				db 'AT$'
    PS2_1 			db 'PS2 model 30$'
    PS2_2 			db 'PS2 model 50 or 60$'
    PS2_3 			db 'PS2 model 80$'
    PCjr 			db 'PCjr$'
    PC_Convertible	db 'PC Convertible$'
    DOS				db 'Version MS DOS: 00.00$'
    OEM 			db 'Serial number OEM: 00$'
    User_Numb		db 'User number: 000000$'
    endl 			db 13, 10, '$'
;---------------------------------------------------------
   tetr_to_hex proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
   tetr_to_hex endp

  ; ------------------------------------------------------
   byte_to_hex proc near
   ;байт в AL переводится в два символа шестн. числа в AX
    push 	cx
    mov 	ah, al
    call 	tetr_to_hex
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	tetr_to_hex ;ч al УФБТЫБС ГЙЖТБ, Ч ah НМБДЫБС
    pop 	cx
    ret
   byte_to_hex endp
  ; ----------------------------------------------------
   wrd_to_hex proc near
   ;перевод в 16 с/с 16-ти разрядного числа
   ;в AX - число, DI - адрес последнего символа
    push 	bx
    mov 	bh, ah
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    dec 	di
    mov 	al, bh
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    pop 	bx
    ret
   wrd_to_hex endp

;---------------------------------------------------------   
   byte_to_dec proc near
   ;перевод в 10 с/с, SI - адрес поля младшей цифры
    push 	cx
    push 	dx
    xor 	ah, ah
    xor 	dx, dx
    mov 	cx, 10
loop_bd:
    div 	cx
    or 		dl, 30h
    mov 	[si], dl
    dec 	si
    xor 	dx, dx
    cmp 	ax, 10
    jae 	loop_bd
    cmp 	al, 00h
    je 		end_l
    or 		al, 30h
    mov 	[si], al
end_l:
    pop 	dx
    pop 	cx
    ret
   byte_to_dec endp

begin:

;PC type
    mov 	dx,offset type_PC	
    mov 	ah, 09h
    int 	21h
    
    push 	ds
    mov 	ax, 0F00h
    mov 	ds, ax
    mov 	al, [0FFFEh]
    pop 	ds
    
    cmp 	al, 0FFh
	jne 	type1
    mov		dx,offset PC
    mov		ah, 09h
	int		21h
    jmp 	type_end

type1:
    cmp 	al, 0FEh
    jne 	type2
    mov		dx,offset PC_XT 
    mov		ah, 09h
	int		21h
    jmp 	type_end

type2:
    cmp 	al, 0FBh
    jne 	type3
    mov		dx,offset PC_XT 
    mov		ah, 09h
	int		21h
    jmp 	type_end

type3:
    cmp 	al, 0FCh
    jne 	type4
    mov		dx,offset AT
    mov		ah, 09h
	int		21h
    jmp 	type_end

type4:
    cmp 	al, 0FAh
    jne 	type5
    mov		dx,offset PS2_1  
    mov		ah, 09h
	int		21h
    jmp 	type_end

type5:
    cmp 	al, 0FCh
    jne 	type6
    mov		dx,offset PS2_2
    mov		ah, 09h
	int		21h
    jmp 	type_end

type6:
    cmp 	al, 0F8h
    jne 	type7
    mov		dx,offset PS2_3
    mov		ah, 09h
	int		21h
    jmp 	type_end

type7:
    cmp 	al, 0FDh
    jne 	type8
    mov		dx,offset PCjr
    mov		ah, 09h
	int		21h
    jmp 	type_end

type8:
    cmp 	al, 0F9h
    jne 	type_unknown
    mov		dx,offset PC_Convertible
    mov		ah, 09h
	int		21h
    jmp 	type_end

type_unknown:
	call	byte_to_hex
	mov		di,offset Unknown+14
	mov		[di],ax
	mov		dx,offset Unknown
	mov		ah, 09h
	int		21h

type_end:
    mov	dx, offset endl
    mov		ah, 09h
	int		21h
    
;DOS
    
    mov 	ah, 30h
    int 	21h
    
    mov 	si,offset DOS+17
    call 	byte_to_dec
    mov 	al, ah
    mov 	si,offset DOS+20
    call 	byte_to_dec
    
    mov 	dx,offset DOS
    mov 	ah, 09h
    int 	21h
    
    mov 	dx,offset endl
    mov 	ah, 09h
    int 	21h
    
;OEM    
    
    mov 	al, bh
    call 	byte_to_hex
    mov 	di,offset OEM+19
    mov 	[di], ax
    
    mov 	dx, offset OEM
    mov 	ah, 09h
    int 	21h
    
    mov 	dx, offset endl
    mov 	ah, 09h
    int 	21h
    
;User number
    
    mov 	al, bl
    call 	byte_to_hex
    mov 	di, offset User_Numb+21
    mov 	[di], ax   
    
    mov 	ax, cx
    mov 	di, offset User_Numb+25
    call 	wrd_to_hex
    
    mov 	dx, offset User_Numb
    mov 	ah, 09h
    int 	21h
   
  
    
;quit   
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h
  TESTPC ends
    end start
