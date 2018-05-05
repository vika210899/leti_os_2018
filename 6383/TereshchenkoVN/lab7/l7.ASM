
.SEQ    

L6_CODE SEGMENT
        ASSUME CS: L6_CODE, DS: L6_DATA, ES: NOTHING, SS: L6_STACK

START:  jmp l6_start

; ____________________________________________________________________________
L6_DATA SEGMENT

        PSP_SIZE = 10h                   
        STACK_SIZE = 10h                   


        ERROR_E02 db 'Ошибка поиска, код 0002H: файл LR2.COM не найден.',     0Dh, 0Ah, '$'
        OVL_END db 'Во время проверки оверлеев возникла ошибка.',  			        0Dh, 0Ah, '$'
	FND_E02 db 'Ошибка поиска, код 0002H: указанный путь не существует.',   0Dh, 0Ah, '$'
        FND_E12 db 'Ошибка поиска, код 0012H: файл не найден.',       0Dh, 0Ah, '$'
        

        
	STP_00 db 'Причина завершения 00H: Нормальное завершение, код:   H.',  0Dh, 0Ah, '$'
        STP_01 db 'Причина завершения 01H: Завершение с помощью Ctrl-C.',  0Dh, 0Ah, '$'
               
        
	ABS_NM1 db 100h dup (?)      
        OVL_NM1 db 'OV1.OVL', 00h  
        ABS_NM2 db 100h dup (?)         
        OVL_NM2 db 'OV2.OVL', 00h  
        ABS_NM3 db 100h dup (?)         
        OVL_NM3 db 'OV3.OVL', 00h   

        DTA_BUF db 2Bh dup (?)     
        OVLN_IP dw 00h                 
        OVLN_CS dw 00h                 
        EPB_DW1 dw 00h                 
        EPB_DW2 dw 00h                                

         

                           


L6_DATA ENDS

; ____________________________________________________________________________

L6_STACK SEGMENT STACK
        db STACK_SIZE * 10h dup (?)
L6_STACK ENDS

; ____________________________________________________________________________

TETR_TO_HEX PROC NEAR
                and     AL, 0Fh
                cmp     AL, 09
                jbe     NEXT
                add     AL, 07
NEXT:           add     AL, 30h
                ret
TETR_TO_HEX ENDP

; ____________________________________________________________________________

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

; ____________________________________________________________________________

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


PRINT PROC NEAR
		push 	AX
		mov 	AH, 09h
		int 	21h
		pop 	ax
		ret
PRINT ENDP


; ____________________________________________________________________________

l6_start:       mov     BX, L6_DATA     
                mov     DS, BX          
                mov     BX, L6_STACK    
                add     BX, STACK_SIZE     
                sub     BX, L6_CODE     
                add     BX, PSP_SIZE     
                mov     AH, 4Ah         
                int     21h             
		jmp 	condare_DTA


; ____________________________________________________________________________

condare_DTA:    mov 	AH, 1Ah
		lea	DX, DTA_BUF
		int 	21h
		mov 	SI, 00h
		jmp	ovl
		    
; ____________________________________________________________________________

ovl:            inc     SI
                jmp     name_ov1
name_ov1:       cmp     SI, 01h         
                jne     name_ov2        
                lea     CX, OVL_NM1
                lea     DX, ABS_NM1
                jmp     cond_nam
name_ov2:       cmp     SI, 02h         
                jne     name_ov3        
                lea     CX, OVL_NM2
                lea     DX, ABS_NM2
                jmp     cond_nam
name_ov3:       cmp     SI, 03h        
                jne     name_eol       
                lea     CX, OVL_NM3
                lea     DX, ABS_NM3
                jmp     cond_nam
name_eol:       mov   	DX, offset OVL_END	
                call    PRINT
                jmp     quit

; ____________________________________________________________________________
cond_nam:       push    SI              
                push    ES              
                mov     ES, ES:[2Ch]    
                xor     SI, SI          
cond_eel:       cmp     word ptr ES:[SI], 0000h 
                je      cond_lsi        
                inc     SI              
                jmp     cond_eel        
cond_lsi:       add     SI, 4           
                mov     DI, SI          
                xor     AX, AX          
cond_lsl:       cmp     byte ptr ES:[DI], 00h   
                je      cond_cpi        
                cmp     byte ptr ES:[DI], "/"   
                je      cond_sls        
                cmp     byte ptr ES:[DI], "\"   
                je      cond_sls        
                jmp     cond_lsn        
cond_sls:       mov     AX, DI          
cond_lsn:       inc     DI              
                jmp     cond_lsl
cond_cpi:       mov     DI, DX          
cond_cpl:       cmp     SI, AX          
                ja      cond_cni        
                mov     BL, ES:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     cond_cpl
cond_cni:       pop     ES              
                mov     SI, CX          
cond_cnl:       cmp     byte ptr DS:[SI], 00h   
                je      find_ovl        
cond_cns:       mov     BL, DS:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     cond_cnl

; ____________________________________________________________________________

find_ovl:       pop     SI              
                mov     AH, 4Eh         
                mov     CX, 00h         
                int     21h
                jc      find_e02
                jmp     size_of_ov
find_e02:       cmp     AX, 02h
                jne     find_e12
      		mov 	DX, offset FND_E02
		call	PRINT
                jmp     quit
find_e12:       cmp     AX, 12h
     		mov 	DX, offset FND_E12
		call	PRINT
                jmp     quit
; ____________________________________________________________________________

size_of_ov:       lea     BP, DTA_BUF
                mov     AX, DS:[BP+1Ah] 
                mov     BX, DS:[BP+1Ch] 
                xchg    DX, BP          
                mov     DX, BX
                and     DX, 0000000000001111b   
                cmp     DX, BX                 
                mov     CL, 0Ch         
                shl     DX, CL          
                mov     DL, AL
                and     DL, 00001111b   
                cmp     DL, 00000000b   
                je      get_para        
                mov     DL, 01h         
                jmp     get_para        
get_para:       mov     CL, 04h
                shr     AX, CL          
                add     AX, DX                 
                xchg    DX, BP          
                jmp     free_mem
; ____________________________________________________________________________

free_mem:       mov     BX, AX          
                mov     AH, 48h         
                int     21h
                mov     OVLN_CS, AX    
                jmp     ovl_param

; ____________________________________________________________________________
ovl_param:       mov     BX, seg EPB_DW1
                push    ES              
                mov     ES, BX          
                lea     BX, EPB_DW1     
                mov     EPB_DW1, AX     
                mov     EPB_DW2, AX     
                jmp     load_ovl

; ____________________________________________________________________________
load_ovl:       mov     CH, 01h         
                mov     AH, 4Bh         
                mov     AL, 03h         
                int     21h
                pop     ES              
                jc      load_e01        
                mov     CH, 00h         
                jmp     exec_ovl
load_e01:       cmp     AX, 01h
                jne     load_e02
		mov 	DX, offset FND_E02
		call 	PRINT
                jmp     fee_mem_exe
load_e02:       cmp     AX, 02h
       		mov 	DX, offset FND_E12
		call 	PRINT
                jmp     fee_mem_exe

; ____________________________________________________________________________

exec_ovl:       call    dword ptr DS:[OVLN_IP]
                jmp     fee_mem_exe

; ____________________________________________________________________________

fee_mem_exe:       mov     AX, OVLN_CS     
                push    ES              
                mov     ES, AX          
                mov     AH, 49h         
                int     21h
                pop     ES              
                cmp     CH, 00h         
                jne     quit
                jmp     ovl


quit:           mov     AH, 01h
                int     21h
                mov     AH, 4Ch
                int     21h

L6_CODE ENDS
END START
