INT_STACK SEGMENT STACK
	DW 64 DUP (?)
INT_STACK ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;---------------------------------------------------------------
ROUT PROC FAR ;обработчик прерывания
	jmp ROUT_CODE
ROUT_DATA:
	SIGNATURE DB '0000' ;сигнатура, некоторый код, который идентифицирует резидент
	KEEP_IP DW 0 ;и смещения прерывания
	KEEP_CS DW 0 ;для хранения сегмента
	KEEP_PSP DW 0 ;и PSP
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0 
ROUT_CODE:
	mov KEEP_AX, AX ;сохраняем ax
	mov KEEP_SS, SS ;сохраняем стек
	mov KEEP_SP, SP
	mov AX, seg INT_STACK ;устанавливаем собственный стек
	mov SS, AX
	mov SP, 64h
	mov AX, KEEP_AX
	push AX ;сохранение изменяемых регистров
	push DX
	push DS
	push ES
	
	;проверяем скан-код клавиши
	in AL, 60H ;читать ключ
	cmp AL, 0Fh ;это требуемый код? 0F - скан-код Tab
	je DO_REQ ;получили требуемый скан-код
	
	;стандартный обработчик прерывания
	pushf
	call dword ptr CS:KEEP_IP ;переход на первоначальный обработчик
	jmp ROUT_END
	
DO_REQ: ;отработка аппаратного прерывания
	push AX
	in AL, 61h ;взять значение порта управления клавиатурой
	mov AH, AL ;сохранить его
	or AL, 80h ;установить бит разрешения для клавиатуры
	out 61h, AL ;и вывести его в управляющий порт
	xchg AH, AL ;извлечь исходное значение порта
	out 61h, AL ;и записать его обратно
	mov AL, 20h ;послать сигнал "конец прерывания"
	out 20h, AL ;контроллеру прерываний 8259
	pop AX
	
ADD_TO_BUFF: ;запись символа в буфер клавиатуры
	mov AH, 05h ;код функции
	mov CL, 'D' ;пишем символ в буфер клавиатуры
	mov CH, 00h
	int 16h
	or AL, AL ;проверка переполнения буфера
	jz ROUT_END ;переполненение
	;oчищаем буфер клавиатуры
	CLI ;запрещение прерывания
	mov ax,es:[1Ah] ;берём адрес начала буфера
	mov es:[1Ch],ax ;помещаем адрес начала буфера в адрес конца
	STI ;разрешение прерывания
	jmp ADD_TO_BUFF ;повторить

ROUT_END:
	pop ES ;восстановление регистров
	pop DS
	pop DX
	pop AX 
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	mov AX, KEEP_AX
	mov AL,20h
	out 20h,AL
	iret
LAST_BYTE:
ROUT ENDP
;---------------------------------------------------------------
CHECK_INT PROC ;проверка прерывания
	;проверка, установлено ли пользовательское прерывание с вектором 09h
	mov AH,35h ;функция 35h прерывания 21h
	mov AL,09h ;AL = номер прерывания
	int 21h ;дать вектор прерывания
			;выход: ES:BX = адрес обработчика прерывания 
	
	mov SI, offset SIGNATURE ;на определённом, известном смещении в теле резидента располагается сигнатура,
							 ;некоторый код, который идентифицирует резидент
	sub SI, offset ROUT ;SI = смещение SIGNATURE относительно начала функции прерывания
	
	mov AX,'00' ;сравнив известное значение сигнатуры
	cmp AX,ES:[BX+SI] ;с реальным кодом, находящимся в резиденте
	jne NOT_LOADED ;если значения не совпадают, то резидент не установлен
	cmp AX,ES:[BX+SI+2] ;с реальным кодом, находящимся в резиденте
	jne NOT_LOADED ;если значения не совпадают, то резидент не установлен
	jmp LOADED ;если значения совпадают, то резидент установлен
	
NOT_LOADED: ;установка пользовательского прерывания
	call SET_INT ;установка пользовательского прерывания
	;вычисление необходимого количества памяти для резидентной программы
	mov DX,offset LAST_BYTE ;кладём в dx размер части сегмента CODE, содержащей пользовательское прерывание 
							;и необходимые код и данные для него
	mov CL,4 ;перевод в параграфы
	shr DX,CL
	inc DX	;размер в параграфах
	add DX,CODE ;прибавляем адрес сегмента CODE
	sub DX,CS:KEEP_PSP ;вычитаем адрес сегмента PSP
	xor AL,AL
	mov AH,31h ;номер функции 31h прерывания 21h
	int 21h ;оставляем нужное количество памяти
			;(dx - количество параграфов) и выходим в DOS, оставляя программу в памяти резидентно 
		
LOADED: ;смотрим, есть ли в хвосте /un , тогда нужно выгружать
	push ES
	push AX
	mov AX,KEEP_PSP 
	mov ES,AX
	cmp byte ptr ES:[82h],'/' ;сравниваем аргументы
	jne NOT_UNLOAD ;не совпадают
	cmp byte ptr ES:[83h],'u' ;сравниваем аргументы
	jne NOT_UNLOAD ;не совпадают
	cmp byte ptr ES:[84h],'n' ;сравниваем аргументы
	je UNLOAD ;совпадают
	
NOT_UNLOAD: ;если не /un
	pop AX
	pop ES
	mov dx,offset ALREADY_LOADED
	call PRINT
	ret
	;выгрузка пользовательского прерывания
UNLOAD: ;если /un
	pop AX
	pop ES
	call DELETE_INT ;выгрузка пользовательского прерывания
	mov dx,offset UNLOADED ;вывод сообщения
	call PRINT
	ret
CHECK_INT ENDP
;---------------------------------------------------------------
SET_INT PROC ;установка написанного прерывания в поле векторов прерываний
	push DS
	mov AH,35h ;функция получения вектора
	mov AL,09h ;номер вектора
	int 21h
	mov CS:KEEP_IP,BX ;запоминание смещения 
	mov CS:KEEP_CS,ES ;и сегмента
	mov DX,offset ROUT ;смещение для процедуры в DX
	mov AX,seg ROUT ;сегмент процедуры
	mov DS,AX ;помещаем в DS
	mov AH,25h ;функция установки вектора
	mov AL,09h ;номер вестора
	int 21h ;меняем прерывание
	pop DS
	push DX
	mov DX,offset IS_LOADED ;вывод сообщения
	call PRINT
	pop DX
	ret
SET_INT ENDP 
;---------------------------------------------------------------
DELETE_INT PROC ;удаление написанного прерывания в поле векторов прерываний
	push DS
	;восстановление вектора прерывания
	CLI ;запрещение прерывания
	mov DX,ES:[BX+SI+4] ;KEEP_IP
	mov AX,ES:[BX+SI+6] ;KEEP_CS
	mov DS,AX ;DS:DX = вектор прерывания: адрес программы обработки прерывания
	mov AH,25h ;функция 25h прерывания 21h
	mov AL,09h ;AL = номер вектора прерывания
	int 21h ;восстанавливаем вектор
	;освобождение памяти, занимаемой резидентом
	push ES
	mov AX, ES:[BX+SI+8] ;KEEP_PSP 
	mov ES, AX
	mov ES, ES:[2Ch] ;ES = сегментный адрес (параграф) освобождаемого блока памяти 
	mov AH, 49h ;функция 49h прерывания 21h    
	int 21h ;освобождение распределенного блока памяти
	pop ES
	mov ES, ES:[BX+SI+8];KEEP_PSP ES = сегментный адрес (параграф) освобождаемого блока памяти 
	mov AH, 49h ;функция 49h прерывания 21h  
	int 21h	;освобождение распределенного блока памяти
	STI ;разрешение прерывания
	pop DS
	ret
DELETE_INT ENDP 
;---------------------------------------------------------------
PRINT PROC NEAR ;печать на экран 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	mov CS:KEEP_PSP,ES ;сохранение PSP
	call CHECK_INT ;проверка прерывания
	xor AL,AL
	mov AH,4Ch ;выход 
	int 21H
CODE ENDS
;---------------------------------------------------------------
STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	ALREADY_LOADED DB 'User interruption is already loaded!',0DH,0AH,'$'
	UNLOADED DB 'User interruption is unloaded!',0DH,0AH,'$'
	IS_LOADED DB 'User interruption is loaded!',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
END START
