;*****************************************************************************************
; Author: Dat Tran, S. J.
; Program: LabLib.asm
; Description: Library Subroutines
;*****************************************************************************************

;*****************************************************************************************
;* Constants for LCD
;*****************************************************************************************
RS_LIB		EQU	mPORTB_BIT0	;
EN_LIB		EQU	mPORTB_BIT1	;
RW_LIB		EQU	mPORTB_BIT7	;

;*****************************************************************************************
; Constants display message
;*****************************************************************************************
MSG_POS_LIB	EQU	$00
NUM_POS_LIB	EQU	$0D
XTEN_POS_LIB	EQU	$40
XUNIT_POS_LIB	EQU	$4B

;*****************************************************************************************
;* Constants for buffer
;*****************************************************************************************
SIZE_LIB	EQU	6	;
TEN_LIB		EQU	10	;

;*****************************************************************************************
;* Other Constants
;*****************************************************************************************
ASCII_CONVERT_LIB	EQU	$30

;*****************************************************************************************
; Special characters
;*****************************************************************************************
NULL_LIB	EQU	$00	; ASCII code for NULL character
SPACE_LIB	EQU	$20	; ASCII code for ' ' character
ASCII_ZERO_LIB	EQU	$30	; ASCII code for '0' character
ASCII_NINE_LIB	EQU	$39	; ASCII code for '9' character
ASCII_POUND_LIB	EQU	$23	; ASCII code for '#' character

;*****************************************************************************************
; Constants for  PT2_100Hz_OC2
;*****************************************************************************************
DELAY_CNT_LIB	EQU 	1875	; delay count for 100Hz (with 1:64 prescaler)
TOGGLE_LIB	EQU 	$10	; value to toggle the TC2 pin

;*****************************************************************************************
; Message headers
;*****************************************************************************************
Msg_prompt_Lib	DC.B	'Key Entered: ', $00	;
Xten_Msg_Lib	DC.B	'XT: ', $00		;
Xunit_Msg_Lib	DC.B	'XU: ', $00		;

;*****************************************************************************************
;* control bytes for setting up SCI1:
;	 a.  19200 baud (bps): 
;		Num = 24Mhz / (16 * SBR ) = 24MHz / (16 * 19200) = 78 = $4E 
;		(SCI1BDH = 0, SCI1BDL = $4E)
;	 b.  1 start bit, 8-data bit, 1 stop bit, no parity 
;	 c.  disable interrupt for transmitting and receiving, enable both transmitter and
;		receiver
;*****************************************************************************************
SCI1_Ctl_Bytes_Lib	DC.B	$00	; SCI1BDH = 0
			DC.B	$4E	; SCI1BDL = 78 = $4E
			DC.B	$00	; SCI1CR1: 8-data bit, 1 stop bit, no parity
			DC.B	$0C	; SCI1CR2: TE, RE enabled.

;*****************************************************************************************
; HEX values for displaying digit in 7-segment display LEDs
;*****************************************************************************************
Digit_Table_Lib		DC.B	$3F	; digit "0"
			DC.B	$06	; digit "1"
			DC.B	$5B	; digit "2"
			DC.B	$4F	; digit "3"
			DC.B	$66	; digit "4"
			DC.B	$6D	; digit "5"
			DC.B	$7C	; digit "6"
			DC.B	$07	; digit "7"
			DC.B	$7F	; digit "8"
			DC.B	$67	; digit "9"

;*****************************************************************************************
; Subroutine Init_Hardware_Lib - initializes the hardware
;*****************************************************************************************
Init_Hardware_Lib:
	JSR	Set_Clk_24Mhz	; set 24Mhz bus clock
	JSR	Set_Timer_Lib	; set the timer delay
	;JSR	Init_Keypad_Lib ; initializing keypad
	;JSR	Init_LCD_Lib	; initializing LCD
	;JSR	Init_LEDs_Lib	; initializing LEDs
	;JSR	Init_Switches_Lib; initializing DIP Switches
	JSR	Init_AD0_Lib	; initializing A/D
	JSR	Init_Sound_Lib	; initializing sound
	;JSR	Init_Seven_Seg_LEDs; initializing 7-segment LEDs
	;JSR	Init_RGB_Lib	; initializing RGB LEDs
	;JSR	Init_PortE_Lib	; initializing Port E for IRQ interrupt
	;JSR	Init_SCI1_Lib	; initializing SCI1
	;JSR	Init_PE2_Relay_Lib; initializing PE2 for Relay
	;JSR	PT2_100Hz_OC2	; set up a 100Hz square wave at PT2
	RTS

;*****************************************************************************************
; Subroutine Set_Clk_24Mhz - sets the bus speed to 24Mhz
;*****************************************************************************************
Set_Clk_24Mhz:
	; PLL code for 24MHz bus speed from a 4/8/16 crystal
	LDX	#$00			;
	BCLR	CLKSEL, X, mCLKSEL_PLLSEL	; clear bit 7, clock derived from oscclk
	BSET	PLLCTL, X, mPLLCTL_PLLON	; Turn PLL on, bit 6=1 PLL on, bit 6=0 PLL off
	LDAA	#$05			; 5+1=6 multiplier
	STAA	SYNR, X			;
	LDAA	#$01			; divisor=1+1=2, 8*2*6 /2 = 48MHz PLL freq,
					; for 8 MHz crystal
	STAA	REFDV, X
	BRCLR	CRGFLG, X, mCRGFLG_LOCK, *	; Wait until bit 3 = 1
	BSET	CLKSEL, X, mCLKSEL_PLLSEL	;
	RTS

;*****************************************************************************************
; Subroutine Set_Timer_Lib - sets Timer Control Register for delay
;*****************************************************************************************
Set_Timer_Lib:
	MOVB	#$90, TSCR1		; enable TCNT, fast timer flag clear
	MOVB	#$06, TSCR2		; set main timer prescaler to 64
	BSET	TIOS, mTIOS_IOS0	; enable OC0 for delay counter
	RTS
;*****************************************************************************************
; Subroutine Init_PortE - setups Port E for IRQ interrupt
;*****************************************************************************************
Init_PortE_Lib:   
	BSET    INTCR, mINTCR_IRQE  ; falling edge trigger
	BSET    INTCR, mINTCR_IRQEN ; interrupt enabled
	BCLR    PUCR, mPUCR_PUPEE   ; pull-up resistors of Port E are disabled.
	RTS
;*****************************************************************************************
; Subroutines for relay
;*****************************************************************************************
;*****************************************************************************************
;* Init_PE2_Relay_Lib - setups PE2 as an output for the relay
;*****************************************************************************************
Init_PE2_Relay_Lib:
	BSET	DDRE, mDDRE_BIT2		; set PE2 for the output
	RTS
;*****************************************************************************************
;* PE2_Relay_ON_Lib - Sets PE2 to 1 to turn on the relaty
;*****************************************************************************************
PE2_Relay_ON_Lib:
	BSET	PORTE, mPORTE_BIT2	; turn on the relay
	RTS

;*****************************************************************************************
;* PE2_Relay_ON_Lib - Sets PE2 to 0 to turn off the relaty
;*****************************************************************************************
PE2_Relay_OFF_Lib:
	BCLR	PORTE, mPORTE_BIT2	; turn on the relay
	RTS
	
;*****************************************************************************************
;* Init_Switches_Lib - initializes Port H for DIP switch
;*****************************************************************************************
Init_Switches_Lib:
	; Set Port H for input mode
	MOVB	#$00, DDRH	;
	RTS

;*****************************************************************************************
; Subroutine PT2_100Hz_OC2 - sets 100Hz square for OC2 at PT2
;*****************************************************************************************
PT2_100Hz_OC2:
	BSET	TIOS, mTIOS_IOS2	; enable OC2
	MOVB	#TOGGLE_LIB, TCTL2	; select toggle for OC2 pin action
	LDD	TCNT			; load the counter timer register
	ADDD	#DELAY_CNT_LIB		;
	STD	TC2
	BSET	TIE, mTIE_C2I		; enable OC2 interrupt		
	RTS
	
;*****************************************************************************************
; Interrupt service routine for OC2
;*****************************************************************************************
OC2_ISR:
	CLI				; clear I bit enable other interrupt
	LDD	TC2
	ADDD	#DELAY_CNT_LIB
	STD	TC2
	RTI

;*****************************************************************************************
; Subroutines for sound
;*****************************************************************************************
;*****************************************************************************************
;* Init_Sound_Lib - initializes Port T for sound
;*****************************************************************************************
Init_Sound_Lib:
	; configure PT5: output
	BSET	DDRT, mDDRT_DDRT5;
	RTS

;*****************************************************************************************
;* Siren_Lib - creates a siren using the speaker
;*****************************************************************************************
Siren_Lib:
	PSHX			; save the value of IX onto the stack
	PSHY			; save the value of IY onto the stack
	LDX	#250		; repeat 500Hz waveform for 250 times
Siren_Lib_Tone1:  
	BSET	PTT,  mPTT_PTT5	; pull PT5 pin high	  
	LDY	#1
	JSR	Delay1ms		;
	BCLR	PTT,  mPTT_PTT5	; pull PT5 pin low
	LDY	#1
	JSR	Delay1ms		;
	DBNE	X, Siren_Lib_Tone1;
		
	LDX	#125		; repeat 250Hz waveform for 125 times
Siren_Lib_Tone2:  
	BSET	PTT,  mPTT_PTT5	; pull PT5 pin high
	LDY	#2
	JSR	Delay1ms		;
	BCLR	PTT,  mPTT_PTT5	; pull PT5 pin low
	LDY	#2
	JSR	Delay1ms	;
	DBNE	X, Siren_Lib_Tone2;
		
	PULY			; restore the value of IY
	PULX			; restore the value of IX	
	RTS

;*****************************************************************************************
;* Buzz_Lib - creates a buzz sound for alarm clock
;*****************************************************************************************
Buzz_Lib:
	PSHX			; save the value of IX onto the stack
	PSHY			; save the value of IY onto the stack
		
	LDX	#250		; repeat 1kHz waveform for 250 times
Buzz_Lib_Loop:  
	BSET	PTT,  mPTT_PTT5	; pull PT5 pin high	  
	LDY	#5
	JSR	Delay100us	;
	BCLR	PTT,  mPTT_PTT5	; pull PT5 pin low
	LDY	#5
	JSR	Delay100us	;
	DBNE	X, Buzz_Lib_Loop	;
		 
	PULY			; restore the value of IY
	PULX			; restore the value of IX	
	RTS

;*****************************************************************************************
; Subroutines for Analog to Digital AD0
;*****************************************************************************************
;*****************************************************************************************
; Subroutine Init_AD0_Lib - initializes AD0
;*****************************************************************************************
Init_AD0_Lib:
	MOVB	#$E0, ATD0CTL2	; enable AD0, fast ATD flag clear.
	LDY	#2
	JSR	Delay50us	; wait for AD0 is stabilized.
	MOVB	#$22, ATD0CTL3	; 1 A/D conversion
	MOVB	#$25, ATD0CTL4	; 10-bit operation, 4 A/D conversion/clock,
				; prescaler to 12
	RTS

;*****************************************************************************************
; Subroutine Light_PAD4_Lib - gets the A/D conversion for light sensor (Q1)
;*****************************************************************************************
Light_PAD4_Lib:
	MOVB	#$84, ATD0CTL5	; start an ATD conversion sequence on channel 5
				; (Q1 - Light sensor) of ATD0
	BRCLR	ATD0STAT0,mATD0STAT0_SCF, * 	; wait for the conversion to complete
	LDD	ATD0DR0		; read a conversion result
	RTS
;*****************************************************************************************
; Subroutine Temperature_PAD5_Lib - gets the A/D conversion for temperature measurement
;	(U14A - Temperature sensor)
;*****************************************************************************************
Temperature_PAD5_Lib:
	MOVB	#$85, ATD0CTL5	; start an ATD conversion sequence on channel 5
				; (U14A - Temperature sensor) of ATD0
	BRCLR	ATD0STAT0,mATD0STAT0_SCF, * 	; wait for the conversion to complete
	LDD	ATD0DR0		; read a conversion result
	RTS
;*****************************************************************************************
; Subroutine Trimmer_PAD7_Lib - gets the A/D conversion for trimmer pot VR2
;*****************************************************************************************
Trimmer_PAD7_Lib:
	MOVB	#$87, ATD0CTL5		; start an ATD conversion sequence on channel 5
					; (Q1 - Light sensor) of ATD0
	BRCLR	ATD0STAT0,mATD0STAT0_SCF, * 	; wait for the conversion to complete
	LDD	ATD0DR0			; read a conversion result
	RTS

;*****************************************************************************************
; Subroutines for SCI1
;*****************************************************************************************
;*****************************************************************************************
; subroutine Init_SCI1_Lib - initializes SCI1 with the control bytes in SCI1_Ctl_Bytes
;***************************************************************************************** 
Init_SCI1_Lib:
	PSHX				; save IX onto the stack
	LDX	#SCI1_Ctl_Bytes_Lib	; IX <- address of sci_init
	MOVB	0, X, SCI1BDH		; SCI1BDH
	MOVB	1, X, SCI1BDL		; SCI1BDL
	MOVB	2, X, SCI1CR1		; SCI1CR1
	MOVB	3, X, SCI1CR2		; SCI1CR2
	PULX				; restore IX
	RTS

;*****************************************************************************************
;* subroutine Write_Msg_SCI1_Lib - sends characters, pointed in IX, to SCI1.
;*****************************************************************************************
Write_Msg_SCI1_Lib:
	PSHX				; save IX onto the stack
	PSHD				; save D onto th stack
Wrtie_Msg_SCI1_Lib_Again:
	LDAA	1, X+			;
	CMPA	#NULL_LIB		; check for the end of the message
	BEQ	Write_Msg_SCI1_Lib_Done	;
	JSR	Out_SCI1_Lib		; send the character to SCI1
	BRA	Wrtie_Msg_SCI1_Lib_Again	;	
Write_Msg_SCI1_Lib_Done:
	PULD				; restore D
	PULX				; restore IX
	RTS

;*****************************************************************************************
;* subroutine In_SCI1_Lib - reads an ASCII character from SCI1 and saves it into ACCA. 
;	If there is no character, ACCA is set to NULL character
;***************************************************************************************** 
In_SCI1_Lib:
	BRCLR	SCI1SR1, mSCI1SR1_RDRF, No_Char_Lib	; check RDRF flag
	BRCLR	SCI1SR1, $0F, Read_Char_Lib	; check for error (overrun, noise, frame, parity)
	BRA	No_Char_Lib			;
Read_Char_Lib:
	LDAA	SCI1DRL				; read a character from SCI1
	ANDA	#$7F				; clear parity bit	
	BRA	In_SCI1_Lib_Done			;
No_Char_Lib:
	LDAA	#NULL_LIB			; ACCA <- NULL
In_SCI1_Lib_Done:
	RTS

;*****************************************************************************************
;* subroutine Out_SCI1_Lib - sends an ASCII character in ACCA to SCI1
;*****************************************************************************************
Out_SCI1_Lib:
	BRCLR	SCI1SR1, mSCI1SR1_TDRE, *	; check TDRE flag; if it is not empty, wait
	STAA	SCI1DRL				; send a character to SCI1
	RTS

;*****************************************************************************************
; Subroutines for LEDs
;*****************************************************************************************
;*****************************************************************************************
;* Init_LEDs_Lib - initializes Ports B & P for LED's
;*****************************************************************************************
Init_LEDs_Lib:
	; set Port B for output mode
	MOVB	#$FF, DDRB		; PB0 - PB7: outputs
	CLR	PORTB			; All LEDs are OFF
	
	; set PJ1
	BSET	DDRJ, mDDRJ_DDRJ1		; PJ1: output
	BCLR	PTJ, mPTIJ_PTIJ1		; PJ1 = 0; LEDs are ON
	
	; turn off 7-segment LED display
	JSR	Turn_Off_Seven_Seg_Lib	;
	RTS

;*****************************************************************************************
; Subroutines for RGB LEDs
;*****************************************************************************************
;*****************************************************************************************
;* Init_RGB_Lib - initializes Ports P for RGB LED's
;*****************************************************************************************
Init_RGB_Lib:
	BSET	DDRP, $70	; PP4 - PP6: outputs
	BCLR	PTP, $70		; PP4 - PP6: "0"; RGB LEDs -> OFF
	RTS

;*****************************************************************************************
;* Set_RGB_Lib - turns on RGB LED's with the value in ACCA
;*****************************************************************************************
Set_RGB_Lib:
	PSHD			; save the value of ACCD onto the stack

	; move the lower 4 bits to upper 4bits
	LSLA			; << 1 
	LSLA			; << 2
	LSLA			; << 3
	LSLA			; << 4
	
	; save with values of PTP
	LDAB	PTP		; B <- PTP
	ANDB	#$0F		; remove the upper 4 bits in ACCB
	ABA			; A <- A + B
	STAA	PTP		; PTP <- A
	
	PULD			; restore the value of ACCD
	RTS

;*****************************************************************************************
;* Change_RGB_Color_Lib - turns on RGB LED's with the value in ACCA
;*****************************************************************************************
Change_RGB_Color_Lib:
	PSHA			; save the value of ACCA onto the stack
	LDAA	PTP		; A <- PTP
	ADDA	#$10		; Add 1 to PP4 - PP6
	STAA	PTP		;
	PULA			; restore the value of ACCA
	RTS

;*****************************************************************************************
;* Turn_Off_Seven_Seg_Lib - turns off 7-segment display LEDs
;*****************************************************************************************
Turn_Off_Seven_Seg_Lib:
	; turn off 7-segment LED display
	BSET	DDRP, $0F	; PP0 - PP3: outputs
	BSET	PTP, $0F		; Digit #0 - #3: OFF
	RTS

;*****************************************************************************************
;* Init_Seven_Seg_LEDs - initializes hardware for 7-segment LEDs
;*****************************************************************************************
Init_Seven_Seg_LEDs:	
	; set Port B
	MOVB	#$FF, DDRB	; PTB7 - PTB0 = 1 -> outputs
	MOVB	#$00, PORTB	; PTB7 - PTB0 = 0 -> all 7-seg LEDs are OFF
	
	; set Port J1
	BSET	DDRJ, $02	; PTJ1 = 1 -> output
	BSET	PTJ, $02		; PTJ1 = 1, all LEDS are OFF

	; set Port P
	BSET	DDRP, $0F	; PTP3 - PTP0 = 1 -> outputs
	BSET	PTP, $0F		; PTP3 - PTP0 = 1 -> 4 7-seg LEDs are OFF	
	RTS

;*****************************************************************************************
; Subroutines for lab#2
;*****************************************************************************************
;*****************************************************************************************
; Subroutine Set_Prompt_Lib - sets a message prompt on LCD
;*****************************************************************************************
Set_Prompt_Lib: 
	LDAA	#MSG_POS_LIB	;
	JSR	Set_Position_Lib	;
	LDX	#Msg_prompt_Lib	;
	JSR	Display_Msg_Lib	;	  
	RTS
;*****************************************************************************************
; Subroutine Clear_Num_Lib - clears the positions for displaying the key pressed on LCD
;*****************************************************************************************
Clear_Num_Lib:
	PSHD			; save value of D onto the stack
	LDAA	#NUM_POS_LIB	;
	JSR	Set_Position_Lib	;
	LDAA	#$20		; 'space' character
	JSR	Display_Char_Lib	;
	JSR	Display_Char_Lib	;
	LDAA	#NUM_POS_LIB	;
	JSR	Set_Position_Lib;
	PULD			; restore the value of D	
	RTS

;*****************************************************************************************
; Subroutine Display_Xten_Lib - displays the tenth digit
;*****************************************************************************************
Display_Xten_Lib:
	PSHD			; save the value of ACCD onto the stack
	TAB			; save the value of ACCA in ACCB
	LDAA	#XTEN_POS_LIB	; set the postion for the tenth digit
	JSR	Set_Position_Lib	;
	LDX	#Xten_Msg_Lib	; display the tenth digit
	JSR	Display_Msg_Lib	;
	TBA			;
	JSR	Display_Char_Lib	;
	PULD			; restore the value of ACCD
	RTS
;*****************************************************************************************
; Subroutine Display_Xunit_Lib - displays the unit digit
;*****************************************************************************************
Display_Xunit_Lib:
	PSHD			; save the value of ACCD onto the stack
	TAB			; save the value of ACCA in ACCB
	LDAA	#XUNIT_POS_LIB	; set the postion for the unit digit
	JSR	Set_Position_Lib	;
	LDX	#Xunit_Msg_Lib	; display the unit digit
	JSR	Display_Msg_Lib	;
	TBA
	JSR	Display_Char_Lib	;
	PULD			; restore the value of ACCD
	RTS

;*****************************************************************************************
; Subroutine Read_Two_Key_Lib - reads two BCD keys from the keypad into ACCA
;*****************************************************************************************
Read_Two_Key_Lib:
	LEAS	-1, SP		; local variable of 1 byte  
	
	; set position for number	
	LDAA	#NUM_POS_LIB	;
	JSR	Set_Position_Lib	;
	JSR	Set_Blink_ON_Lib	;
	
	; read the first BCD digit
	JSR	Read_One_BCD_Lib; read 1 BCD key
	
	; move to upper 4 bits
	SUBA	#ASCII_CONVERT_LIB;
	LSLA
	LSLA
	LSLA
	LSLA
	STAA	0, SP		; save the digit to local variable
	
	; read the second BCD digit
	JSR	Read_One_BCD_Lib; read 1 BCD key
	
	; remove the upper 4 bits 
	SUBA	#ASCII_CONVERT_LIB;
	ORAA	0, SP		;

	; turn blink off	
	JSR	Set_Blink_OFF_Lib;
	
	LEAS	1, SP		; de-allocate the local variable
	RTS
	
;*****************************************************************************************
; Subroutines for key pad
;*****************************************************************************************
;******************************************************************************************
; Subroutine Init_Keypad_Lib - initalizes the keypad
;******************************************************************************************
Init_Keypad_Lib:
	MOVB	#$0F, DDRA	; pins PA7~PA4 for input, pins PA3~PA0 for output
	BSET	PUCR, mPUCR_PUPAE	; enable port A pull-up resistors
	RTS

;*****************************************************************************************
; Subroutine Read_One_BCD_Lib - reads one BCD key from the keypad into ACCA
;*****************************************************************************************
Read_One_BCD_Lib:	 
	JSR	Scan_Keypad_Lib	; read a key from the keypad
	
	; check for a valid BCD < '0' or > '9'
	CMPA	#ASCII_ZERO_LIB	;
	BLO	Read_One_BCD_Lib	;
	CMPA	#ASCII_NINE_LIB	;
	BHI	Read_One_BCD_Lib;
	
	; display the BCD key
	JSR	Display_Char_Lib;
	RTS

;*****************************************************************************************
; Subroutine Read_Two_BCDs_Lib - reads two BCD keys from the keypad into ACCA
;*****************************************************************************************
Read_Two_BCDs_Lib:
	LEAS	-1, SP		; local variable of 1 byte  
	
	; read the first BCD digit
	JSR	Read_One_BCD_Lib; read 1 BCD key
	
	; move to upper 4 bits
	SUBA	#ASCII_CONVERT_LIB;
	LSLA
	LSLA
	LSLA
	LSLA
	STAA	0, SP		; save the digit to local variable
	
	; read the second BCD digit
	JSR	Read_One_BCD_Lib; read 1 BCD key
	
	; remove the upper 4 bits 
	SUBA	#ASCII_CONVERT_LIB;
	ORAA	0, SP		;
	
	LEAS	1, SP		; de-allocate the local variable
	RTS

;*****************************************************************************************
; Subroutine Scan_Keypad_Lib - scans the whole keypad for a key press
;*****************************************************************************************
Scan_Keypad_Lib:
	PSHB			; save ACCB onto the stack
	PSHX			; save IX onto the stack
	PSHY			; save IY onto the stack
Scan_Keypad_Lib_Again:
	JSR	PA0_Col_0_Lib	; PA0 = 0, scan the rows
	CPX	#$01		; check the flag
	BEQ	End_Read_Lib	;
	JSR	PA1_Col_1_Lib	; PA1 = 0, scan the rows
	CPX	#$01		; check the flag
	BEQ	End_Read_Lib	;
	JSR	PA2_Col_2_Lib	; PA2 = 0, scan the rows
	CPX	#$01		; check the flag
	BEQ	End_Read_Lib	;
	JSR	PA3_Col_3_Lib	; PA3 = 0, scan the rows
	CPX	#$01		; check the flag
	BEQ	End_Read_Lib	;
	BRA	Scan_Keypad_Lib_Again
End_Read_Lib:
	PULY			; restore the value of IY
	PULX			; restore the value of IX
	PULB			; restore the value of ACCB
	RTS

;*****************************************************************************************
; Subroutine Read_PortA_Lib - reads from Port A and implements debouncing key 
;	press
;*****************************************************************************************
Read_PortA_Lib:
	SEI	
	PSHY			; save the value of IY onto the stack
	LEAS	-2, SP		; allocate a local variable
	LDX	#$00		; reset the flag (IX)
	LDAA	PORTA		; read from Port A
	STAA	1, SP		; save ACCA into the local variable
	BRSET	1, SP, $F0, No_Key_Lib	; check for a low value (a key pressed)

	LDY	#1		; add 10ms delay for
	JSR	Delay10ms	; debouncing the switch
	
	LDAB	PORTA		; read from Port A
	CBA			; compare ACCA and ACCB
	BNE	No_Key_Lib	;
	
	LDX	#$01		; set the flag
	
	LDY	#21		; add 210ms delay for
	JSR	Delay10ms	; debouncing the switch
	BRA	Done_Read_PortA	;

No_Key_Lib:
	LDAA	#NULL_LIB	; set NULL character to ACCA
	
Done_Read_PortA:
	LEAS	+2, SP		; deallocate a local variable
	PULY			; restore the value of IY
	CLI
	RTS
;*****************************************************************************************
; Subroutine PA0_Col_0_Lib - scans column 0
;*****************************************************************************************
PA0_Col_0_Lib:
	LEAS	-2, SP		; allocate a local variable
	
	MOVB	#$FE, PORTA	; PA0 = 0, PA1-PA7 = 1
	JSR	Read_PortA_Lib	;
	
	CPX	#$01		; check the flag
	BNE	PA0_done	;
	
	STAA	1, SP	; save ACCA into the local variable
	
	BRCLR	1, SP, mPORTAD0_PTAD4, PA0_key0	; check for key 0
	BRCLR	1, SP, mPORTAD0_PTAD5, PA0_key4	; check for key 4
	BRCLR	1, SP, mPORTAD0_PTAD6, PA0_key8	; check for key 8
	BRCLR	1, SP, mPORTAD0_PTAD7, PA0_key12	; check for key 12
	BRA	PA0_done	;
PA0_key0:
	LDAA	#$31		;  key 0 ('1') is pressed
	BRA	PA0_done		; 
PA0_key4:
	LDAA	#$34		;  key 4 ('4') is pressed
	BRA	PA0_done		;
PA0_key8:
	LDAA	#$37		;  key 8 ('7') is pressed
	BRA	PA0_done		;
PA0_key12:
	LDAA	#$2A		;  key 12 ('*') is pressed		
PA0_done:
	LEAS	+2, SP		; deallocate a local variable
	RTS
;*****************************************************************************************
; Subroutine PA1_Col_1_Lib - scans column 1
;*****************************************************************************************
PA1_Col_1_Lib:
	LEAS	-2, SP		; allocate a local variable
	
	MOVB	#$FD, PORTA	; PA1 = 0, PA0, PA2-PA7 = 1
	JSR	Read_PortA_Lib	;
	
	CPX	#$01		; check the flag
	BNE	PA1_done	;
	
	STAA	1, SP		; save ACCA into the local variable
	
	BRCLR	1, SP, mPORTAD0_PTAD4, PA1_key1	; check for key 1
	BRCLR	1, SP, mPORTAD0_PTAD5, PA1_key5	; check for key 5
	BRCLR	1, SP, mPORTAD0_PTAD6, PA1_key9	; check for key 9
	BRCLR	1, SP, mPORTAD0_PTAD7, PA1_key13	; check for key 13
	BRA	PA1_done	;
PA1_key1:
	LDAA	#$32		;  key 1 ('2') is pressed
	BRA	PA1_done		; 
PA1_key5:
	LDAA	#$35		;  key 5 ('5') is pressed
	BRA	PA1_done		;
PA1_key9:
	LDAA	#$38		;  key 9 ('8') is pressed
	BRA	PA1_done		;
PA1_key13:
	LDAA	#$30		;  key 13 ('0') is pressed		
PA1_done:
	LEAS	+2, SP		; deallocate a local variable
	RTS
;*****************************************************************************************
; Subroutine PA2_Col_2_Lib - scans column 2
;*****************************************************************************************
PA2_Col_2_Lib:
	LEAS	-2, SP		; allocate a local variable
	
	MOVB	#$FB, PORTA	; PA2 = 0, PA0, PA1, PA3-PA7 = 1
	JSR	Read_PortA_Lib	;
	
	CPX	#$01		; check the flag
	BNE	PA2_done	;
	
	STAA	1, SP	; save ACCA into the local variable
	
	BRCLR	1, SP, mPORTAD0_PTAD4, PA2_key2	; check for key 2
	BRCLR	1, SP, mPORTAD0_PTAD5, PA2_key6	; check for key 6
	BRCLR	1, SP, mPORTAD0_PTAD6, PA2_key10	; check for key 10
	BRCLR	1, SP, mPORTAD0_PTAD7, PA2_key14	; check for key 14
	BRA	PA2_done	;
PA2_key2:
	LDAA	#$33		;  key 2 ('3') is pressed
	BRA	PA2_done	; 
PA2_key6:
	LDAA	#$36		;  key 6 ('6') is pressed
	BRA	PA2_done	;
PA2_key10:
	LDAA	#$39		;  key 10 ('9') is pressed
	BRA	PA2_done	;
PA2_key14:
	LDAA	#ASCII_POUND_LIB;  key 14 ('#') is pressed		
PA2_done:
	LEAS	+2, SP		; deallocate a local variable
	RTS
;*****************************************************************************************
; Subroutine PA3_Col_3_Lib - scans column 3
;*****************************************************************************************
PA3_Col_3_Lib:
	LEAS	-2, SP		; allocate a local variable
	
	MOVB	#$F7, PORTA	; PA3 = 0, PA0-PA2, PA4-PA7 = 1
	JSR	Read_PortA_Lib	;
	
	CPX	#$01		; check the flag
	BNE	PA3_done		;
	
	STAA	1, SP	; save ACCA into the local variable
	
	BRCLR	1, SP, mPORTAD0_PTAD4, PA3_key3	; check for key 3
	BRCLR	1, SP, mPORTAD0_PTAD5, PA3_key7	; check for key 7
	BRCLR	1, SP, mPORTAD0_PTAD6, PA3_key11	; check for key 11
	BRCLR	1, SP, mPORTAD0_PTAD7, PA3_key15	; check for key 15
	BRA	PA3_done	;
PA3_key3:
	LDAA	#$41		;  key 3 ('A') is pressed
	BRA	PA3_done	; 
PA3_key7:
	LDAA	#$42		;  key 7 ('B') is pressed
	BRA	PA3_done	;
PA3_key11:
	LDAA	#$43		;  key 11 ('C') is pressed
	BRA	PA3_done	;
PA3_key15:
	LDAA	#$44		;  key 15 ('D') is pressed		
PA3_done:
	LEAS	+2, SP		; deallocate a local variable
	RTS
	
;*****************************************************************************************
; Subroutines for LCD
;*****************************************************************************************
;*****************************************************************************************
;* Init_PortK_Lib - initializes port K for LCD display
;*****************************************************************************************
Init_PortK_Lib:	
	MOVB	#$FF, DDRK	; PK0 - PK7 are output pins
	CLR	PORTK		; clear the outputs
 	RTS		 
;*****************************************************************************************
;* Clear_Display_Lib - clears the LCD
;*****************************************************************************************
Clear_Display_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	LDAA	#$01		; Clear the display
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of the command
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of the command
	LDY	#5		;
	JSR	Delay1ms	; wait for 5ms
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
;* Display_Msg_Lib - displays the message
;*****************************************************************************************
Display_Msg_Lib:
	PSHA			; save ACCA onto the stack
	PSHX			; save IX onto the stack	 
Display_again_Lib:
	LDAA	1, X+		; A <- ASCII data
	CMPA	#$00		; check for the end of the string
	BEQ	Display_end_Lib	;		  
	JSR	Display_Char_Lib;
	BRA	Display_again_Lib;
Display_end_Lib:
	PULX			; restore the value of IX
	PULA			; restore the value of ACCA
	RTS
;*****************************************************************************************
;* Display_Char_Lib - writes an ASCII value in ACCA to LCD
;*****************************************************************************************
Display_Char_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	JSR	SplitNum_Lib	;
	JSR	WriteData_Lib	; write upper 4 bits of ASCII byte
	TBA
	JSR	WriteData_Lib	; write lower 4 bits of ASCII byte
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
;* Set_Blink_ON_Lib - sets the blink on at the character indicated by ACCA
;*****************************************************************************************
Set_Blink_ON_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	LDAA	#$0D		; Display ON, cursor OFF, blink ON
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of the command
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of the command
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS

;*****************************************************************************************
;* Set_Blink_OFF_Lib - sets the blink off
;*****************************************************************************************
Set_Blink_OFF_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	LDAA	#$0C		; Display ON, cursor OFF, blink OFF
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of the command
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of the command
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS
	
;*****************************************************************************************
;* Set_Position_Lib - sets the position for displaying data in LCD
;*****************************************************************************************
Set_Position_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	ORAA	#$80		; set b7 of ACCA
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of the command
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of the command
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
;* WriteData_Lib - sends a data (lower 4 bits) in ACCA to LCD
;*****************************************************************************************
WriteData_Lib:  
	ANDA	#$0F		; mask the upper 4 bits of ACCA
	LSLA			;
	LSLA			; data from bits 2 - 5
	ORAA	#$03		; keep RS = 1, and E = 1 in ACCA
	STAA	PORTK		; send to LCD
	BSET	PORTK, EN_LIB	; E = 1 for high pulse (PK1)
	NOP			; make a pulse of of 250ns wide
	NOP			; for EN_LIB pulse
	NOP			; 
	BCLR	PORTK, EN_LIB	; E = 0 for H-L pulse (PK1)
	RTS		
;*****************************************************************************************
;* WriteCMD_Lib - sends a command (lower 4 bits) in ACCA to LCD
;*****************************************************************************************
WriteCMD_Lib:   
	ANDA	#$0F		; mask the upper 4 bits of ACCA
	LSLA			; 
	LSLA			; data from bits 2 - 5
				; RS = 0 for command (PK0), R/W = 0 for writing (PK7)
	ORAA	#EN_LIB		; maintain E signal
	STAA	PORTK		; send to LCD
	BSET	PORTK, EN_LIB	; E = 1 for high pulse (PK1)
	NOP			; make a pulse of of 250ns wide
	NOP			; for EN_LIB pulse
	NOP			; 
	BCLR	PORTK, EN_LIB	; E = 0 for H-L pulse (PK2)
	RTS
;*****************************************************************************************
; SlipNum - separates hex numbers in ACCA
;	  ACCA <- MS digit
;	  ACCB <- LS digit
;*****************************************************************************************
SplitNum_Lib:   
	TAB			; keep a copy of A in B
	ANDB	#$0F		; mask the upper 4 bits
	LSRA			;
	LSRA			;
	LSRA			;
	LSRA			;
	RTS
;*****************************************************************************************
;* Init_LCD_Lib - initializes LCD according to the initializing sequence indicated
;	  by the manufacture
;*****************************************************************************************
Init_LCD_Lib:
	PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack

	JSR	Init_PortK_Lib	; initializing Port K
			   
	LDY	#30		;
	JSR	Delay1ms	; wait 30ms for LCD to power up
	
	; send byte 1 of code to LCD
	LDAA	#$30		; A <- byte #1 of code: $30
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write byte #1
	LDY	#5		;
	JSR	Delay1ms		; wait for 5 ms
	
	; send byte 2 of code to LCD
	LDAA	#$30		; A <- byte #2 of code: $30
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write byte #2
	LDY	#3		;
	JSR	Delay50us	; wait for 150us
	
	; send byte 3 of code to LCD
	LDAA	#$30		; A <- byte #3 of code: $30
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write byte #3
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	
	; send byte 4 of code to LCD
	LDAA	#$20		; A <- byte #4 of code: $20
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write byte #4
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	
	; send byte 5 of code to LCD
	LDAA	#$28		; A <- byte #5 of code: $28
				;  db5 = 1, db4 = 0 (DL = 0 - 4 bits), 
				;  db3 = 1 (N = 1 - 2 lines),
				;  db2 = 0 (F = 0 - 5x7 dots).
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of byte #5
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of byte #5
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	
	; send byte 6 of code to LCD
	LDAA	#$0C		; A <- byte #6 of code: $0C
				;  db3 = 1, db2 = 1 (D = 1 - display ON)
				;  db1 = 0 (C = 1 - cursor ON)
				;  db0 = 0 (B = 1 - blink ON)
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of byte #6
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of byte #6
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	
	; send byte 7 of code to LCD
	LDAA	#$06		; A <- byte #7 of code: $06
				;  db2 = 1,
				;  db1 = 1 (I/D = 1 - increment cursor)
				;  db0 = 0 (S = 0 - no display shift)
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of byte #7
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of byte #7
	LDY	#1		;
	JSR	Delay50us	; wait for 50us
	
	; send byte 8 of code to LCD
	LDAA	#$01		; A <- byte #8 of code: $01
				;  db0 = 1 (clears display and returns
				;	the cursor home).		 
	JSR	SplitNum_Lib	;
	JSR	WriteCMD_Lib	; write upper 4 bits of byte #8
	TBA
	JSR	WriteCMD_Lib	; write lower 4 bits of byte #8
	LDY	#3		;
	JSR	Delay1ms	; wait for 3ms
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS

;*****************************************************************************************
; Subroutines for delay
;*****************************************************************************************
;*****************************************************************************************
; Author: Dr. Han-Way Huang
; Date: 07/18/2004
; Organization: Minnesota State University, Mankato
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 10 us. The value passed in Y specifies the number of 10us to be
; delayed.
;*****************************************************************************************
Delay10us:  
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB	#$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$02, TSCR2	; configure prescale factor to 4 (clock count = 24MHz/4 = 6MHz)
	;MOVB	#$01, TIOS	; enable OC0 for output
	LDD	TCNT		; get the current time
Again_10us_Lib:
	ADDD	#4		; start an output compare operation:
				; 10us = 4 * 64/ 24 MHz
	STD 	TC0	 	; set TC0 for 50us delay

	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0	 	; load TC0 for the next loop
	DBNE	Y, Again_10us_Lib	;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 50 us. The value passed in Y specifies the number of 50us to be
; delayed.
;*****************************************************************************************
Delay50us:  
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB	#$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$02, TSCR2	; configure prescale factor to 4 (clock count = 24MHz/4 = 6MHz)
	;MOVB	#$01, TIOS	; enable OC0 for output
	LDD	TCNT		; get the current time
Again_50us_Lib:
	ADDD	#19		; start an output compare operation:
				; 50us = 18.75 * 64/ 24 MHz
	STD 	TC0	 	; set TC0 for 50us delay

	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0	 	; load TC0 for the next loop
	DBNE	Y, Again_50us_Lib	;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 100 us. The value passed in Y specifies the number of 100us to be
; delayed.
;*****************************************************************************************
Delay100us:  
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB	#$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$02, TSCR2	; configure prescale factor to 4 (clock count = 24MHz/4 = 6MHz)
	;MOVB	#$01, TIOS	; enable OC0 for output
	LDD	TCNT		; get the current time
Again_100us_Lib:
	ADDD	#38		; start an output compare operation:
				; 100us = 38 * 64/ 24 MHz
	STD 	TC0	 	; set TC0 for 50us delay

	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0	 	; load TC0 for the next loop
	DBNE	Y, Again_100us_Lib;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 1ms. The value passed in Y specifies the number of 1 milliseconds to be
; delayed.
;*****************************************************************************************
Delay1ms:
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB	#$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$06, TSCR2	; configure prescale factor to 64 (clock count = 24MHz/64)
	;MOVB	#$01, TIOS	; enable OC0
	LDD 	TCNT
Again_1ms_Lib:
	ADDD	#375		; start an output compare operation
				;	1ms = 375 * 64 / 24Mhz
	STD	TC0		; with 1ms time delay
	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0	 	; load TC0 for the next loop 
	DBNE	Y, Again_1ms_Lib	;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 10ms. The value passed in Y specifies the number of 10 milliseconds
; to be delayed.
;*****************************************************************************************
Delay10ms:  
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB  #$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$06, TSCR2	; configure prescale factor to 64 (clock count = 24MHz/64)
	;MOVB	#$01, TIOS	; enable OC0
	LDD	TCNT
Again_10ms_Lib:
	ADDD	#3750		; start an output compare operation
				;	10ms = 3750 * 64 / 24MHz
	STD	TC0		; with 10ms time delay
	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0		; load TC0 for the next loop
	DBNE	Y, Again_10ms_Lib	;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS
;*****************************************************************************************
; The following function creates a time delay which is equal to the multiple
; of 100ms. The value passed in Y specifies the number of 100 milliseconds
; to be delayed.
;*****************************************************************************************
Delay100ms:
	PSHD			; save ACCD onto the stack
	PSHY			; save IY onto the stack
	PSHC			; save CCR onto the stack
	;MOVB	#$90, TSCR1	; enable TCNT (TEN) & fast flag clear (TFFCA)
	;MOVB	#$06, TSCR2	; configure prescale factor to 64 (clock count = 24MHz/64)
	;MOVB	#$01, TIOS	; enable OC0
	LDD	TCNT
Again_100ms_Lib:
	ADDD	#37500		; start an output compare operation
				;	100ms = 37500 * 64 / 24MHz
	STD	TC0		; with 100ms time delay
	BRCLR	TFLG1, mTFLG1_C0F, *	; wait until C0F is set
	LDD	TC0	 	; load TC0 for the next loop
	DBNE	Y, Again_100ms_Lib	;
	PULC			; restore CCR
	PULY			; restore IY
	PULD			; Restore the value of ACCD
	RTS	 

;*****************************************************************************************
;* Delay1s - creates a delay of 1 second
;*****************************************************************************************	
Delay1s:PSHD			; save ACCD onto the stack
	PSHY			; Save IY onto the stack
	LDY	#10
	JSR	Delay100ms	;
	PULY			; Restore the value of IY
	PULD			; Restore the value of ACCD
	RTS
	
;*****************************************************************************************
; Utility Subroutines
;*****************************************************************************************
;*****************************************************************************************
;  Subroutine Hex2ASCII_Lib - converts the binary value in ACCA into two ASCII 
;	chars with the hex value of the byte: 
;		ACCA <-- MS digit
;		ACCB <-- LS digit
;*****************************************************************************************
Hex2ASCII_Lib:
	TAB			; copy byte to ACCB
	ANDB	#$0F		; ACCB has low nibble
	CMPB	#$0A		; compare with 10
	BLT	ASCII_skip1_Lib	; if less to ASCII_skip1_Lib
	ADDB	#$07		; otherwise add 7
ASCII_skip1_Lib:
	ADDB	#$30		; convert to ASCII
	
	LSRA			; move 
	LSRA			; the high nibble
	LSRA			; into the low
	LSRA		 	; nibble
	CMPA	#$0A		; compare with 10
	BLT	ASCII_skip2_Lib	; if less to ASCII_skip2_Lib
	ADDA	#$07		; otherwise add 7
ASCII_skip2_Lib:
	ADDA	#$30		; convert to ASCII
	RTS			; return to program

;*****************************************************************************************
; Subroutine ASCII2Hex_Lib - converts the ASCII value (digit and Hex) into its hexadecimal
;	number
;*****************************************************************************************
ASCII2Hex_Lib:
	SUBA	#$30		; subtract the base alpha
	CMPA	#$0A		;
	BLO	ASCII2Hex_Lib_done;
	SUBA	#$07		; subtract the offset for alpha character
ASCII2Hex_Lib_done:
	RTS

;******************************************************************************************
; String_ASCII_BCD2Hex_Lib - converts a string of ASCII BCD digit into Hex equivalent number. 
;	The string is in IX with NULL termination, and the result will be in ACCD.
;******************************************************************************************
String_ASCII_BCD2Hex_Lib:
	PSHX
	PSHY
	LDY	#$00		; clear IY
	LDD	#$00		; clear D
String_ASCII_BCD2Hex_Lib_Again:
	LDAB	1, X+		; B <-- digit in the string
	CMPB	#NULL_LIB	;
	BEQ	End_String_ASCII_BCD2Hex_Lib	;
	SUBB	#$30		; convert to decimal digit
	ABY			; IY <-- IY + B
	TFR	Y, D		; D <-- IY
	TST	0, X		; check the next digit in the string before multiplying by
				; 10
	BEQ	End_String_ASCII_BCD2Hex_Lib	;
	LDY	#TEN_LIB		; IY <- 10
	EMUL			; D * Y --> Y:D
	TFR	D, Y		; IY <-- D
	BRA	String_ASCII_BCD2Hex_Lib_Again
End_String_ASCII_BCD2Hex_Lib:	
	PULY
	PULX
	RTS

;******************************************************************************************
; Subroutine Hex2DecChar_Lib - converts a hex number in D to ASCII characters, pointed by
;	IY, the length of the buffer is in IX.
;******************************************************************************************
Hex2DecChar_Lib
	PSHD			; save D onto the stack
	PSHX			; save IX onto the stack
	PSHY			; save IY onto the stack
	
	LEAS	-2, SP		; allocate local variables
	XGDX			; IX <-> D
	DECB			; B <- Size of buffer
	
	STAB	1, SP	   ; save the size of the buffer into local variable
	LEAY	B, Y		; set IY to the least significant digit
	XGDX			; IX <-> D
	MOVB	#$00, 1, Y-	; add NULL terminator character

Hex2DecChar_Repeat:
 	LDX	#TEN_LIB	; IX <- 10	
	IDIV			; D / IX, IX <- quotient, D <- remander
	ADDB	#$30		; convert to ASCII
	STAB	1, Y-		; save it in result buffer
	DEC	1, SP
	BEQ	Hex2DecChar_done;
	TFR	X, D		; D <- quotient (IX)
	TSTB			; 
	BNE	Hex2DecChar_Repeat;

Hex2DecChar_done:
	LDAB	1, SP		; B <- extra spaces in the buffer
	CMPB	#$00
	BLS	Hex2DecChar_Lib_Unstack	

Hex2DecChar_Lib_Add_Space:	
	MOVB	#SPACE_LIB, 1,Y-; adding ' ' character
	DBNE	B, Hex2DecChar_Lib_Add_Space

Hex2DecChar_Lib_Unstack:
	LEAS	2, SP		; deallocate local variables
	PULY			; restore the value of IY
	PULX			; restore the value of IX
	PULD			; restore the value of D
	RTS

;*************************************************************************************************
; Subroutine Clear_Buffer_Lib - clears the buffer, pointed by IY, 
;	the length of the buffer is in ACCB
;*************************************************************************************************
Clear_Buffer_Lib:
	PSHD			; save the content of D onto the stack
	PSHX			; save the content of IX onto the stack
	LEAX	B, X		; IX <- effective address
	MOVB	#NULL_LIB, 1,-X	; set the NULL terminator
	DECB			; decrement index

Clear_Buffer_Again:
	MOVB	#SPACE_LIB, 1,-X;
	DBNE	B, Clear_Buffer_Again;

Clear_Buffer_Done:	
	PULX			; restore the content of IX
	PULD			; restore the content of D
	RTS	

;*****************************************************************************************
;*		Interrupt Vectors		  *
;*****************************************************************************************
	ORG	Vtimch2
	DC.W	OC2_ISR
