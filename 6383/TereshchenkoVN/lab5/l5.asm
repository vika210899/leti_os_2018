.Model small
.DATA
PSP dw ?
isUd db ?
isloaded db ?
sg dw ?
num db 0
KEEP_CS DW ? 
KEEP_IP DW ?
strld db 13, 10, "Resident has been loaded$", 13, 10
struld db 13, 10, "Resident has been unloaded$"
strald db 13, 10, "Resident has been already loaded$"
.STACK 400h
.CODE
resID dw 0ff00h
;-----------------------------------
changing PROC FAR
	mov cs:[key], 0
	in al, 60h
	cmp al, 10h   
	jl interput
	cmp al, 35h
	jle cond_1
	inc cs:[key] 
	cmp al, 49 
	je cond
	inc cs:[key]    
	cmp al, 14 
	je cond
	cond_1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b
		pop ax
		jnz cond
	interput:
		jmp dword ptr cs:[Int9_vect];
	cond: 
		push ax
		in al, 61h   
		mov ah, al   
		or al, 80h   
		out 61h, al  
		xchg ah, al  
		out 61h, al  
		mov al, 20h  
		out 20h, al  
	l16h:
		pop ax
		mov ah, 05h  
		cmp cs:[key], 0
		je key1
		cmp cs:[key], 1
		je key2
		cmp cs:[key], 2
		je key3
	key1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b
		jnz change
		pop ax
		jmp dword ptr cs:[Int9_vect];
	change:
		pop ax
		mov cl, 0B0h
		add cl, al
		sub cl, 0Fh 
		jmp writeKey
	key2:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 01000011b 
		jnz big
		pop ax
		mov cl, 'n'
		jmp writeKey
	big:
		pop ax
		mov cl, 'N'
		jmp writeKey
	key3:
		mov cl, 'D'
		jmp notcls 
	writeKey:
		mov ch,00h  
		int 16h 
		or al, al 
		jnz buffer
		jmp notcls
		
	buffer: 
		push es
		CLI	
		xor ax, ax
		MOV es, ax	
		MOV al, es:[41AH]	
		MOV es:[41CH], al 	
		STI	
		pop es
	notcls:
		IRET		
		Int9_vect dd ?		
		key db 0 
changing  ENDP  
;-----------------------------------
debark PROC
	push es
	push ax
	mov ax, psp
	mov es, ax
	mov cl, es:[80h]
	mov dl, cl
	xor ch, ch
	test cl, cl	
	jz ex2
	xor di, di
	readChar:
		inc di
		mov al, es:[81h+di]
		inc di
		cmp al, '/'
		jne ex2
		mov al, es:[81h+di]
		inc di
		cmp al, 'u'
		jne ex2
		mov al, es:[81h+di]
		cmp al, 'n'
		jne ex2
		mov isUd, 1 
	ex2:
		pop ax
		pop es
		ret
debark ENDP
;-----------------------------------
AlreadyLoad PROC
	push es
	mov ax, 3509h
	int 21h
	mov dx, es:[bx-2]
	pop es
	cmp dx, resId
	je ad
	jmp exd
	ad:
		mov isloaded, 1
	exd:
		ret
AlreadyLoad ENDP
;-----------------------------------
UnLoad proc
	push    DS              
        mov     AX, ES:[KEEP_CS]    
        mov     DS, AX         
        mov     DX, ES:[KEEP_IP]    
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h            
        pop     DS
        sti                    
        mov     AX, KEEP_CS    
        sub     AX, PSP
        mov     ES, AX         
        mov     BX, ES:[2Ch]   
        mov     AH, 49h        
        int     21h
        mov     ES, BX
        mov     AH, 49h       
        int     21h
Unload endp
;-----------------------------------
Resident proc
	lea dx, strld
	call WRITE
	lea dx, temp
	sub dx, psp
	mov cl, 4
	shr dx, cl
	mov Ax, 3100h
	int 21h
	ret
Resident Endp
;-----------------------------------
WRITE PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-----------------------------------
Main PROC  FAR 
	mov ax, ds
	mov ax, @DATA		  
	mov ds, ax
	mov ax, es
	mov psp, ax

	call AlreadyLoad
	
	call debark

	cmp isloaded, 1
	je a
	mov ax, 3509h 
	int 21h
	mov KEEP_IP, bx 
	mov KEEP_CS, es  
	mov word ptr int9_vect+2, es
	mov word ptr int9_vect, bx

	push ds
	mov dx, OFFSET changing 
	mov ax, SEG changing    
	mov ds, ax          
	mov ax, 2509h        
	int 21H            
	pop ds
	call Resident
	a:   
		 push     ES	
  	         mov      CX, 238Bh
	         mov      ES, CX
	         mov      AH, 49h
	         int         21h
	         pop       ES
         	 mov     CX, 2356h
	         mov     ES, CX
	         int         21h
		cmp isud, 1
		jne b
		call unload
		lea dx, struld
		call WRITE
		mov ah, 4ch                        
		int 21h   
	b:

		push     ES	
		mov      CX, 238Bh
		mov      ES, CX
		mov      AH, 49h
		int         21h
		pop       ES
	
		mov     CX, 2356h
		mov     ES, CX
		int         21h
		lea dx, strald
		call WRITE
		mov ah, 4ch                        
		int 21h                             
Main ENDP

TEMP PROC
TEMP ENDP

END Main
		  
