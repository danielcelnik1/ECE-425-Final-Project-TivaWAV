// Main Code for tivaWAV
// Written by Daniel Celnik and Adam Espinoza

#include <stdint.h>
#include <stdbool.h>
#include "TM4C123GH6PM.h"
#include "SSI0.h"
#include "SysTick_Delay.h"
#include "UART0.h"
#include "PWM1_0.h"

#define BUFFER_SIZE    16384           // 32 sectors of 512 bytes
#define PWM_PERIOD     1133            // ~44.1 kHz PWM at 50 MHz
#define START_SECTOR   0
#define MARKER_BYTE    0x53

uint8_t buffer[BUFFER_SIZE];
volatile bool playing = false;

// Non-blocking UART character check
char UART0_CheckForCharacter(void) {
    // Check if there's data in the receive FIFO
    if((UART0->FR & UART0_RECEIVE_FIFO_EMPTY_BIT_MASK) == 0) {
        // Return the received character
        return (char)(UART0->DR & 0xFF);
    }
    return 0; // Return 0 if no character available
}

int main(void) {
    // Init hardware
    SSI0_Init();              // SPI for SD
    SysTick_Delay_Init();     // Microsecond delay
    UART0_Init();             // Debug UART
    UART0_Clear_Terminal();
    PWM1_0_Init(PWM_PERIOD, PWM_PERIOD / 2);  // 50% duty to start
    
    UART0_Output_String("INITIALIZING AUDIO PLAYER\r\n");
		

    UART0_Output_String("SD INIT SUCCESS\r\n");
    SD_SetHighSpeed();
    
    uint32_t current_sector = START_SECTOR;
    
    UART0_Output_String("LOADING BUFFER...\r\n");
    
    // Fill buffer initially
    for (int i = 0; i < BUFFER_SIZE / 512; i++) {
        SD_ReadSector(current_sector++, &buffer[i * 512]);
    }
    
    UART0_Output_String("BUFFER LOADED - PRESS 'P' TO PLAY, 'S' TO STOP\r\n");
    
    // Main playback loop
    while (1) {
        // Check for key presses
        char input = UART0_CheckForCharacter();
        
        if (input == 'P' || input == 'p') {
            if (!playing) {
                playing = true;
                UART0_Output_String("PLAYING AUDIO...\r\n");
            }
        }
        else if (input == 'S' || input == 's') {
            if (playing) {
                playing = false;
                // Silence output when stopped
                PWM1_0_Update_Duty_Cycle(PWM_PERIOD / 2);
                UART0_Output_String("PLAYBACK STOPPED\r\n");
            }
        }
        
        // Only process audio if in playing state
        if (playing) {
            for (int sector = 0; sector < BUFFER_SIZE / 512; sector++) {
                uint8_t* sector_ptr = &buffer[sector * 512];
                
                // Process all samples in this sector
                for (int i = 0; i < 512 - 1; i++) {
                    // Check for key presses during playback
                    char key = UART0_CheckForCharacter();
                    if (key == 'S' || key == 's') {
                        playing = false;
                        PWM1_0_Update_Duty_Cycle(PWM_PERIOD / 2);
                        UART0_Output_String("PLAYBACK STOPPED\r\n");
                        break;
                    }
                    
                    if (sector_ptr[i] == MARKER_BYTE) {
                        uint8_t sample = sector_ptr[i + 1];
                        // Convert unsigned 8-bit (0–255) to 16-bit biased range (0–65535)
                        uint16_t biased = ((uint16_t)sample) << 8;  // scale to full range
                        uint16_t duty = (biased * PWM_PERIOD) >> 18;
                        PWM1_0_Update_Duty_Cycle(duty);
                        SysTick_Delay1us(21);  
                        i++;  // skip sample byte
                    }
                }
                
                // If playback was stopped, break out of sector loop
                if (!playing) {
                    break;
                }
                
                // Load next sector
                SD_ReadSector(current_sector++, sector_ptr);
            }
        }
        else {
            SysTick_Delay1ms(10);
        }
    }
}