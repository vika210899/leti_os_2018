TESTPC     SEGMENT 
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:TESTPC 
           ORG 100h

START:    jmp PROC_BEGIN
   		

AVAIL_MEM db 'The amount of available memory:                     bytes', 0Dh, 0Ah, '$'
EXPAN_MEM db 'Size of expanded memory:                      bytes',       0Dh, 0Ah, '$'
MCB db       '    Addres              Owner                 Size        Last 8 bytes', 0Dh, 0Ah, '$'
SEG_HEX db '       H   ',                                               '$'
PRG db '          Program          ',                                        '$'
FREE_M db '         Free memory       ',                                        '$'
SEGM db '         Segment     h     ',                                        '$'
SIZES db '          byte             ',                    0Dh, 0Ah, '$'
DR_OS db '     Driver OS XMS UMS    ',                                        '$'
CR_BL db '  Control block 386MAX UMB ',                                        '$'
BL386 db '        386MAX UMB          ',                                        '$'
BLOCK db '         386MAX            ',                                        '$'
MS_D db '         MS DOS            ',                                        '$'
STRING		    db	    0DH,0AH, '$' 


TETR_TO_HEX PROC NEAR
                and     AL, 0Fh
                cmp     AL, 09
                jbe     NEXT
                add     AL, 07
NEXT:           add     AL, 30h
                ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC NEAR
                push    CX
                mov     AH, AL
                call    TETR_TO_HEX
                xchg    AL, AH
                mov     CL, 04h
                shr     AL, CL
                call    TETR_TO_HEX     
                pop     CX             
                ret
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC NEAR
                push    AX
                push    BX
                push    DI
                mov     BH, AH
                call    BYTE_TO_HEX
                mov     DS:[DI], AH
                dec     DI
                mov     DS:[DI], AL
                dec     DI
                mov     AL, BH
                call    BYTE_TO_HEX
                mov     DS:[DI], AH
                dec     DI
                mov     DS:[DI], AL
                pop     DI
                pop     BX
                pop     AX
                ret
WRD_TO_HEX ENDP


BYTE_TO_DEC PROC NEAR
                push    AX
                push    CX
                push    DX
                push    SI
                xor     AH, AH
                xor     DX, DX
                mov     CX, 10
loop_bd:        div     CX
                or      DL, 30h
                mov     DS:[SI], DL
                dec     SI
                xor     DX, DX
                cmp     AX, 10
                jae     loop_bd
                cmp     AL, 00h
                je      end_l
                or      AL, 30h
                mov     DS:[SI], AL
end_l:          pop     SI
                pop     DX
                pop     CX
                pop     AX
                ret
BYTE_TO_DEC ENDP



DWRD_TO_DEC PROC NEAR
                push    AX
                push    BX
                push    CX
                push    DX
                push    DI
                jmp     Clear
Contin:         mov     AX, CX
                mov     BX, DX
Clear:          xor     CX, CX
                xor     DX, DX
Check:          cmp     BX, 00h
                ja      Subst
                cmp     AX, 0Ah
                jb      Print
Subst:          clc
                sub     AX, 0Ah
                sbb     BX, 00h
                clc
                add     CX, 01h
                adc     DX, 00h
                jmp     Check
Print:          add     AX, 30h
                mov     DS:[DI], AL
                dec     DI
                test    CX, CX
                jnz     Contin
                test    DX, DX
                jnz     Contin
                pop     DI
                pop     DX
                pop     CX
                pop     BX
                pop     AX
                ret
DWRD_TO_DEC ENDP
;----------------------------


WRT PROC NEAR
                push    AX
                mov     AH, 09h
                int     21h
                pop     AX
                ret
WRT ENDP



PARAGRAPH PROC NEAR
                push    CX
                xor     BH, BH
                mov     BL, AH
		mov     CL, 4H
                shl     AX, CL
                shr     BX, CL
                clc
                pop     CX
                ret
PARAGRAPH ENDP

AVAILABLE_MEMORY PROC NEAR
		mov     AH, 4Ah         
                mov     BX, 0FFFFh      
                int     21h
		clc
		mov     AX, BX
                call    PARAGRAPH
                lea     DI, AVAIL_MEM
                add     DI, 39        
                call    DWRD_TO_DEC
                lea     DX, AVAIL_MEM
                call    WRT
		ret
AVAILABLE_MEMORY ENDP

SIZE_EXPAN_MEM PROC NEAR
                push    CX
                mov     AL, 30h
                out     70h, AL
                in      AL, 71h
                mov     BL, AL
                mov     AL, 31h
                out     70h, AL
                in      AL, 71h
		mov     ah,al
		mov     al,bl
		lea     DI, EXPAN_MEM
                add     DI, 35         
                call    DWRD_TO_DEC
                lea     DX, EXPAN_MEM
                call    WRT
                pop     CX
                ret
SIZE_EXPAN_MEM ENDP

MCB_LIST 	PROC NEAR
		lea dx,MCB
		call WRT
		push    ES              
                mov     AH, 52h
                int     21h
                mov     ES, ES:[BX-2]  


SEG_ADDR:	lea     DI, SEG_HEX
                mov     AX, '  '
                mov     DS:[DI+04], AX 
                mov     DS:[DI+06], AX  
                mov     AX, ES
                lea     DI, SEG_HEX
                add     DI, 07          
                call    WRD_TO_HEX
                lea     DX, SEG_HEX
                call    WRT
             		
                cmp     word ptr ES:[01h], 00000h
		jne	NEXT1
		lea     DX, FREE_M
                call    WRT
		jmp     Size_part

NEXT1:          cmp     word ptr ES:[01h], 00006h
		jne	NEXT2
		lea     DX, DR_OS
                call    WRT
		jmp     Size_part

NEXT2:		cmp     word ptr ES:[01h], 00008h
		jne	NEXT3
		lea     DX, MS_D
                call    WRT
		jmp     Size_part

NEXT3:		cmp     word ptr ES:[01h], 0FFFAh
		jne	NEXT4
		lea     DX, CR_BL
                call    WRT
		jmp     Size_part


NEXT4:		cmp     word ptr ES:[01h], 0FFFDh
		jne	NEXT5
		lea     DX, BLOCK
                call    WRT
		jmp     Size_part

NEXT5:		cmp     word ptr ES:[01h], 0FFFEh
		jne	NEXT6
		lea     DX, BL386
                call    WRT
		jmp     Size_part

NEXT6:		lea     DI, SEGM
                mov     AX, ES:01h      
                lea     DI, SEGM
                add     DI, 21         
                call    WRD_TO_HEX
                lea     DX, SEGM
                call    WRT
		jmp     Size_part

Size_part:	lea     DI, SIZES
                mov     AX, ES:03h      
                call    PARAGRAPH
                lea     DI, SIZES
                add     DI, 09          
                call    DWRD_TO_DEC
                lea     DI, SIZES
                mov si,08h
BYTE1:
		
		mov al,es:[si]
		cmp al,0
		je  Last
		mov  DS:[DI+19], Al
		cmp  si,15
                je  Last
                inc  di
		inc  si
                jmp  BYTE1


Last:           lea     DX, SIZES
                call    WRT

		cmp     byte ptr ES:[00h], 5Ah
                je      _End
                mov     AX, ES:03h
                mov     BX, ES
                inc     BX              
                add     AX, BX          
                mov     ES, AX
                jmp     SEG_ADDR


_End:    	
		pop     ES  
		ret           
MCB_LIST ENDP


MEMORY_SIZE = ($-START)+300H               
NEXT_SIZE = (MEMORY_SIZE+0Fh)/0FH
MEMORY64=1000h
PROC_BEGIN:	
                        

                mov     AH, 4Ah         
                mov     BX, 0FFFFh      
                int     21h
                clc  
		call AVAILABLE_MEMORY
		call SIZE_EXPAN_MEM
		mov     SP, MEMORY_SIZE    
                mov     AH, 4Ah         
                mov     BX, NEXT_SIZE     
                int     21h 
		mov     AH, 48h         
                mov     BX, MEMORY64   
                int     21h
		call  MCB_LIST
		mov     AH, 4Ch
                int     21h 



TESTPC  ENDS
END START