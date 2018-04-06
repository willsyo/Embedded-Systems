#include "led.h"

void init_LED(void){
  LED_DIR = 0xF0;  // Set PM4-7 as output
  LED_DAT = 0xF0;  // Blink to test for proper initialization
  delayMS(5);
  LED_DAT = 0x00;
}

void writeNumLED(const char num){

 /*
 
   Figure out which number should be displayed
   And send it the LED.
   
 */
   
  switch (num){
    case hex_values[0]:
      LED_DAT = 0x10;
      break;
    case hex_values[1]:
      LED_DAT = 0x20;
      break;
    case hex_values[2]:
      LED_DAT = 0x30;
      break;
    case hex_values[3]:
      LED_DAT = 0xA0;
      break;
    case hex_values[4]:
      LED_DAT = 0x40;
      break;
    case hex_values[5]:
      LED_DAT = 0x50;
      break;
    case hex_values[6]:
      LED_DAT = 0x60;
      break;
    case hex_values[7]:
      LED_DAT = 0xB0;
      break;
    case hex_values[8]:
      LED_DAT = 0x70;
      break;
    case hex_values[9]:
      LED_DAT = 0x80;
      break;
    case hex_values[10]:
      LED_DAT = 0x90;
      break;
    case hex_values[11]:
      LED_DAT = 0xC0;
      break;
    case hex_values[12]:
      LED_DAT = 0xE0;
      break;
    case hex_values[13]:
      LED_DAT = 0x00;
      break;
    case hex_values[14]:
      LED_DAT = 0xF0;
      break;
    case hex_values[15]:
      LED_DAT = 0xD0;
      break;
  }   
}
