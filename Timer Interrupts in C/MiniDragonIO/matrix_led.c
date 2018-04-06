#include "matrix_led.h"

void init_MatrixLED(void){
  DDRS = 0xF0; // Port S pins 4-7 are output 
  DDRP = 0xF0; // Port P pins 4-7 are output
}

void writeMatrixLED(char cx){
  int i;
  int *num; // Pointer to array address of desired number
  
  // Figure which array to assign to the pointer
  // Based on received character
  switch(cx){
    case '0':
      num = zero;  
    break;
    
    case '1':
      num = one;
    break;
    
    case '2':
      num = two;
    break;
    
    case '3':
      num = three;
    break;
    
    case '4':
      num = four;
    break;
    
    case '5':
      num = five;
    break;
    
    case '6':
      num = six;
    break;
    
    case '7':
      num = seven;
    break;
    
    case '8':
      num = eight;
    break;
    
    case '9':
      num = nine;
    break;
    
    case 'A':
      num = a;
    break;
    
    case 'B':
      num = b;
    break;
    
    case 'C':
      num = c;
    break;
    
    case 'D':
      num = d;
    break;
    
    case 'E':
      num = e;
    break;
    
    case 'F':
      num = f;
    break;
    
    default:
    break;
  }
    for(i = 0; i < 15; i++){
      if(num[i] == 1){
        PTP = port_p[i];
        PTS = port_s[i];
      }
      delayMS(1);
    }
 
}
