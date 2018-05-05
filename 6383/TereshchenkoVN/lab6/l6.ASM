
.SEQ    

L6_CODE SEGMENT
        ASSUME CS: L6_CODE, DS: L6_DATA, ES: NOTHING, SS: L6_STACK

START:  jmp l6_start

; ____________________________________________________________________________
L6_DATA SEGMENT

        PSP_SIZE = 10h                   
        STACK_SIZE = 10h                   

	SIZE_NAME_F db 100h dup (?)         
        NAME_F db '2.com', 00h 	
        COMAHD_LINE db 0Ch, ' /path /path' 

        ERROR_E02 db 'Ошибка запуска, код 0002H: файл 2.com не найден.',      0Dh, 0Ah, '$'
     
        KEEP_SS dw ?                    
        KEEP_SP dw ? 

        
	STP_00 db 'Причина завершения 00H: Нормальное завершение, код: 7AH',  0Dh, 0Ah, '$'
        STP_01 db 'Причина завершения 01H: Завершение с помощью Ctrl-C.',  0Dh, 0Ah, '$'
        ENV_SAD dw 00h                  
        CMLN_IP dw offset COMAHD_LINE     
        CMLN_CS dw seg COMAHD_LINE          
                       

         

                           


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
                jmp     cond_nam


; ____________________________________________________________________________

cond_nam:       push    ES              
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
cond_cpi:       lea     DI, SIZE_NAME_F    
cond_cpl:       cmp     SI, AX          
                ja      cond_cni        
                mov     BL, ES:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     cond_cpl
cond_cni:       pop     ES              
                lea     SI, NAME_F     
cond_cnl:       cmp     byte ptr DS:[SI], 00h   
                je      cond_pbs        
                mov     BL, DS:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     cond_cnl

; ____________________________________________________________________________

cond_pbs:       push    ES              
                mov     BX, seg ENV_SAD
                mov     ES, BX          
                lea     BX, ENV_SAD     
                mov     DX, seg SIZE_NAME_F
                mov     DS, DX          
                lea     DX, SIZE_NAME_F    
                mov     KEEP_SS, SS     
                mov     KEEP_SP, SP     
                jmp     err_prg

; ____________________________________________________________________________

err_prg:       mov     AH, 4Bh         
                mov     AL, 00h         
                int     21h
                mov     BX, L6_DATA
                mov     DS, BX          
                mov     SS, KEEP_SS     
                mov     SP, KEEP_SP     
                pop     ES              
		jc 	err_e02
                jmp     stp_cds
err_e02:       cmp     AX, 02h
       		mov 	DX, offset ERROR_E02
		call	PRINT
                jmp     quit

; ____________________________________________________________________________

stp_cds:       mov     AH, 4Dh         
                int     21h
                cmp     AH, 00h
                jne     stp_c01
                call    BYTE_TO_HEX     
                lea     DI, STP_00
                mov     DS:[DI+52], AX  
      		mov 	DX, offset STP_00
		call	PRINT
                jmp     quit
stp_c01:       cmp     AH, 01h
  		mov 	DX, offset STP_01
		call	PRINT
                jmp     quit

; ____________________________________________________________________________

quit:       mov     AH, 01h
                int     21h
                mov     AH, 4Ch
                int     21h

L6_CODE ENDS
END START

; ____________________________________________________________________________
