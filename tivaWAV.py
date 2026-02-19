#ifndef SSI0_H
#define SSI0_H

#include <stdint.h>
#include <stdbool.h>

void SSI0_Init(void);
void SD_SetHighSpeed(void);

void SPI_CS_Low(void);
void SPI_CS_High(void);

uint8_t SPI_Transfer(uint8_t byte);
void SPI_TransferBurst(const uint8_t *tx, uint8_t *rx, int len);

void SD_SendCommand(uint8_t cmd, uint32_t arg, uint8_t crc);
uint8_t SD_SendACMD(uint8_t acmd, uint32_t arg, uint8_t crc);
bool SD_Initialize(void);
uint8_t SD_SendCommand0(uint8_t cmd, uint32_t arg, uint8_t crc);
uint8_t SD_WaitForResponse(void);
bool SD_ReadSector(uint32_t lba, uint8_t *buffer);
void SD_BeginStream(uint32_t lba);
void SD_StopStream(void);
void Stream_Audio_With_Triplets(uint32_t start_sector);
	#endif
