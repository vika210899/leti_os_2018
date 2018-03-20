.286
TESTPC		SEGMENT
			ASSUME    CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
			ORG       100H  

START: jmp BEGIN

; DATA
AVAILABLE_MEM   db   'Available memory size: ','$'
EXTENDEN_MEM   	db   'Extended memory size: ','$'
BYTE_      		db   '          bytes', '$'
STR_HEXWRD     	db   '    ','$'
TABLE   		db   'Type | PSP address | Size (bytes) | Data$'
TYPE_    		db   '     |$'
PSP_    		db   '             |$'
SIZE_    		db   '              |$'
DATA_    		db   '                $'
LINE_  		db   0DH,0AH,'$'

TETR_TO_HEX  PROC      near
          and       AL,0FH
          cmp       AL,09
          jbe       NEXT
          add       AL,07
NEXT:
          add       AL,30H
          ret
TETR_TO_HEX  ENDP

BYTE_TO_HEX  PROC      near
          push      CX
          mov       AH,AL
          call      TETR_TO_HEX
          xchg      AL,AH
          mov       CL,4
          shr       AL,CL
          call      TETR_TO_HEX       
          pop       CX             
          ret
BYTE_TO_HEX  ENDP

WRD_TO_HEX  PROC      near
          push      BX
          mov       BH,AH
          call      BYTE_TO_HEX
          mov       [DI],AH
          dec       DI
          mov       [DI],AL
          dec       DI
          mov       AL,BH
          call      BYTE_TO_HEX
          mov       [DI],AH
          dec       DI
          mov       [DI],AL
          pop       BX
          ret
WRD_TO_HEX  ENDP

BYTE_TO_DEC  PROC      near
          push      CX
          push      DX
          push      AX

          xor       AH,AH
          xor       DX,DX
          mov       CX,10
LOOP_BD:  div       CX
          or        DL,30H
          mov       [DI],DL
          dec       DI
          xor       DX,DX
          cmp       AX,10
          jae       LOOP_BD
          cmp       AL,00H
          je        END_L
          or        AL,30H
          mov       [DI],AL
          
END_L:    pop       AX
          pop       DX
          pop       CX
          ret
BYTE_TO_DEC  ENDP

PRINT_NUM PROC      near
          push      CX
          mov       CX,0AH
          div       CX
          or        DX,30H
          mov       [DI],DL
          dec       DI
          xor       DX,DX
          pop       CX
          ret
PRINT_NUM ENDP

TBYTE_TO_DEC PROC      near
          push      AX
          push      CX
          push      DX
          mov       CX,2710H
          cmp       DX,0H
          jnz       LOOP_TBD
          cmp       AX,2710H
          jb        ENDLPTBD
          
LOOP_TBD: div       CX
          push      AX          
          mov       AX,DX
          xor       DX,DX
          call      PRINT_NUM
          call      PRINT_NUM
          call      PRINT_NUM
          call      PRINT_NUM
          pop       AX
          cmp       AX,2710H
          jnb       LOOP_TBD

ENDLPTBD: cmp       AX,0H
          JZ        EXIT_TBD
          call      PRINT_NUM
          jmp       ENDLPTBD
          
EXIT_TBD: pop       DX
          pop       CX
          pop       AX
          ret
TBYTE_TO_DEC ENDP

CLEAR_BYTES  PROC      near
          push      DI
          push      CX
          push      DX
          mov       DI,OFFSET BYTE_+8
          mov       CX,9
          mov       DL,' '
		  
LOOP_CLR: mov       [DI],DL
          dec       DI
          loop      LOOP_CLR
          pop       DX
          pop       CX
          pop       DI
          ret
CLEAR_BYTES  ENDP

PRINT_STRING  PROC      near
          push      AX          
          mov       AH,09H
          int       21H          
          pop       AX
          ret
PRINT_STRING  ENDP

NEWLINE   PROC      near
          push      AX
          push      DX          
          mov       AH,02H
          mov       DL,0DH
          int       21H
          mov       DL,0AH
          int       21H          
          pop       DX
          pop       AX
          ret
NEWLINE   ENDP

; AVAILABLE MEMORY
AV_MEM  PROC      near
          push      AX
          push      BX
          push      DX          
          mov       AH,4AH
          mov       BX,0FFFFH
          int       21H
          clc         
          mov       DX,BX
          mov       AX,BX
          shr       DX,12
          shl       AX,4         
          mov       DI,OFFSET BYTE_+8
          call      TBYTE_TO_DEC
		  mov       DX,OFFSET AVAILABLE_MEM
		  call      PRINT_STRING 
          mov       DX,OFFSET BYTE_
          call      PRINT_STRING         
          call      CLEAR_BYTES         
          mov       DX,OFFSET LINE_
          call      PRINT_STRING         
          pop       DX
          pop       BX
          pop       AX
          ret
AV_MEM  ENDP

; EXTENDED MEMORY
EXT_MEM  PROC      near
          push      DX
          push      AX
          push      BX
          push      DI          
          mov       DX,OFFSET EXTENDEN_MEM
          call      PRINT_STRING         
          mov       AL,30H
          out       70H,AL
          in        AL,71H
          mov       BL,AL         
          mov       AL,31H
          out       70H,AL
          in        AL,71H
          mov       BH,AL         
          mov       DX,BX
          shr       DX,6
          mov       AX,BX
          shl       AX,10         
          mov       DI,OFFSET BYTE_+8
          call      TBYTE_TO_DEC          
          mov       DX,OFFSET BYTE_
          call      PRINT_STRING         
          call      CLEAR_BYTES         
          mov       DX,OFFSET LINE_
          call      PRINT_STRING        
          pop       DI
          pop       BX
          pop       AX
          pop       DX
          ret
EXT_MEM  ENDP

PRINT_TABLE  PROC      near
          push      AX
          push      BX
          push      CX
          push      DX
          push      ES
          push      DI          
          mov       DX,OFFSET TABLE
          call      PRINT_STRING
          call      NEWLINE         
          ; GET "LIST OF LISTS"
          mov       AH,52H
          int       21H
          mov       ES,ES:[BX-2]         
PRINT_LINE: 
          xor       AX,AX
          mov       AL,ES:00H
          mov       DI,OFFSET TYPE_+3
          call      BYTE_TO_HEX
          mov       [DI],AH
          mov       [DI-1],AL
          mov       DX,OFFSET TYPE_
          call      PRINT_STRING         
          mov       AX,ES:01H
          mov       DI,OFFSET PSP_+8
          call      WRD_TO_HEX
          mov       DX,OFFSET PSP_
          call      PRINT_STRING         
          mov       AX,ES:03H
          mov       DI,OFFSET SIZE_+9
          mov       DX,AX
          shr       DX,12
          shl       AX,4
          call      TBYTE_TO_DEC
          mov       DX,OFFSET SIZE_
          call      PRINT_STRING         
          mov       DI,OFFSET DATA_+1
          mov       AX,ES:08H
          mov       [DI],AX
          mov       AX,ES:0AH
          mov       [DI+2H],AX
          mov       AX,ES:0CH
          mov       [DI+4H],AX
          mov       AX,ES:0EH
          mov       [DI+6H],AX          
          mov       DX,OFFSET DATA_
          call      PRINT_STRING          
          mov       DX,OFFSET LINE_
          call      PRINT_STRING         
          mov       AL,ES:00H
          cmp       AL,5AH
          je        EXIT
          mov       AX,ES
          mov       BX,ES:03H
          add       AX,BX
          INC       AX
          mov       ES,AX          
          jmp       PRINT_LINE
          
EXIT:     pop       DI
          pop       ES
          pop       DX
          pop       CX
          pop       BX
          pop       AX
          ret
PRINT_TABLE  ENDP

; CODE
BEGIN:    
          call      AV_MEM
          call      EXT_MEM
          call      PRINT_TABLE
		  mov 		AH, 10H
		  int 		16H
          xor       AL,AL
          mov       AH,4CH
          int       21H
TESTPC      ENDS
END       START
