
PCinfo	segment
		assume cs:PCinfo, ds:PCinfo, es:nothing, ss:nothing
	org 	100h
	
start:		
	jmp		begin

	;data
	available_mem 	db 'Amount of available memory:            b$'
	extenden_mem 	db 'Size of extended memory:            Kb$'
	mcb 			db 'List of memory control blocks:$'
	type_MCB		db 'MCB type: 00h$'
	adress_PSP		db 'PSP adress: 0000h$'
	size_s 			db 'Size:          b$'
    endl			db  13, 10, '$'
    tab				db 	9,'$'

tetr_to_hex proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
   tetr_to_hex endp

;Байт в al переводится в два символа 16-ричного числа в ax
byte_to_hex proc near
    push 	cx
    mov 	ah, al
    call 	tetr_to_hex
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	tetr_to_hex ;В al старшая цифра, в ah младшая
    pop 	cx
    ret
   byte_to_hex endp

;Перевод в 16 сс 16-ти разрядного числа
;ax - число, di - адрес последнего символа
wrd_to_hex proc near
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

;Перевод в 10 сс, si - адрес поля младшей цифры
byte_to_dec proc near
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
   
wrd_to_dec proc near
    push 	cx
    push 	dx
    mov  	cx, 10
wloop_bd:   
    div 	cx
    or  	dl, 30h
    mov 	[si], dl
    dec 	si
	xor 	dx, dx
    cmp 	ax, 10
    jae 	wloop_bd
    cmp 	al, 00h
    je 		wend_l
    or 		al, 30h
    mov 	[si], al
wend_l:      
    pop 	dx
    pop 	cx
    ret
   wrd_to_dec endp
 


begin:

;Количество доступной памяти        
	mov 	ah, 4Ah
	mov 	bx, 0ffffh
	int 	21h
    
	xor	dx, dx
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx
	
	mov  	si, offset available_mem+37
	call 	wrd_to_dec
    
	mov 	dx, offset available_mem
	mov 	ah, 09h
    int 	21h
	mov	dx, offset endl
	mov 	ah, 09h
    int 	21h
	
;Размер расширенной памяти    
	mov	al, 30h
	out	70h, al
	in	al, 71h
	mov	bl, al ;младший байт в al
	mov	al, 31h
	out	70h, al
	in	al, 71h ;старший байт в al
	mov	ah, al
	mov	al, bl

	mov	si, offset extenden_mem+34
	xor 	dx, dx
	call 	wrd_to_dec
	
	mov	dx, offset extenden_mem
	mov 	ah, 09h
    int 	21h
	mov	dx, offset endl
	mov 	ah, 09h
    int 	21h

;Цепочка блоков управления памятью    
    mov		dx, offset mcb
    mov 	ah, 09h
    int 	21h
	mov		dx, offset endl
	mov 	ah, 09h
    int 	21h
    
    mov		ah, 52h
    int 	21h
    mov 	ax, es:[bx-2]
    mov 	es, ax
	
    ;тип MCB
tag1:
	mov 	al, es:[0000h]
    call 	byte_to_hex
    mov		di, offset type_MCB+10
    mov 	[di], ax
      
    mov		dx, offset type_MCB
    mov 	ah, 09h
    int 	21h
    mov		dx, offset tab
    mov 	ah, 09h
    int 	21h
     
    ;сегментный адрес PSP владельца участка памяти    
    mov 	ax, es:[0001h]
    mov 	di, offset adress_PSP+15
    call 	wrd_to_hex
    
    mov		dx, offset adress_PSP
    mov 	ah, 09h
    int 	21h
    mov		dx, offset tab
    mov 	ah, 09h
    int 	21h
    
    ;размер участка в параграфах
    mov 	ax, es:[0003h]
    mov 	cx, 10h 
    mul 	cx
	
	mov		si, offset size_s+13
    call 	wrd_to_dec
    mov		dx, offset size_s
    mov 	ah, 09h
    int 	21h 
    mov		dx, offset tab
    mov 	ah, 09h
    int 	21h
	
    ;последние 8 байт
    push 	ds
    push 	es
    pop 	ds
    
    mov 	dx, 08h
    mov 	di, dx
    mov 	cx, 8
tag2:
	cmp		cx,0
	je		tag3
    mov		dl, byte PTR [di]
    mov		ah, 02h
	int		21h
    dec 	cx
    inc		di
    jmp		tag2
tag3:    
	pop 	ds
	mov		dx, offset endl
    mov 	ah, 09h
    int 	21h
    
;проверка, последний блок или нет
    cmp 	byte ptr es:[0000h], 5ah
    je 		quit
   
;адрес следующего блока
    mov 	ax, es
    add 	ax, es:[0003h]
    inc 	ax
    mov 	es, ax
    jmp 	tag1
         
quit:          
  
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h
PCinfo	ENDS
		END    START
