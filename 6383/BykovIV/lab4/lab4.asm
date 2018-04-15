.286

DSEG            SEGMENT
  STR_ALRLOADED db 'is unloaded ', 13, 10, '$'
  STR_NOTHING   db 'is not unloaded', 13, 10 , '$'
DSEG            ENDS

SSEG            SEGMENT STACK
                dw 50H DUP(?)
SSEG            ENDS

CSEG            SEGMENT
                ASSUME DS:DSEG, SS:SSEG, CS:CSEG, ES:NOTHING

RESIDENT       PROC    FAR
                jmp     BEGIN

  KEEP_IP       dw      ?
  KEEP_CS       dw      ?
  PSP           dw      ?
  SIGN          dw      1234H	
  COUNTER 		db 		'Number of calls:    '
  COUNT         db      '000'

BEGIN:          pusha
                push    DS
                push    ES

                mov     DX, SEG RESIDENT
                mov     DS, DX

                mov     DH, '0'
                mov     DL, '9'
                mov     DI, OFFSET COUNT+2

I_START:        cmp     DI, OFFSET COUNT
                jl      I_STOP
                cmp     [DI], DL
                je      I_ZERO
                mov     DL, [DI]
                inc     DL
                mov     [DI], DL
                jmp     I_STOP

I_ZERO:         mov     [DI], DH
                dec     DI
                jmp     I_START

I_STOP:         mov     AX, 1300H
                mov     BX, 000FH
                mov     CX, 0017H
                mov     DX, 0000H
                push    CS
                pop     ES
                mov     BP, OFFSET COUNTER
                int     10H

                pop     ES
                pop     DS
                popa
                mov     AL, 20H
                out     20H, AL
                iret
RESIDENT       ENDP

LAST_BYTE:

;-----------------------------
PRINT           PROC    NEAR
                push    AX
                mov     AX, 0900H
                int     21H
                pop     AX
                ret
PRINT           ENDP

;-----------------------------
MAIN            PROC    FAR
                mov     AX, DSEG
                mov     DS, AX

                mov     CS:[PSP], ES
                mov     DL, ES:[82H]

                mov     AX, 351CH
                int     21H
                mov     CS:[KEEP_CS], ES
                mov     CS:[KEEP_IP], BX

                cmp     DL, '/'
                jne     LOAD

                mov     DX, ES:[SIGN]
                cmp     DX, 1234H
                jne     NOTHING_UNLOAD

                cli
                push    DS
                push    ES
                mov     DS, ES:[KEEP_CS]
                mov     DX, ES:[KEEP_IP]
                mov     AX, 251CH
                int     21H
                pop     DS
                sti

                pop     ES
                push    ES
                mov     ES, ES:[PSP]
                mov     ES, ES:[2CH]
                mov     AX, 4900H
                int     21H
                pop     ES
                mov     ES, ES:[PSP]
                int     21H

                jmp     STOP

LOAD:           mov     DX, ES:[SIGN]
                cmp     DX, 1234H
                je      LOADED

                push    DS
                mov     DX, OFFSET RESIDENT
                mov     AX, SEG RESIDENT
                mov     DS, AX
                mov     AX, 251CH
                int     21H
                pop     DS

                mov     DX, OFFSET LAST_BYTE + 1F0H
                mov     CL, 4
                SHR     DX, CL
                inc     DX
                mov     AX, 3100H
                int     21H
                jmp     STOP

LOADED:         mov     DX, OFFSET STR_ALRLOADED
                call    PRINT
                jmp     STOP

NOTHING_UNLOAD: mov     DX, OFFSET STR_NOTHING
                call    PRINT

STOP:         
				mov ax, 4C00h
                int 21h
MAIN            ENDP
CSEG            ENDS
                END MAIN
