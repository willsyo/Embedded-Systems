#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <MC9S12DP256.h>   

void main(void){

  unsigned char dip0, dip1;
  char keypad_input;
  unsigned char out = 0xD0;

  char *switchOut[16] = {
    "00","01","02","03","04","05","06","07",
    "08","09","10","11","12","13","14","15"
  };
  
  unsigned char keypadOut[16] = {
    0x1,0x2,0x3,0xA,0x4,0x5,0x6,0xB,
    0x7,0x8,0x9,0xC,0xE,0x0,0xF,0xD
  };
  
  /* Device Initializations */
  initSPI();
  init_LCD();
  init_Keypad();
  
  while (1){
  
    if(keypadAvailable()){               
    
      keypad_input = scanKeypad();       // Read keypad
      waitfor_keyup();                   
      putcSPI(keypadOut[keypad_input]);  // Output the keypad value to LEDs via SPI module
      PTM |= 0x02;                       
      
    }
    
    dip0 = getcSPI();                   // Read switch value from SPI module
    if (dip0 != dip1){                  // Only display new switch value if it has changed
    
      dip1 = dip0;
      cmd2LCD(0x80);
      display_stringLCD(switchOut[dip0]);
      
    }    
    
    PTM = 0x00;                         // Set Port M low
    
  }
  
}



