

OVL_CODE SEGMENT
        ASSUME CS: OVL_CODE, DS: NOTHING, ES: NOTHING, SS: NOTHING



OVERLAY_PROC PROC FAR
start:          push    AX
                push    DX
                push    DI
                push    DS
                push    ES
                mov     AX, CS         
                mov     DS, AX         
                mov     ES, AX
                lea     DI, OVL_STR
                add     DI, 45         
                call    WRD_TO_HEX     
                lea     DX, OVL_STR
                call    PRINT
                mov     AH, 01h
                int     21h
                pop     ES
                pop     DS
                pop     DI
                pop     DX
                pop     AX
                retf
OVERLAY_PROC ENDP




OVL_STR db 'Сегментный адрес оверлейного сегмента №3:     H.',  0Dh, 0Ah, '$'



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



PRINT PROC NEAR
                push    AX
                mov     AH, 09h
                int     21h
                pop     AX
                ret
PRINT ENDP

OVL_CODE ENDS
END


