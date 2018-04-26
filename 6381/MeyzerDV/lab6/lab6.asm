CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
; Функция освобождения лишней памяти
FREE_MEM PROC
	; Вычисляем в BX необходимое количество памяти для этой программы в параграфах
		mov ax,STACKSEG ; В ax сегментный адрес стека
		mov bx,es
		sub ax,bx ; Вычитаем сегментный адрес PSP
		add ax,10h ; Прибавляем размер стека в параграфах
		mov bx,ax
	; Пробуем освободить лишнюю память
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_SUCCESS
	
	; Обработка ошибок
		mov dx,offset STR_ERR_FREE_MEM
		call PRINT
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DESTROYED
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset STR_ERR_WRNG_MEM_BL_ADDR
		
		FREE_MEM_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
	; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	FREE_MEM_SUCCESS:
	ret
FREE_MEM ENDP
;---------------------------------------
; Функция создания блока параметров
CREATE_PARAM_BLOCK PROC
	mov ax, es:[2Ch]
	mov PARMBLOCK,ax ; Кладём сегментный адрес среды
	mov PARMBLOCK+2,es ; Сегментный адрес параметров командной строки(PSP)
	mov PARMBLOCK+4,80h ; Смещение параметров командной строки
	ret
CREATE_PARAM_BLOCK ENDP
;---------------------------------------
; Функция запуска дочернего процесса
RUN_CHILD PROC
	mov dx,offset STRENDL
	call PRINT
	; Устанавливаем DS:DX на имя вызываемой программы
		
		mov dx,offset STD_CHILD_PATH
		; Смотрим, есть ли хвост
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je RUN_CHILD_NO_TAIL ; Если нет хвоста, то используем стандартное имя вызываемой программы
		mov si,cx ; si - номер копируемого символа
		push si ; Сохраняем кол-во символов
		RUN_CHILD_LOOP:
			mov al,es:[81h+si]
			mov [offset CHILD_PATH+si-1],al			
			dec si
		loop RUN_CHILD_LOOP
		pop si
		mov [CHILD_PATH+si-1],0 ; Кладём в конец 0
		mov dx,offset CHILD_PATH ; Хвост есть, используем его
		RUN_CHILD_NO_TAIL:
		
	; Устанавливаем ES:BX на блок параметров
		push ds
		pop es
		mov bx,offset PARMBLOCK

	; Сохраняем SS, SP
		mov KEEP_SP, SP
		mov KEEP_SS, SS
	
	; Вызываем загрузчик:
		mov ax,4b00h
		int 21h
		jnc RUN_CHILD_SUCCESS
	
	; Восстанавливаем DS, SS, SP
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
	
	; Обрабатываем ошибки:
		cmp ax,1
		mov dx,offset STR_ERR_WRNG_FNCT_NUMB
		je RUN_CHILD_PRINT_ERROR
		cmp ax,2
		mov dx,offset STR_ERR_FL_NOT_FND
		je RUN_CHILD_PRINT_ERROR
		cmp ax,5
		mov dx,offset STR_ERR_DISK_ERR
		je RUN_CHILD_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM2
		je RUN_CHILD_PRINT_ERROR
		cmp ax,10
		mov dx,offset STR_ERR_WRONG_ENV_STR
		je RUN_CHILD_PRINT_ERROR
		cmp ax,11
		mov dx,offset STR_ERR_WRONG_FORMAT	
		je RUN_CHILD_PRINT_ERROR
		mov dx,offset STR_ERR_UNKNWN
		RUN_CHILD_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
	; Выходим в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
		
	RUN_CHILD_SUCCESS:
	mov ax,4d00h
	int 21h
	; Вывод причины завершения
		cmp ah,0
		mov dx,offset STR_NRML_END
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,1
		mov dx,offset STR_CTRL_BREAK
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,2
		mov dx,offset STR_DEVICE_ERROR
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,3
		mov dx,offset STR_RSDNT_END
		je RUN_CHILD_PRINT_END_RSN
		mov dx,offset STR_UNKNWN
		RUN_CHILD_PRINT_END_RSN:
		call PRINT
		mov dx,offset STRENDL
		call PRINT

	; Вывод кода завершения:
		mov dx,offset STR_END_CODE
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset STRENDL
		call PRINT

	ret
RUN_CHILD ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	
	call FREE_MEM
	call CREATE_PARAM_BLOCK
	call RUN_CHILD
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
; ДАННЫЕ
DATA SEGMENT
	; Строки ошибок:
		STR_ERR_FREE_MEM	 		db 'Error when freeing memory: $'
		STR_ERR_MCB_DESTROYED 		db 'MCB is destroyed$'
		STR_ERR_NOT_ENOUGH_MEM 		db 'Not enough memory for function processing$'
		STR_ERR_WRNG_MEM_BL_ADDR 	db 'Wrong addres of memory block$'
		STR_ERR_UNKNWN				db 'Unknown error$'
		
		; Ошибки от загрузчика OS
		STR_ERR_WRNG_FNCT_NUMB		db 'Function number is wrong$'
		STR_ERR_FL_NOT_FND			db 'File is not found$'
		STR_ERR_DISK_ERR			db 'Disk error$'
		STR_ERR_NOT_ENOUGH_MEM2		db 'Not enough memory$'
		STR_ERR_WRONG_ENV_STR		db 'Wrong environment string$'
		STR_ERR_WRONG_FORMAT		db 'Wrong format$'
	; Строки, содержащие причины завершения дочерней программы
		STR_NRML_END		db 'Normal end$'
		STR_CTRL_BREAK		db 'End by Ctrl-Break$'
		STR_DEVICE_ERROR	db 'End by device error$'
		STR_RSDNT_END		db 'End by 31h function$'
		STR_UNKNWN			db 'End by unknown reason$'
		STR_END_CODE		db 'End code: $'
		
	STRENDL db 0DH,0AH,'$'
	; Блок параметров. Перед загрузкой дочерней программы на него должен указывать ES:BX
	PARMBLOCK 	dw 0 ; Сегментный адрес среды
				dd ? ; Сегментный адрес и смещение параметров командной строки
				dd 0 ; Сегмент и смещение первого FCB
				dd 0 ; Второго
	
	CHILD_PATH  	db 50h dup ('$')
	STD_CHILD_PATH	db 'LAB2.EXE',0
	; Переменные для хранения SS, SP
	KEEP_SS dw 0
	KEEP_SP dw 0
DATA ENDS
; СТЕК
STACKSEG SEGMENT STACK
	dw 80h dup (?) ; 100h байт
STACKSEG ENDS
 END START