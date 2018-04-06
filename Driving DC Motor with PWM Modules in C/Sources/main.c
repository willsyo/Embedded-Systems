
#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

char *switchOut[16] = {
    "1","2","3","INVALID","4","5","6","INVALID", 
    "7","8","9","INVALID","INVALID","INVALID","INVALID","INVALID"
  }; // Invalids won't actually show on LCD
  
void main(void){
  
  unsigned int key_value, prev_value;
  char dir = '+';  // Initialize spin direction
  
  // Initialize hardware  
  init_Keypad();
  init_LCD();
  init_motor();
  
  while(1){
  
   if (keypadAvailable()){
      key_value = scanKeypad();
      
      // Prevents function from reacting to invalid buttons
      if((key_value != 3) && (key_value != 7) && (key_value < 11)){
        
        set_motor_speed(key_value); // Adjust motor speed
        change_motor_direction(dir);// Adjust direction
        cmd2LCD(0x01);              // Display speed to LCD
        display_charLCD(dir);
        display_stringLCD(switchOut[key_value]);
        prev_value = key_value;     // Record current speed
        
      } else if (key_value == 0xC){ // Spin clockwise case
        dir = '+';
        change_motor_direction(1);
        cmd2LCD(0x01);
        display_charLCD('+');  
        display_stringLCD(switchOut[prev_value]);
        
      } else if(key_value == 0xE){ // Spin counter-clockwise case
        dir = '-';                 // Update current direction
        change_motor_direction(0); // Adjust direction
        cmd2LCD(0x01);             // Display Speed
        display_charLCD('-');
        display_stringLCD(switchOut[prev_value]);

      } else if(key_value == 0xD){ // Stop Motor case
        stop_motor();              
        cmd2LCD(0x01);             // Display STOP
        display_stringLCD("STOP");
      }
      
      
        
    } 
    
  }
 
}

