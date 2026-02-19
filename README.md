/**
 * @file SSI0.c
 *
 * @brief Source code for the SSI0 driver (for SD card SPI).
 *
 * @note Uses 400 kHz for initialization and switches to 10 MHz afterward.
 */

#include "SSI0.h"
#include <stdint.h>
#include <stdbool.h>
#include "TM4C123GH6PM.h"
#include "SysTick_Delay.h"

// --- Manual CS Control ---
#define CS_PIN  (1 << 3)
void SPI_CS_Low(void)  { GPIOA->DATA &= ~CS_PIN; }
void SPI_CS_High(void) { GPIOA->DATA |= CS_PIN; }

// --- SSI Status Register bits ---
#define SSI_SR_TFE  0x01
#define SSI_SR_TNF  0x02
#define SSI_SR_RNE  0x04
#define SSI_SR_RFF  0x08
#define SSI_SR_BSY  0x10

// --- 400 kHz at startup ---
void SSI0_Init(void)
{
    SYSCTL->RCGCSSI |= 0x01;
    SYSCTL->RCGCGPIO |= 0x01;
    while ((SYSCTL->PRGPIO & 0x01) == 0) {}

    GPIOA->AFSEL |= (1 << 2) | (1 << 4) | (1 << 5);
    GPIOA->PCTL &= ~((0xF << 8) | (0xF << 16) | (0xF << 20));
    GPIOA->PCTL |= (0x2 << 8) | (0x2 << 16) | (0x2 << 20);
    GPIOA->DEN |= 0x3C;

    GPIOA->AFSEL &= ~(1 << 3);
    GPIOA->DIR |= (1 << 3);
    GPIOA->DATA |= (1 << 3);

    SSI0->CR1 &= ~0x02;
    SSI0->CR1 &= ~0x01;
    SSI0->CR1 &= ~0x04;
    SSI0->CC = 0x0;

    // Set to 400 kHz: 50 MHz / (125 * 1)
    SSI0->CPSR = 125;
    SSI0->CR0 = 0x07; // 8-bit, mode 0

    SSI0->CR1 |= 0x02;
}

// --- Switch to 10 MHz after init ---
void SD_SetHighSpeed(void) {
    SSI0->CR1 &= ~0x02;     // Disable SSI during configuration
    SSI0->CPSR = 2;         // 50 MHz / 4 = 12.5 MHz
    SSI0->CR0 = 0x07;       // 8-bit data, SPI mode 0
    SSI0->CR1 |= 0x02;      // Enable SSI
}

// --- SPI byte transfer ---
uint8_t SPI_Transfer(uint8_t byte) {
    while ((SSI0->SR & SSI_SR_TNF) == 0);
    SSI0->DR = byte;
    while ((SSI0->SR & SSI_SR_RNE) == 0);
    return SSI0->DR & 0xFF;
}

// --- SPI burst transfer ---
void SPI_TransferBurst(const uint8_t *tx, uint8_t *rx, int len) {
		SPI_CS_High();
		SPI_CS_Low();
    for (int i = 0; i < len; ++i) {
        uint8_t out = tx ? tx[i] : 0xFF;
        rx[i] = SPI_Transfer(out);
    }
		SPI_CS_High();

}

// --- Wait for R1 response ---
uint8_t SD_WaitForR1(void) {
    for (int i = 0; i < 10; i++) {
        uint8_t r1 = SPI_Transfer(0xFF);
        if ((r1 == 0x01)) return r1;
    }
    return 0xFF;
}

uint8_t SD_WaitForResponse(void) {
    SPI_CS_High();
	//	SysTick_Delay1us(1);
		SPI_CS_Low();
	//	SysTick_Delay1us(1);
	  uint8_t response = SPI_Transfer(0xFF);
    SPI_CS_High();
	//	SysTick_Delay1us(1);
    return response;
}

// --- Send command to SD card ---
void SD_SendCommand(uint8_t cmd, uint32_t arg, uint8_t crc) {
	
    uint8_t packet[6];
    packet[0] = 0x40 | cmd;
    packet[1] = (arg >> 24) & 0xFF;
    packet[2] = (arg >> 16) & 0xFF;
    packet[3] = (arg >> 8) & 0xFF;
    packet[4] = arg & 0xFF;
    packet[5] = crc;
	
    SPI_TransferBurst(packet, (uint8_t *)0, 6);
	
}

uint8_t SD_SendCommand0(uint8_t cmd, uint32_t arg, uint8_t crc) {
    uint8_t packet[6];
    packet[0] = 0x40 | cmd;
    packet[1] = (arg >> 24) & 0xFF;
    packet[2] = (arg >> 16) & 0xFF;
    packet[3] = (arg >> 8) & 0xFF;
    packet[4] = arg & 0xFF;
    packet[5] = crc;
		uint8_t r1  = 0x00;
	
		while (r1 != 0x01) {
		SPI_CS_Low();
    SPI_TransferBurst(packet, (uint8_t *)0, 6);
	  SPI_CS_High();
//	 	SysTick_Delay1us(1);
		SPI_CS_Low();
    r1 = SD_WaitForR1();
	  SPI_CS_High();
	//	SysTick_Delay1us(1);
		}
    for (int i = 0; i < 8; i++) {
	  SPI_CS_Low();
	//	SysTick_Delay1us(1);
		SPI_Transfer(0xFF);
		SPI_CS_High();
	//	SysTick_Delay1us(1);

		}

    return r1;
}



// --- SD card initialization ---
bool SD_Initialize(void) {
    // Send 80+ clocks (10 bytes) with CS high
    SPI_CS_High();
		 bool done = false;
		uint8_t reply = 0;
    for (int i = 0; i < 500; i++) SPI_Transfer(0xFF);

		SD_SendCommand(0,0x00000000,0x95);
		for (int i = 0; i < 12 ; i++) {
			reply = SD_WaitForResponse();
			if (reply == 0xC1) {
			done = false;
			return done; }
		}	
		SD_SendCommand(8,0x000001AA,0x87);
		for (int i = 0; i < 12 ; i++) {
			reply = SD_WaitForResponse();
			if (reply == 0xC1) {
				done = false;
				return done; }
		}
			for (int i = 0; i < 1000 ; i++) {
			SD_SendCommand(55,0x00000000,65);	
				
				for (int j = 0 ; j < 8; j++) {
				reply = SD_WaitForResponse();
				if (reply == 0x00) done = true;
					}
				
			  SD_SendCommand(41,0x40000000,0x77);	
					
				for (int j = 0 ; j < 8; j++) {
				reply = SD_WaitForResponse();
				if (reply == 0x00) done = true;
					}
				if (done == true) break;

			}
		
	return done;

}

bool SD_ReadSector(uint32_t lba, uint8_t *buffer)
{
    // CMD17: Read single block (0x11)
    SD_SendCommand(17, lba, 0xFF);

    // Wait for R1 response (should be 0x00 for success)
    for (int i = 0; i < 10; i++) {
        uint8_t r1 = SD_WaitForResponse();
        if (r1 == 0x00) break;
        if (i == 9) return false; // timeout
    }

    // Wait for data token (0xFE)
    for (int i = 0; i < 1000; i++) {
        uint8_t token = SD_WaitForResponse();
        if (token == 0xFE) break;
        if (i == 999) return false; // timeout
    }

    // Read 512 bytes
    for (int i = 0; i < 512; i++) {
        buffer[i] = SD_WaitForResponse();
    }

    // Allow CRC to clear
    for (int i = 0; i < 10; i++) {
        SD_WaitForResponse();
    }
    return true;
}

