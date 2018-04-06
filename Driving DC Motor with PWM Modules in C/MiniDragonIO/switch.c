#include "switch.h"

void init_Switch(void){
  SWITCH_DIR = 0x00;  // Set PT 0-7 as input
}

char *readSwitch(void){
  char *ch;
  unsigned int switch_input;
  
  switch_input = SWITCH_DAT; // Read the switch data
  
  /*
     Figure out which number the switch 
     is set to and find the corresponding 
     'string' to display
  */
  
  switch(switch_input){
    case 0x00:
      ch = "00";
      break;
    case 0x01:
      ch = "01";
      break;
    case 0x02:
      ch = "02";
      break;
    case 0x03:
      ch = "03";
      break;
    case 0x04:
      ch = "04";
      break;
    case 0x05:
      ch = "05";
      break;
    case 0x06:
      ch = "06";
      break;
    case 0x07:
      ch = "07";
      break;
    case 0x08:
      ch = "08";
      break;
    case 0x09:
      ch = "09";
      break;
    case 0x0A:
      ch = "10";
      break;
    case 0x0B:
      ch = "11";
      break;
    case 0x0C:
      ch = "12";
      break;
    case 0x0D:
      ch = "13";
      break;
    case 0x0E:
      ch = "14";
      break;
    case 0x0F:
      ch = "15";
      break;
  }
  
  return ch;
}