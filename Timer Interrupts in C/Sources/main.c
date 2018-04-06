
#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */


#define HiCnt 150
#define LoCnt 450

unsigned int on_edge, off_edge, overflow, diff, test_read;
char HiorLo, high, low;
unsigned long reaction_time;

char char_arry [10] = 
  {'0', '1', '2', '3', '4', 
  '5', '6', '7', '8', '9'};

char time_string[8];

void itos(char * string, unsigned long value);

void main(void) {
  unsigned char keypadInput;
  char i = 0;
  unsigned int edge1, period;
  
  // Initialize hardware  
  init_Keypad();
  init_LCD();
  DDRM = 0x80;
  DDRA = 0x0F;
  PUCR = 0x01;
  PORTA = 0x00;
  
  
  // Set up the square wave
  TSCR1 = 0x90;    // Timer Enable, Enable Fast Clear
  TSCR2 = 0x03;    // Disable Timer Interrupt Enable, Set Prescaler to 8
  TIOS |= 0x02;    // Set IOS1 to output compare, IOS2,3 to input capture
  TCTL2 = 0x0C;    // Set output compare 1 to set to high
  TFLG1 = 0x02;    // Clear interrupt flags
  TC1 = TCNT + 10; // Set to high in 10 clock cycles
  while(!(TFLG1 & 0x02)); // Wait for interrupt from high signal
  TCTL2 = 0x04;    // Set output compare 1 to toggle on interrupt
  TC1 += HiCnt;    // Set next interrupt time
  HiorLo = 0;      // Reset HiorLo flag
  TIE = 0x0E;      // Enable interrupts
  asm("cli");      // Clear global interrupt flag
  while(1);
  
 /* // Set up the input capture timers
  TCTL4 = 0x50;    // Set input trigger to be on the falling edge for both IC2,IC3
  TFLG1 = 0x0C;
      
  
  TSCR1 = 0x90;
  TSCR2 = 0x07;  // Set prescaler to 128
  TIOS &= ~0x04;
  TCTL4 = 0xA0;
  test_read = TCNT;  // Clear Overflow Reset
  TIE = 0x0C;
  asm("cli");
  
  while (1){
  
    while (!(high & low));
    
    TSCR2 &= ~0x80;   // Pause overflow interrupt
    diff = off_edge - on_edge;
    
    if (off_edge < on_edge){
      overflow -= 1;
    }
    
    reaction_time = ((long)overflow * 65536u + (long)diff)*16u/3u/1000u;
    overflow = 0;
    itos(time_string, reaction_time);
    cmd2LCD(0x80);
    display_stringLCD(time_string);
    high = 0;low = 0;      
  }                   */
}      
      
    
void itos(char * string, unsigned long value){
  int digit = 0;
  digit = value/1000;
  
  string[0] = char_arry[digit];
  value = value - digit * 1000;
  digit = value/100;
  
  string[1] = char_arry[digit];
  value = value - digit * 100;
  digit = value/10;
  
  string[2] = char_arry[digit]; 
  value = value - digit * 10;
  
  string[3] = char_arry[digit];
  string[4] = ' ';
  string[5] = 'm';
  string[6] = 's';
  string[7] = '\0';
}




void interrupt oc1ISR(void){   
    if(HiorLo){
      // Implement the high value
      TC1 += HiCnt; 
      HiorLo = 0;
    }else{
      // Implement the low value
      TC1 += LoCnt;
      HiorLo = 1;
    }
}

void interrupt near ic2isr(void){
    if (!high){
      on_edge = TC2;
      high = 1;
      overflow = 0;
      PTM = 0x80;
      TSCR2 |= 0x80;
    }else{
      test_read = TC2; 
    }
}

void interrupt near ic3isr(void){
    if (high){
       off_edge = TC3;
       low = 1;
       TSCR2 &= ~0x80;
       PTM = 0x00;
    }else{
       test_read = TC3; 
    }
}

void interrupt tovisr(void){
    test_read = TCNT;    // Clear the overflow interrupt flag
    overflow ++;
}
