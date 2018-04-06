#include "spi.h"

void initSPI(){
   SPI0CR1 = 0x50;// Enable SPI system as master, Polarity = 0, Phase = 0
   SPI0BR = 0x21; // Set Baud Rate to 2 MHz
   WOMS = 0x00;   // Set Pull-Up resistors
   DDRM |= 0x03;  // Enable PM0-PM1 as output for shift reg enable
   PTM &= 0xFE;   // Set PM0 LOW for parallel input
}

char getcSPI(){

  PTM |= 0x01;                // Set PM0 HIGH for Output
  while(!(SPI0SR_SPTEF));     // wait until write is permissible
  SPI0DR = 0x00;              // trigger 8 SCK pulses to shift in data
  while(!(SPI0SR_SPIF));      // wait until a byte has been shifted in
  PTM &= 0xFE;                // Set PM0 LOW for parallel input
  return SPI0DR;              // return the character
  
}

void getsSPI(char *ptr, int count){
  
  while(count) {         // continue while byte count is nonzero
    *ptr++ = getcSPI();  // get a byte and save it in buffer
    count--;
  }
  *ptr = 0;              // terminate the string with a NULL
  
}

void putcSPI(char cx){

  char temp;
  while(!(SPI0SR_SPTEF)); // wait until write is permissible
  SPI0DR = cx;            // output the byte to the SPI
  while(!(SPI0SR_SPIF));  // wait until write operation is complete
  temp = SPI0DR;          // clear the SPIF flag

}

void putsSPI(char *ptr){

  while(*ptr) {     /* continue until all characters have been output */
    putcSPI(*ptr);
    ptr++;
  }

}