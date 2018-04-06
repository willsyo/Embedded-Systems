#include "keypad.h"

void init_Keypad(void){
  KEY_DIR = 0x0F;  // Set PA0-4 as output and PA5-7 as input
  PUCR = 0x01;     // Enable pull-up resistor for Port A
}

char scanKeypad(void){
	unsigned int KFlag = 0;  // button flag
	unsigned int Key_Input;  // Input from Port A
	int i;

  while (!KFlag){ 
  
    for (i = 0; i<4 ; i++){
    
      if(!KFlag){
      
        KEY_DAT = coloumn[i]; // Scan the current keypad column
        Key_Input = KEY_DAT;  // Read input from port A
        Key_Input >>= 4; // shift out the unnecessary 4 bits
        
        // Find out which port is low
        // and set teh key flag accordingly
        
        switch (Key_Input) {
        
          case 0x0F:     //If all high are high, there is no input
            KFlag = 0;
            break;
          case coloumn[0]:
            Key_Input = 0;
            KFlag = 1;
            break;
          case coloumn[1]:
            Key_Input = 4;
            KFlag = 1;
            break;
          case coloumn[2]:
            Key_Input = 8;
            KFlag = 1;
            break;
          case coloumn[3]:
            Key_Input = 12;
            KFlag = 1;
            break;
          default:
            KFlag = 0;
            break;
          
        }
        
        if (KFlag){          //Figures which row the button was pressed on
           Key_Input += i;          
        }else{
           KFlag = 0;
        }
      }    
    }
  }
  
  delayMS(200);              // add delay for debouncing
  return Key_Input;
  
}
 
void waitfor_keyup(){
  while((KEY_DAT&0xF0) != 0xF0){}   // Waits for button to be released
}

int keypadAvailable(void){
  int i = 0;
  unsigned int Key_Input = 0;
  unsigned int KFlag;
  for (i = 0; i<4 ; i++){
    KEY_DAT = coloumn[i];    // Scan the current keypad column
    Key_Input = KEY_DAT;     // Read input from port A
    Key_Input >>= 4;         // shift out the unnecessary 4 bits
    if (Key_Input != 0x0F){  // Check to see if there was a button pressed
      return 1;              // Return true if button is pressed
    } 
  }
  return 0;
}

