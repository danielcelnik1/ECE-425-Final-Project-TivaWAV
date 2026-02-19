# PWM Audio Playback on TM4C123

## Overview
This project implements a simple digital-to-analog audio system using PWM on the **Tiva C TM4C123** microcontroller.  
8-bit PCM audio is read from an SD card via SPI and converted into an analog signal using PWM, a two-stage RC low-pass filter, and a class-D amplifier.

---

## How It Works

1. **SD Card (SPI / SSI)**  
   - Audio stored as raw 8-bit PCM  
   - Data read in 512-byte sectors  

2. **Buffering**  
   - Each sector loaded into a 512-byte buffer  
   - One byte = one audio sample  

3. **PWM Output (44.1 kHz)**  
   - PWM duty cycle updated per sample  
   - SysTick used for sample timing  
   - Emulates DAC behavior  

4. **Analog Reconstruction**  
   - Two-stage RC low-pass filter  
     - Stage 1: 2.7kΩ, 100nF  
     - Stage 2: 10kΩ, 100nF  
   - Class-D amplifier drives speaker  

---

## Key Specs

- Sample Rate: 44.1 kHz  
- Resolution: 8-bit PCM  
- SD Sector Size: 512 bytes  
- PWM-based DAC (no dedicated DAC hardware)

---

## Concepts Applied

- PWM as DAC  
- SPI/SSI communication  
- Timer configuration  
- Low-pass filtering  
- Embedded C real-time control  

---

## Summary

A complete embedded audio pipeline:  
**SD card → SPI → PWM → RC filter → Amplifier → Speaker**  