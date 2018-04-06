#include "lcd.h"

void cmd2LCD (char cmd){

     char temp;
     temp = cmd;           /* save a copy of the command */
     cmd &=0xF0;           /* clear out the lower 4 bits */
     LCD_DAT &= (~LCD_RS); /* select LCD instruction register */
     LCD_DAT |= LCD_E;     /* pull E signal to high */
     cmd >>= 2;            /* shift to match LCD data pins */
     LCD_DAT = cmd | LCD_E;/* output upper 4 bits, E, and RS */
     asm("nop");           /* dummy statements to lengthen E */
     LCD_DAT &= (~LCD_E);  /* pull E signal to low */
     cmd = temp & 0x0F;    /* extract the lower four bits */
     LCD_DAT |= LCD_E;     /* pull E to high */
     cmd <<= 2;            /* shift to match LCD data pins */
     LCD_DAT = cmd | LCD_E;/* output upper 4 bits, E, and RS */
     asm("nop");           /* dummy statements to lengthen E */
     asm("nop");           /*       "         */
     asm("nop");
     LCD_DAT &= (~LCD_E);  /* pull E clock to low */
     delayMS(50);          /* wait until the command is complete */
}

void init_LCD(void){

    LCD_DIR = 0xFF;        /* configure LCD_DAT port for output */
    delayMS(100);
    cmd2LCD(0x03);
    cmd2LCD(0x03);
    cmd2LCD(0x28);
    cmd2LCD(0x06);
    cmd2LCD(0x0E);
    cmd2LCD(0x01);         /* clear screen, move cursor to home */
    delayMS(2);
}

void display_charLCD(char cx){

    char temp;
    temp = cx;
    LCD_DAT |= LCD_RS;     /* select LCD data register */
    LCD_DAT |= LCD_E;      /* pull E signal to high */
    cx &= 0xF0;            /* clear the lower 4 bits */
    cx >>= 2;              /* shift to match the LCD data pins */
    LCD_DAT = cx|LCD_E_RS; /* output upper 4 bits, E, and RS */
    asm("nop");            /* dummy statements to lengthen E */
    asm("nop");            /*       "         */
    asm("nop");
    LCD_DAT &= (~LCD_E);   /* pull E to low */
    cx = temp & 0x0F;      /* get the lower 4 bits */
    LCD_DAT |= LCD_E;      /* pull E to high */
    cx <<= 2;              /* shift to match the LCD data pins */
    LCD_DAT = cx|LCD_E_RS; /* output upper 4 bits, E, and RS */
    asm("nop");            /* dummy statements to lengthen E */
    asm("nop");            /*       "         */
    asm("nop");
    LCD_DAT &= (~LCD_E);   /* pull E to low */
    delayMS(1);
}

void display_stringLCD(char* ptr){

    while(*ptr){
        display_charLCD(*ptr);
        ptr++;
    }
}
