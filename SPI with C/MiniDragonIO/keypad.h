
#include <MC9S12DP256.h>


#define KEY_DAT PORTA
#define KEY_DIR DDRA

char key_values[16] = {'1', '2', '3', 'A', '4', '5', '6', 'B', '7', '8', '9', 'C', 'E', '0', 'F', 'D'}; 
const unsigned int coloumn[4] = {0x0E, 0x0D, 0x0B, 0x07};

void init_Keypad(void);

char scanKeypad(void);

void waitfor_keyup(void);

int keypadAvailable(void);