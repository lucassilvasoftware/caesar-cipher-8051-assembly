RS      equ     P1.3    ;Reg Select ligado em P1.3
EN      equ     P1.2    ;Enable ligado em P1.2

ORG 000H
LJMP MAIN

INPUT_SHIFT_LCD:
	DB "Insira o SHIFT"
  DB 00h 
INPUT_STRING_LCD:
  DB "Digite a String"
  DB 00h 

ORG 23H
LEITURA: 
    MOV A, SBUF ; LEITURA BYTE
    ADD A, R3 ; ADICIONA O SHIFT A LETRA
    MOV B, #5Bh ; ADICIONA O VALOR DA DIFERENÇA PARA CICLAR A LETRA, CASO A SOMA SEJA MAIOR QUE 26
    MOV R2, A ; ARMAZENA O VALOR ORIGINAL DA LETRA EM R2

    SUBB A, B ; SUBTRAI B DE A, PARA SABER SE A SOMA É MAIOR QUE 26
    JNC AGREATER ; SE O BIT DO CARRY NAO FOR SETADO, O A É MAIOR, LOGO DEVE-SE TRATAR A DIFERENÇA E CICLAR A LETRA
    MOV A, R2 ; CASO B FOR MAIOR, PULA DIRETO PARA A ESCRITA
    JMP WRITE

AGREATER: ; TRATAR O CICLO
    MOV R7, A ; COLOCA EM R7 O VALOR DA DIFERENCA
    MOV A, #41h ; COLOCA EM A 41
    ADD A, R7 ; ADICIONA 41 AO R7, AI FICA DIFERENCA MAIS 41

WRITE:
    MOV SBUF, A ; ESCREVE LETRA NO RECEPTOR
    JNB TI, $ ; AGUARDA FIM DA TRANSMISSAO
    CLR TI ; APAGA INDICADOR FIM DA TRANSMISSAO
    CLR RI ; APAGA INDICADOR FIM DA ENTRADA
    RETI ; AVANÇA PARA A PROXIMA ENTRADA

;ABCDEFGHIJKLMNOPQRSTUVWXYZ

ORG 200H
MAIN:
	MOV 40H, #'#' ; MAPEAMENTO DAS TECLAS DO KEYPAD ->
	MOV 41H, #0h
	MOV 42H, #'*'
	MOV 43H, #09h
	MOV 44H, #08h
	MOV 45H, #07h
	MOV 46H, #06h
	MOV 47H, #05h
	MOV 48H, #04h
	MOV 49H, #03h
	MOV 4AH, #02h
	MOV 4BH, #01h

ESCRITA_LCD:
	ACALL lcd_init
	MOV A, #00h
	ACALL posicionaCursor
	MOV DPTR,#INPUT_SHIFT_LCD
	ACALL escreveStringROM
	JMP LEITURA_PRIMEIRO_NUMERO

LEITURA_PRIMEIRO_NUMERO:

	ACALL LEITURA_TECLADO ; CHAMA A FUNCAO QUE ARMAZENA EM R0 A LETRA
	JNB F0, LEITURA_PRIMEIRO_NUMERO

	MOV A, #40h ;LOGICA PARA OBTER O NUMERO CORRETO A PARTIR DO MÉTODO LEITURA_TECLADO
	ADD A, R0
	MOV R0, A
	MOV A, @R0 
	
	MOV B, #0AH ; COLOCA EM B O VALOR 10
	MUL AB ; MULTIPLICA POR 10 O PRIMEIRO INPUT PARA FAZER A DEZENA
	MOV R3, A ; ARMAZENA E R3 A MULTIPLICACAO

	CLR F0 ; CLEAR EM F0 PARA ACEITAR O PROXIMO INPUT DA UNIDADE

LEITURA_SEGUNDO_NUMERO:
	CALL DELAY ; DELAY PARA NÃO LER DUAS VEZES O MESMO NUMERO
	CLR A
	ACALL LEITURA_TECLADO ; CHAMA A FUNCAO QUE ARMAZENA EM R0 A LETRA
	JNB F0, LEITURA_SEGUNDO_NUMERO ; LISTENER PARA PEGAR A LETRA

	MOV A, #40h ; LOGICA PARA OBTER O NUMERO CORRETO A PARTIR DO MÉTODO LEITURA_TECLADO
	ADD A, R0
	MOV R0, A
	MOV A, @R0 

	ADD A, R3 ; ADICIONA A UNIDADE EM R3
	MOV R3, A ; COLOCA O VALOR TOTAL O SHIFT NO ACUMULADOR
	CLR F0 ; CLEANA O F0 PRA NADA NN SEI PQ ISSO TA AQ

	ACALL clearDisplay
	MOV A, #00h
	ACALL posicionaCursor
	MOV DPTR,#INPUT_STRING_LCD
	ACALL escreveStringROM
	JMP SETUP_TRANSMISSORS

SETUP_TRANSMISSORS:
    MOV SCON, #50H
    MOV PCON, #80H
    MOV TMOD, #20H
    MOV TH1, #243
    MOV TL1, #243
    MOV IE, #90H
    SETB TR1
	JMP $

LEITURA_TECLADO: ; MÉTODO RESPONSÁVEL POR LER O KEYPAD
	MOV R0, #0			

	; scan row0
	MOV P0, #0FFh	
	CLR P0.0			
	CALL colScan		
	JB F0, finish		
						
	; scan row1
	SETB P0.0			
	CLR P0.1			
	CALL colScan		
	JB F0, finish		
						
	; scan row2
	SETB P0.1			
	CLR P0.2			
	CALL colScan		
	JB F0, finish		
						
	; scan row3
	SETB P0.2			
	CLR P0.3			
	CALL colScan		
	JB F0, finish		
						
finish:
	RET

colScan: ; MÉTODOS AUXILIARES DO LEITURA
	JNB P0.4, gotKey	
	INC R0				
	JNB P0.5, gotKey	
	INC R0				
	JNB P0.6, gotKey	
	INC R0				
	RET					
gotKey:
	SETB F0 		; key found - set F0
	CALL DELAY
	RET				; RETORNA PARA A SUBROTINA


DELAY: ; MÉTODO DE DELAY
	MOV R7, #15000
	DJNZ R7, $
	RET

escreveStringROM:
  MOV R1, #00h
	; Inicia a escrita da String no Display LCD
loop:
  MOV A, R1
	MOVC A,@A+DPTR 	 ;l  da mem ria de programa
	JZ finish		; if A is 0, then end of data has been reached - jump out of loop
	ACALL sendCharacter	; send data in A to LCD module
	INC R1			; point to next piece of data
   MOV A, R1
	JMP loop

lcd_init:
	CLR RS		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay2		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB EN		; |
	CLR EN		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB EN		; |
	CLR EN		; | negative edge on E
				; function set low nibble sent
	CALL delay2		; wait for BF to clear


; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay2		; wait for BF to clear


; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay2		; wait for BF to clear
	RET


sendCharacter:
	SETB RS  		; setb RS - indicates that data is being sent to module
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay2			; wait for BF to clear
	CALL delay2		; wait for BF to clear
	RET

;Posiciona o cursor na linha e coluna desejada.
;Escreva no Acumulador o valor de endere o da linha e coluna.
;|--------------------------------------------------------------------------------------|
;|linha 1 | 00 | 01 | 02 | 03 | 04 |05 | 06 | 07 | 08 | 09 |0A | 0B | 0C | 0D | 0E | 0F |
;|linha 2 | 40 | 41 | 42 | 43 | 44 |45 | 46 | 47 | 48 | 49 |4A | 4B | 4C | 4D | 4E | 4F |
;|--------------------------------------------------------------------------------------|
posicionaCursor:
	CLR RS	
	SETB P1.7		    ; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay2		; wait for BF to clear
	CALL delay2			; wait for BF to clear
	RET


;Retorna o cursor para primeira posi  o sem limpar o display
retornaCursor:
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL DELAY2		; wait for BF to clear
	RET


;Limpa o display
clearDisplay:
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	MOV R6, #40
	rotC:
	CALL delay2		; wait for BF to clear
	DJNZ R6, rotC
	RET


DELAY2:
	MOV R0, #50
	DJNZ R0, $
	RET
