
#include <MC9S12DP256.h>


#define LCD_DAT PORTK
#define LCD_DIR DDRK
#define LCD_E 0x02
#define LCD_RS 0x01
#define LCD_E_RS 0x03

void cmd2LCD(char cmd);

void openLCD(void);

void putLCD(char cx);

void putsLCD(char* ptr);
