;************************************************************************
; Author: Tyler Willis		  CPEN 231L  
; Project: Lab11			
; Program: Communication with Terminal	
; Date Created: 12/5/2016
; Last Modified: 12/5/2016			
; Description: This program will use control registers to establish 
; communication between a keyboard and a monitor, allowing the user to type
; in a 20 character string, as the monitor live updates, and then reprints 
; the string.
; Outputs: Outputs the following on the LCD:
;		   "Lab 11-SCI"  
;*************************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
RS          EQU   mPORTB_BIT0
EN          EQU   mPORTB_BIT1
SIZE		EQU   20
NULL		EQU   $00
CR			EQU   $0D
LF			EQU   $0A
FF			EQU   $0C
BS			EQU   $08
SPACE       EQU   $20

; variable/data section

 ifdef _HCS12_SERIALMON
            ORG $3FFF - (RAMEnd - RAMStart)
 else
            ORG RAMStart
 endif
 ; Insert here your data definition.
project_msg DC.B "Lab 11-SCI",0
output_msg  DC.B "Buffer_Term -> ",0
count		DS.B 1
DFlag		DS.B 1
Buffer_Term DS.B SIZE

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

            CLI                     ; enable interrupts
			
;**************************************************************
;*                 Initialize Hardware                          
;**************************************************************	

			JSR	  Init_Hardware_Lib
			JSR   Init_LCD
			JSR   Init_SCI1
			CLR   DFlag
			CLR   count
			JSR   Clear_buffer
			JSR   Display_msg
			
;**************************************************************
;*                 Main Loop                          
;**************************************************************			
			
	main:	JSR   Read_Terminal
			JSR   Display_Buffer	
			BRA   main

;**************************************************************
;*SUBROUTINE: Display_Buffer,                           
;**************************************************************

Display_Buffer:
			;only display the buffer if the flag is set
			LDAB  DFlag
			CMPB  #1
			BNE   end_display
			;set the monitor to a new line
			LDAA  #CR
			JSR   Out_SCI1
			LDAA  #LF
			JSR   Out_SCI1
			;clear the flag and count vars
			CLR   DFlag
			CLR   count
			;display the buffer
			JSR   Write_Msg
			LDAA  #CR
			JSR   Out_SCI1
			LDAA  #LF 
			JSR   Out_SCI1	   ;clear the previous buffer_string
			JSR   Clear_buffer
end_display:
			RTS

;**************************************************************
;*SUBROUTINE: Write_Msg,                           
;**************************************************************

Write_Msg:
			LDX   #output_msg
display_output:
			;output the "Buffer_Term ->" message first
			LDAA  0, X
			CMPA  #NULL
			BEQ   display_buff
			JSR   Out_SCI1
			INX
			BRA   display_output

display_buff:
			;now display the buffer_term string
			LDX   #Buffer_Term
			LDAB  #0
			
	write:	CMPB  #SIZE
			BEQ   end_write
			LDAA  0, X
			JSR   Out_SCI1
			INX
			INCB
			BRA   write
			
end_write:	RTS	
					
;**************************************************************
;*SUBROUTINE: Read_Terminal,                           
;**************************************************************	

Read_Terminal:
			;	
			LDAB  count
			CMPB  #SIZE
			BHS	  end_read
			LDX   #Buffer_Term
			;Read the input char on SCI1
			JSR   In_SCI1
			;end the routine if the last character is NULL	
			CMPA  #NULL
			BEQ	  end_Terminal
			;Echo character back to SCI1
			JSR   Out_SCI1
			
			CMPA  #CR
			BEQ   end_read
			;if the input char is a backspace, delete the char from the bufffer
			;and delete the char from the monitor output
			CMPA  #BS
			BNE   continue_read
			DEC   count
			LDAB  count
			CLR   B, X
			;get rid of the current char in the monitor
			LDAA  #SPACE
			JSR   Out_SCI1
			LDAA  #BS
			JSR   Out_SCI1
			BRA   end_Terminal
			
continue_read:
			STAA  B, X
			
			INC   count
			BRA   end_Terminal
			;Increment the display flag if the buffer capacity is reached	   
end_read:   INC   DFlag
			MOVB  #NULL, B, X
			
end_Terminal:
			RTS

;**************************************************************
;*SUBROUTINE: Out_SCI1,                           
;**************************************************************

Out_SCI1:	BRCLR SCI1SR1, $80, *	 ;keep listening to status register until 
									 ;bit 7 goes high
			STAA  SCI1DRL			 ;SCI1DRL <- ACCA
			RTS
			
;**************************************************************
;*SUBROUTINE: In_SCI1,                           
;**************************************************************

In_SCI1:	BRCLR SCI1SR1, $20, *	 ;keep listening to status register until 
									 ;bit 1 goes high
			LDAA  SCI1DRL			 ;ACCA <- SCI1DRL
			
			;ANDA  $7F
			
	end_in: 
			RTS					

;**************************************************************
;*SUBROUTINE: Clear_buffer,                           
;**************************************************************

Clear_buffer:
			LDX  #Buffer_Term
			LDAB #0
			;write zeros to the entire buffer
	clear:	CLR  B, X
			CMPB #SIZE
			BEQ  end_clear
			INCB
			BRA  clear
end_clear:	RTS

;**************************************************************
;*SUBROUTINE: Display_msg, displays the project message on LCD                          
;**************************************************************

Display_msg:
			LDX  #project_msg
			LDAA #03
			JSR  Set_Position
			JSR  Display_Msg
			RTS	
			
;**************************************************************
;*                 Initialize SCI1                          
;**************************************************************

Init_SCI1:
			MOVB  #$00, SCI1BDH
			MOVB  #$4E, SCI1BDL	   ;set Baud rate to 19200
			MOVB  #$00, SCI1CR1	   ;1 strt bit, 8 data bits, 1 stop bit
								   ;parity disabled
			MOVB  #$0C, SCI1CR2	   ;Transmit and receiver enabled, interrupt disabled
			RTS		
;---------------------------------------------------------------
;---------------------------------------------------------------			
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
            
;***********************************************************************
; Common subroutines from Lab11Lib.asm
;***********************************************************************

 			INCLUDE 'Lab11Lib.asm' 
                         					
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
