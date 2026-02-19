/**
 * @file PWM1_0.h
 *
 * @brief Header file for the PWM1_0 driver.
 *
 * This file contains the function definitions for the PWM1_0 driver.
 * It uses the Module1 PWM Generator 0 to generate a PWM signal with the PD0 pin.
 *
 * @note This driver assumes that the system clock's frequency is 50 MHz.
 *
 * @note This driver assumes that the PWM_Clock_Init function has been called
 * before calling the PWM1_0_Init function.
 *
 * @author Aaron Nanas
 */
 
#include "TM4C123GH6PM.h"

/**
 * @brief Initializes the PWM Module 1 Generator 0 with the specified period and duty cycle.
 *
 * This function initializes the PWM Module 1 Generator 0 with the given period constant and duty cycle.
 * It configures the PD0 pin to operate as a Module 1 PWM0 pin (M1PWM0) to output the PWM signal.
 * period_constant determines the PWM signal's frequency. The specified duty_cycle value must be less 
 * than the period_constant.
 *
 * @param period_constant The period constant for the PWM signal that determines the
 *                        PWM signal's frequency.
 *
 * @param duty_cycle The duty cycle, as a percentage of period_constant, for the PWM signal.
 *                   This value controls pulse width of the PWM signal.
 *
 * @return None
 */
void PWM1_0_Init(uint16_t period_constant, uint16_t duty_cycle);

/**
 * @brief Updates the PWM Module 1 Generator 0 duty cycle for the PWM signal on the PD0 pin (M1PWM0).
 *
 * @param duty_cycle The new duty cycle for the PWM signal on the PD0 pin (M1PWM0).
 *
 * @return None
 */
void PWM1_0_Update_Duty_Cycle(uint16_t duty_cycle);

