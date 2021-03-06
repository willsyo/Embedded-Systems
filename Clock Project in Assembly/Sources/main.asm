;************************************************************************
; Author: Tyler Willis		  CPEN 231L  
; Project: Lab10			
; Program: Digital Clock with External IRQ Interrupt	
; Date Created: 11/28/2016
; Last Modified: 11/28/2016			
; Description: This program will count the time starting at zero or an 
; user specified time up until 23:59:59 and then will reset. To change the 
; the user must press SW2 to toggle the hour, SW3 to toggle minutes and 
; SW4 to toggle seconds
; Outputs: Outputs the following on the LCD:
;		   "Pacific time"
;            "HH:MM:SS"  
;*************************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point

; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RS          EQU   mPORTB_BIT0
EN          EQU   mPORTB_BIT1
; variable/data section

 ifdef _HCS12_SERIALMON
            ORG $3FFF - (RAMEnd - RAMStart)
 else
            ORG RAMStart
 endif
 ; Insert here your data definition.
key 		DS.B 1
RFlag		DS.B 1 
TickCtr		DS.B 1
RGB_Count   DS.B 1
hdr_msg     DC.B "Pacific time", 0
colon       DC.B ":", 0
hour_chars		DS.B 2
minute_chars	DS.B 2
second_chars	DS.B 2
TFlag		DS.B 1
UFlag		DS.B 1
TCount		DS.B 1
light_count DS.B 1
Hours		DS.B 1
Minutes		DS.B 1
Seconds		DS.B 1

; code section
            ORG   ROMStart


Entry:
_Startup:
            ; remap the RAM &amp; EEPROM here. See EB386.pdf
 ifdef _HCS12_SERIALMON
            ; set registers at $0000
            CLR   $11                  ; INITRG= $0
            ; set ram to end at $3FFF
            LDAB  #$39
            STAB  $10                  ; INITRM= $39

            ; set eeprom to end at $0FFF
            LDAA  #$9
            STAA  $12                  ; INITEE= $9


            LDS   #$3FFF+1        ; See EB386.pdf, initialize the stack pointer
 else
            LDS   #RAMEnd+1       ; initialize the stack pointer
 endif

            
;**************************************************************
;*                 Initialize Hardware                          
;**************************************************************	

		   	JSR	  Init_Hardware_Lib
		   	JSR	  Init_Switches
		   	JSR   Init_Keypad
		  	JSR	  Init_Port_K
		    JSR   Init_LCD
		    JSR	  Init_Port_E
		    JSR   Init_RGB
		    JSR   Init_Port_B
		    JSR	  Display_hdr
		    JSR   Init_Flags
		    CLI                     ; enable interrupts
		    
;**************************************************************
;*                 Initialize Hardware                          
;**************************************************************	

	main:   JSR   Set_Time			;time is preset to 00:00:00 if not user specified
			JSR   Timer
			JSR	  Update
			JSR	  Display
			BRA   main

;********************************************************************** 
;* SUBROUTINE:  
;**********************************************************************

     Display:
     		;Display Hours
	    	LDAA  #$44  		    ;load position 5 on second line on lcd into register A
	    	JSR   Set_Position    	;set position on lcd 
	    	LDAA  Hours		    	;Load the variable Hour into register A and isolate the first digit
	    	LSRA
	    	LSRA
	    	LSRA
	    	LSRA
	    	ADDA  #$30
	    	JSR   Display_Char    	;Dislplay the first digit in Hour
	    	LDAA  #$45
	    	JSR   Set_Position
	    	LDAA  Hours
	    	ANDA  #$0F
	    	ADDA  #$30
	    	JSR   Display_Char    	;Display the second digit in Hour
	    	LDAA  #$46
	    	JSR   Set_Position
	    	LDAA  #$3A		    	;Load and display a colon ':'
	    	JSR   Display_Char
	    	
	    	;Display Minutes
	    	LDAA #$47  		    ;load position 6 on second line on lcd into register A
	    	JSR Set_Position    ;set position on lcd 
	   	 	LDAA Minutes		    ;Load the variable Minute into register A and isolate the first digit
	    	LSRA
	    	LSRA
	    	LSRA
	    	LSRA
	    	ADDA #$30
	    	JSR Display_Char    ;Dislplay the first digit in Minute
	    	LDAA #$48
	    	JSR Set_Position
	    	LDAA Minutes
	    	ANDA #$0F
	    	ADDA #$30
	    	JSR Display_Char    ;Display the second digit in Minute
	    	LDAA #$49
	    	JSR Set_Position
	    	LDAA #$3A		    ;Load and display a colon ':'
	    	JSR Display_Char
	    
	        ;Display Seconds
	    	LDAA #$4A  		    ;load position 6 on second line on lcd into register A
	    	JSR Set_Position    ;set position on lcd 
	    	LDAA Seconds   	    ;Load the variable Minute into register A and isolate the first digit
	    	LSRA
	    	LSRA
	    	LSRA
	    	LSRA
	    	ADDA #$30
	    	JSR Display_Char    ;Dislplay the first digit in Minute
	    	LDAA #$4B
	    	JSR Set_Position
	    	LDAA Seconds
	    	ANDA #$0F
	    	ADDA #$30
	    	JSR Display_Char    ;Display the second digit in Minute
     		
     		RTS
     		
;********************************************************************** 
;* Interrupt Service Routine: IRQ_INT  
;**********************************************************************

     IRQ_INT:
     		;Increment TickCtr unitl it reaches 20
     		INC  TickCtr
     		LDAA TickCtr
     		CMPA #20
     		BLO  end_interrupt
   			;reset TickCtr and set the TFlag
   			CLR  TickCtr
   			LDAA #1
   			STAA TFlag
   			
  end_interrupt:  		
			RTI		;return from interrupt
			
;********************************************************************** 
;* SUBROUTINE: Update, will update hours, seconds, and minutes and loop
;* back to zero upon reaching 23:59:59 
;**********************************************************************

      Update:
      		LDAA  UFlag
      		CMPA  #1
      		BLO   end_update
      		CLR   UFlag
      		;update seconds
      		LDAA  Seconds
      		ADDA  #1
      		DAA  
      		STAA  Seconds
      		CMPA  #$60
    	    LBNE  end_update     ;Check the Zero bit in CCR and branch if it set
    	    CLR   Seconds	     ;Set seconds back to zero
    	    LDAA  Minutes
    	    ADDA  #1
    	    DAA
    	    STAA  Minutes
      		;update minutes
      		LDAA  Minutes
      		CMPA  #$60
      		LBNE  end_update
      		CLR   Minutes
      		LDAA  Hours
    	    ADDA  #1
    	    DAA
    	    STAA  Hours
    	    ;update hours
    	    LDAA  Hours
    	    CMPA  #$24
	    	LBNE  end_update	;Check the Zero bit in CCR and branch if it set
	    	LDAA  #0
	    	STAA  Hours	    	;Set Hour back to zero	    
      		
end_update: RTS  		

;********************************************************************** 
;* SUBROUTINE: Timer, Shifts the LED position and sets UFlag 
;**********************************************************************
 	   Timer:
 	   		;check to see if TFlag is set
			LDAA  TFlag
			CMPA  #1
			BLO   end_timer
			CLR   TFlag
			;set next LED to high
			MOVB  light_count, PORTB
			LSL   light_count
			;determine if the LEDs have reached the 5th posiiton yet
			LDAA  light_count
			CMPA  #$16
			BNE   dnt_clr
			CLR   light_count	 ;reset light_count if at 5th position
			INC   light_count
			;Increment TCount and update other variables if TCount>=5
   dnt_clr:	INC   TCount	
   			LDAA  TCount
   			CMPA  #5
   			BHS   update_vars
   			BRA   end_timer
update_vars:
			LDAA  #1
			STAA  UFlag
			CLR   TCount
			STAA  light_count			
 end_timer: RTS
			
;************************************************************************* 
;* SUBROUTINE: Set_Time, set an user specified time and stores the values  
;*************************************************************************			

	Set_Time:
			;end the subroutine if none of the Switches are pressed
			BRSET PTH, $0E, end_time1

			SEI	  ;disable maskable interrupts
			
			CLR	  TickCtr
			CLR	  RGB_Count
			;Determine what the user wants to toggle	
			BRCLR PTH, $08, Set_Hour
			BRCLR PTH, $04, Set_Minute
			BRCLR PTH, $02, Set_Second
			
	Set_Hour:
			;Display characters as they are typed
			LDX   #hour_chars
			LDAA  #$44
			JSR   Set_Position
			JSR   Set_Blink_ON
			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  0, X		   ;store the character
			;convert the first digit to BCD
			SUBA  #$30
			LSLA
			LSLA
			LSLA
			LSLA
			STAA  Hours		   ;store the BCD digit
			;Display characters as they are typed
			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  1, X		   ;store the character
			JSR   Set_Blink_OFF
			SUBA  #$30
			ADDA  Hours
			DAA
			STAA  Hours
			
			LDX   #colon
			JSR   Display_Msg
			
			BRA   end_time	
			
 end_time1: BRA   end_time2	
 		
  Set_Minute:		
			LDX   #minute_chars
			LDAA  #$47
			JSR   Set_Position
			JSR   Set_Blink_ON
			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  0, X
			SUBA  #$30
			LSLA
			LSLA
			LSLA
			LSLA
			STAA  Minutes

			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  1, X
			JSR   Set_Blink_OFF
			SUBA  #$30
			ADDA  Minutes
			DAA
			STAA  Minutes
			
			LDX   #colon
			JSR   Display_Msg
			
			BRA   end_time

  Set_Second:
			LDX   #second_chars
			LDAA  #$4A
			JSR   Set_Position
			JSR   Set_Blink_ON
			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  0, X
			SUBA  #$30
			LSLA
			LSLA
			LSLA
			LSLA
			STAA  Seconds

			JSR	  Scan_Keypad
			JSR	  Display_Char
			STAA  1, X
			JSR   Set_Blink_OFF
			SUBA  #$30
			ADDA  Minutes
			DAA
			STAA  Minutes
			
	end_time:
			CLI
   end_time2:		
			RTS			

;********************************************************************** 
;* SUBROUTINE:  
;**********************************************************************
Init_Flags:
			CLR  TFlag
			CLR  UFlag
			CLR  TickCtr
			CLR  TCount
			CLR  Hours
			CLR  Minutes
			CLR  Seconds
			LDAA #$01
			STAA light_count
			;Set the time to all zeros
			LDX	 #hour_chars
			CLR  0, X
			CLR  1, X
			LDX  #minute_chars
			CLR  0, X
			CLR  1, X
			LDX  #second_chars
			CLR  0, X
			CLR  1, X
			
			RTS			
;********************************************************************** 
;* SUBROUTINE:  
;**********************************************************************

 Display_hdr:
 			LDX  #hdr_msg
 			LDAA #$02
 			JSR  Set_Position
 			JSR  Display_Msg
 			RTS
				    
;********************************************************************** 
;* SUBROUTINE:  
;**********************************************************************

Init_Port_B:	
			; set Port B for output mode
			MOVB #$FF, DDRB
			; Set PJ1 of port J for output
			; and clear PJ1 to enable LEDs
			BSET DDRJ, mDDRJ_DDRJ1
			BCLR PTJ, mPTIJ_PTIJ1;
			
			; turn off 7-segment display LEDs
			BSET DDRP, $0F ;
			BSET PTP, $0F ;
			
			RTS		    
	
;*********************************************************************** 
;* SUBROUTINE:  
;***********************************************************************

Init_RGB:
 		    BSET DDRP, $70 ; PP6-PP4 = 1 -> outputs
			BCLR PTP, $70  ; PP6-PP4 = 0 -> RGB LEDs: OFF
			RTS
		    			
;**************************************************************
;* SUBROUTINE: Init_Port_E, initializes and configures Port E                          
;**************************************************************

Init_Port_E:
 		    BSET  INTCR, mINTCR_IRQE  ; Falling edge trigger
			BSET  INTCR, mINTCR_IRQEN ; interrupt enabled
			BCLR  PUCR, mPUCR_PUPEE   ; pull-up resistors (Port E) are disabled
			RTS			

;*********************************************************************** 
;* SUBROUTINE: Init_Port_K, initializes PORT K 
;***********************************************************************
			
Init_Port_K:
			MOVB  #$FF, DDRK      ;initialize PORTK
            CLR   PORTK
            RTS
              
;*********************************************************************** 
;* SUBROUTINE: Init_Switches, initializes DIP Switches 
;***********************************************************************
	          
Init_Switches:
			      ; Set Port H for input mode
		    MOVB  #$00, DDRH 
		   	RTS
		   	
Scan_Keypad:

    recheck:JSR   Scan_Col_0      ;scan the first colomn of the keypad
            LDAB  RFlag           ;compare the rflag to see of a value has been read yet
            CMPB  #1
            LBEQ  end_kscan
            JSR   Scan_Col_1      ;scan the second colomn of the keypad
            LDAB  RFlag           ;compare the rflag to see of a value has been read yet
            CMPB  #1
            LBEQ  end_kscan
            JSR   Scan_Col_2      ;scan the third colomn of the keypad
            LDAB  RFlag           ;compare the rflag to see of a value has been read yet
            CMPB  #1
            LBEQ  end_kscan
            JSR   Scan_Col_3       ;scan the fourth colomn of the keypad
            LDAB  RFlag           ;compare the rflag to see of a value has been read yet
            CMPB  #1
            LBNE  recheck         ;if no input scan again
  end_kscan:RTS
            
Scan_Col_0:
            MOVB  #$FE, PORTA     ;set PA0 to low and PA1-PA3 to high
            JSR   Read_PortA      ;scan portA
            
            LDAB  RFlag
            CMPB  #$01             ;Compare RFlag with the value 1 and branch to the end of the subroutine if not equal
            LBNE  end_scan
              
            BRCLR	key, mPORTAD0_PTAD4, set_0	
	          BRCLR	key, mPORTAD0_PTAD5, set_4	
            BRCLR	key, mPORTAD0_PTAD6, set_8
            BRCLR	key, mPORTAD0_PTAD7, set_12
            BRA   end_scan
           
      set_0:LDAA  #$31         ;move the ascii value for "1" into accumulator A
            BRA   end_scan             
      set_4:LDAA  #$34         ;move ascii value for "4" into accumulator A
            BRA   end_scan                                    
      set_8:LDAA  #$37         ;move ascii value for "7" into accumulator A
            BRA   end_scan            
     set_12:LDAA  #$2A         ;move ascii value for "*" into accumulator A                         
   end_scan:RTS
   
Scan_Col_1:
            MOVB  #$FD, PORTA     ;set PA0 to low and PA1-PA3 to high
            JSR   Read_PortA      ;scan portA
            
            LDAB  RFlag
            CMPB  #$01             ;Compare RFlag with the value 1 and branch to the end of the subroutine if not equal
            LBNE  end_scan1
              
            BRCLR	key, mPORTAD0_PTAD4, set_1	
	          BRCLR	key, mPORTAD0_PTAD5, set_5	
            BRCLR	key, mPORTAD0_PTAD6, set_9
            BRCLR	key, mPORTAD0_PTAD7, set_13
            BRA   end_scan1
           
      set_1:LDAA  #$32         ;move the ascii value for "2" into accumulator A
            BRA   end_scan1             
      set_5:LDAA  #$35         ;move ascii value for "5" into accumulator A
            BRA   end_scan1                                    
      set_9:LDAA  #$38         ;move ascii value for "8" into accumulator A
            BRA   end_scan1            
     set_13:LDAA  #$30         ;move ascii value for "0" into accumulator A                         
  end_scan1:RTS
   
Scan_Col_2:
            MOVB  #$FB, PORTA     ;set PA0 to low and PA1-PA3 to high
            JSR   Read_PortA      ;scan portA
            
            LDAB  RFlag
            CMPB  #$01             ;Compare RFlag with the value 1 and branch to the end of the subroutine if not equal
            LBNE  end_scan2
              
            BRCLR	key, mPORTAD0_PTAD4, set_2	
	          BRCLR	key, mPORTAD0_PTAD5, set_6	
            BRCLR	key, mPORTAD0_PTAD6, set_10
            BRCLR	key, mPORTAD0_PTAD7, set_14
            BRA   end_scan2
           
      set_2:LDAA  #$33         ;move the ascii value for "3" into accumulator A
            BRA   end_scan2             
      set_6:LDAA  #$36         ;move ascii value for "6" into accumulator A
            BRA   end_scan2                                    
     set_10:LDAA  #$39         ;move ascii value for "9" into accumulator A
            BRA   end_scan2            
     set_14:LDAA  #$23         ;move ascii value for "#" into accumulator A                         
  end_scan2:RTS
   
Scan_Col_3:
            MOVB  #$F7, PORTA     ;set PA0 to low and PA1-PA3 to high
            JSR   Read_PortA      ;scan portA
            
            LDAB  RFlag
            CMPB  #$01             ;Compare RFlag with the value 1 and branch to the end of the subroutine if not equal
            LBNE  end_scan3
              
            BRCLR	key, mPORTAD0_PTAD4, set_3	
	          BRCLR	key, mPORTAD0_PTAD5, set_7	
            BRCLR	key, mPORTAD0_PTAD6, set_11
            BRCLR	key, mPORTAD0_PTAD7, set_15
            BRA   end_scan3
           
      set_3:LDAA  #$41         ;move the ascii value for "A" into accumulator A
            BRA   end_scan3             
      set_7:LDAA  #$42         ;move ascii value for "B" into accumulator A
            BRA   end_scan3                                    
     set_11:LDAA  #$43         ;move ascii value for "C" into accumulator A
            BRA   end_scan3            
     set_15:LDAA  #$44         ;move ascii value for "D" into accumulator A                         
  end_scan3:RTS
            
Read_PortA:
            MOVB  #$00, RFlag                        
            LDAA  PORTA
            STAA  key   
            BRSET key, #$F0, no_input
            LDY   #9
            JSR   Delay10ms       ;delay 90ms for debouncing
            LDAB  PORTA
            CBA
            BNE   no_input
            MOVB  #$01, RFlag  
                   
  no_input: LDAA  #$00
            RTS       
            
Init_Keypad:
            MOVB	#$0F, DDRA        ; 
	          BSET	PUCR, mPUCR_PUPAE	; enable port A pull-up resistors
	          RTS
            
Init_LCD:
            MOVB  #$FF, DDRK      ;initialize PORTK
            CLR   PORTK
            
            LDY   #2
            JSR   Delay10ms       ;use library subroutine to delay for 20ms (minimum of 15ms)
            
            ;Byte 1
            LDAA  #$30            ;load the value $30 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Write the upper command to the LCD
            
            LDY   #5
            JSR   Delay1ms        ;use library subroutine to delay for 5ms (minimum of 5ms)
            
            ;Byte 2
            LDAA  #$30            ;load the value $30 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Write the upper command to the LCD
            
            LDY   #1
            JSR   Delay100us       ;use library subroutine to delay for 100us (minimum of 100us)
            
            ;Byte 3
            LDAA  #$30            ;load the value $30 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Write the upper command to the LCD
            
            LDY   #5
            JSR   Delay10us       ;use library subroutine to delay for 50us (minimum of 50us)
            
            ;Byte 4
            LDAA  #$20            ;load the value $20 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Write the upper command to the LCD
            
            LDY   #5
            JSR   Delay10us       ;use library subroutine to delay for 50us (minimum of 50us)
            
            ;Byte 5
            LDAA  #$28            ;load the value $28 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Send the first command
            TBA                   ;Transfer the contents of B to A
            JSR   WriteCMD        ;Send the second command
            
            LDY   #5
            JSR   Delay10us       ;use library subroutine to delay for 50us (minimum of 50us)
            
            ;Byte 6
            LDAA  #$0C            ;load the value $0C into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Send the first command
            TBA                   ;Transfer the contents of B to A
            JSR   WriteCMD
            
            LDY   #5
            JSR   Delay10us       ;use library subroutine to delay for 50us (minimum of 50us)
            
            ;Byte 7
            LDAA  #$01            ;load the value $01 into accumulator A
            JSR   SplitNum        ;Split the value into two commands
            JSR   WriteCMD        ;Send the first command
            TBA                   ;Transfer the contents of B to A
            JSR   WriteCMD
            
            LDY   #3
            JSR   Delay1ms       ;use library subroutine to delay for 3ms (minimum of 1.64ms)
            
            ;Byte 8
            LDAA  #$06           ;load the value $06 into accumulator A
            JSR   SplitNum       ;Split the value into two commands
            JSR   WriteCMD       ;Send the first command
            TBA                  ;Transfer the contents of B to A
            JSR   WriteCMD
            
            LDY   #5
            JSR   Delay10us      ;use library subroutine to delay for 50us (minimum of 50us)
            
            RTS
            
Display_Msg:            
     loop:  LDAA  0,X              ;loads content of register x into accumulator A
            INX                    ;increments register X
            CMPA  #0               ;compares register A with the decimal value 0 and sets the zero flag in the CCR register to 1 if they are equal
            BEQ   disp_end         ;branches to disp_end if ACCA and #0 are equal
            JSR   Display_Char     ;If the previous instruction doesn't reuslt in a branch, display the character
            BRA   loop             ;always branch back to loop at this point
 disp_end:  RTS                    ;returns back from the subroutine          RTS
            
  WriteCMD:
            LSLA
            LSLA
            STAA  PORTK
            BSET  PORTK, EN 
            NOP
            NOP
            NOP
            BCLR  PORTK, EN
            RTS
            
  SplitNum:
            TAB
	          ANDB  #$0F
	          LSRA
	          LSRA
	          LSRA
	          LSRA
	          RTS
	          
	WriteData:
            LSLA
            LSLA
            ORAA  #$01
            STAA  PORTK
            BSET  PORTK, EN 
            NOP
            NOP
            NOP
            BCLR  PORTK, EN
            RTS
            
Set_Position:
            PSHD
            ORAA  #$80
            JSR   SplitNum
            JSR   WriteCMD            
            TBA
            JSR   WriteCMD
            LDY   #1
            JSR   Delay50us
            PULD
            RTS
            
Display_Char:
            PSHD  ;save ACCD onto the stack        
            JSR   SplitNum
            JSR   WriteData                        
            TBA
            JSR   WriteData                        
            LDY   #1
            JSR   Delay50us
            PULD
            RTS
            
Set_Blink_ON:

            PSHD
            PSHY
            LDAA  #$0D
            
            
            JSR   SplitNum
            JSR   WriteCMD
            TBA
            JSR   WriteCMD
            LDY   #1
            JSR   Delay50us
            PULY  
            PULD  
            RTS
            
Set_Blink_OFF:

            PSHD
            PSHY
            LDAA   #$0C
            
            
            JSR    SplitNum
            JSR    WriteCMD
            TBA
            JSR    WriteCMD
            LDY    #1
            JSR    Delay50us
            PULY
            PULD
            RTS
                    
;***********************************************************************
; Common subroutines from Lab10Lib.asm
;***********************************************************************

 			INCLUDE 'Lab10Lib.asm' 
                         			
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************

			ORG Virq
			DC.W IRQ_INT ; IRQ interrupt vector
			
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
