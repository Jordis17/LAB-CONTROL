/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: Controller.h
 *
 * Code generated for Simulink model 'Controller'.
 *
 * Model version                  : 1.19
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Wed Sep  9 13:17:25 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Atmel->AVR
 * Code generation objectives:
 *    1. Execution efficiency
 *    2. Traceability
 * Validation result: Not run
 */

#ifndef Controller_h_
#define Controller_h_
#ifndef Controller_COMMON_INCLUDES_
#define Controller_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "rtw_continuous.h"
#include "rtw_solver.h"
#endif                                 /* Controller_COMMON_INCLUDES_ */

#include "Controller_types.h"
#include <string.h>

/* Block states (default storage) for model 'Controller' */
typedef struct {
  real32_T Integrator_DSTATE;          /* '<S38>/Integrator' */
} DW_Controller_f_T;

/* Parameters (default storage) */
struct P_Controller_T_ {
  real32_T Q_max;                      /* Variable: Q_max
                                        * Referenced by:
                                        *   '<S45>/Saturation'
                                        *   '<S30>/DeadZone'
                                        */
  real32_T Q_min;                      /* Variable: Q_min
                                        * Referenced by:
                                        *   '<S45>/Saturation'
                                        *   '<S30>/DeadZone'
                                        */
  real32_T DiscretePIDController2_InitialC;
                              /* Mask Parameter: DiscretePIDController2_InitialC
                               * Referenced by: '<S38>/Integrator'
                               */
  real32_T Constant1_Value;            /* Computed Parameter: Constant1_Value
                                        * Referenced by: '<S28>/Constant1'
                                        */
  real32_T Clamping_zero_Value;       /* Computed Parameter: Clamping_zero_Value
                                       * Referenced by: '<S28>/Clamping_zero'
                                       */
  real32_T Integrator_gainval;         /* Computed Parameter: Integrator_gainval
                                        * Referenced by: '<S38>/Integrator'
                                        */
  int8_T Constant_Value;               /* Computed Parameter: Constant_Value
                                        * Referenced by: '<S28>/Constant'
                                        */
  int8_T Constant2_Value;              /* Computed Parameter: Constant2_Value
                                        * Referenced by: '<S28>/Constant2'
                                        */
  int8_T Constant3_Value;              /* Computed Parameter: Constant3_Value
                                        * Referenced by: '<S28>/Constant3'
                                        */
  int8_T Constant4_Value;              /* Computed Parameter: Constant4_Value
                                        * Referenced by: '<S28>/Constant4'
                                        */
};

/* Real-time Model Data Structure */
struct tag_RTM_Controller_T {
  const char_T **errorStatus;
};

typedef struct {
  DW_Controller_f_T rtdw;
  RT_MODEL_Controller_T rtm;
} MdlrefDW_Controller_T;

/*
 * Exported Global Parameters
 *
 * Note: Exported global parameters are tunable parameters with an exported
 * global storage class designation.  Code generation will declare the memory for
 * these parameters and exports their symbols.
 *
 */
extern real32_T Ki_SIMC;               /* Variable: Ki_SIMC
                                        * Referenced by: '<S35>/Integral Gain'
                                        */
extern real32_T Kp_SIMC;               /* Variable: Kp_SIMC
                                        * Referenced by: '<S43>/Proportional Gain'
                                        */

/* Model reference registration function */
extern void Controller_initialize(const char_T **rt_errorStatus,
  RT_MODEL_Controller_T *const Controller_M, DW_Controller_f_T *localDW);
extern void Controller_Init(DW_Controller_f_T *localDW);
extern void Controller(const real32_T *rtu_T_ref, const real32_T *rtu_T1,
  real32_T *rty_Q1, DW_Controller_f_T *localDW);

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'Controller'
 * '<S1>'   : 'Controller/Discrete PID Controller2'
 * '<S2>'   : 'Controller/Discrete PID Controller2/Anti-windup'
 * '<S3>'   : 'Controller/Discrete PID Controller2/D Gain'
 * '<S4>'   : 'Controller/Discrete PID Controller2/External Derivative'
 * '<S5>'   : 'Controller/Discrete PID Controller2/Filter'
 * '<S6>'   : 'Controller/Discrete PID Controller2/Filter ICs'
 * '<S7>'   : 'Controller/Discrete PID Controller2/I Gain'
 * '<S8>'   : 'Controller/Discrete PID Controller2/Ideal P Gain'
 * '<S9>'   : 'Controller/Discrete PID Controller2/Ideal P Gain Fdbk'
 * '<S10>'  : 'Controller/Discrete PID Controller2/Integrator'
 * '<S11>'  : 'Controller/Discrete PID Controller2/Integrator ICs'
 * '<S12>'  : 'Controller/Discrete PID Controller2/N Copy'
 * '<S13>'  : 'Controller/Discrete PID Controller2/N Gain'
 * '<S14>'  : 'Controller/Discrete PID Controller2/P Copy'
 * '<S15>'  : 'Controller/Discrete PID Controller2/Parallel P Gain'
 * '<S16>'  : 'Controller/Discrete PID Controller2/Reset Signal'
 * '<S17>'  : 'Controller/Discrete PID Controller2/Saturation'
 * '<S18>'  : 'Controller/Discrete PID Controller2/Saturation Fdbk'
 * '<S19>'  : 'Controller/Discrete PID Controller2/Sum'
 * '<S20>'  : 'Controller/Discrete PID Controller2/Sum Fdbk'
 * '<S21>'  : 'Controller/Discrete PID Controller2/Tracking Mode'
 * '<S22>'  : 'Controller/Discrete PID Controller2/Tracking Mode Sum'
 * '<S23>'  : 'Controller/Discrete PID Controller2/Tsamp - Integral'
 * '<S24>'  : 'Controller/Discrete PID Controller2/Tsamp - Ngain'
 * '<S25>'  : 'Controller/Discrete PID Controller2/postSat Signal'
 * '<S26>'  : 'Controller/Discrete PID Controller2/preInt Signal'
 * '<S27>'  : 'Controller/Discrete PID Controller2/preSat Signal'
 * '<S28>'  : 'Controller/Discrete PID Controller2/Anti-windup/Disc. Clamping Parallel'
 * '<S29>'  : 'Controller/Discrete PID Controller2/Anti-windup/Disc. Clamping Parallel/Dead Zone'
 * '<S30>'  : 'Controller/Discrete PID Controller2/Anti-windup/Disc. Clamping Parallel/Dead Zone/Enabled'
 * '<S31>'  : 'Controller/Discrete PID Controller2/D Gain/Disabled'
 * '<S32>'  : 'Controller/Discrete PID Controller2/External Derivative/Disabled'
 * '<S33>'  : 'Controller/Discrete PID Controller2/Filter/Disabled'
 * '<S34>'  : 'Controller/Discrete PID Controller2/Filter ICs/Disabled'
 * '<S35>'  : 'Controller/Discrete PID Controller2/I Gain/Internal Parameters'
 * '<S36>'  : 'Controller/Discrete PID Controller2/Ideal P Gain/Passthrough'
 * '<S37>'  : 'Controller/Discrete PID Controller2/Ideal P Gain Fdbk/Disabled'
 * '<S38>'  : 'Controller/Discrete PID Controller2/Integrator/Discrete'
 * '<S39>'  : 'Controller/Discrete PID Controller2/Integrator ICs/Internal IC'
 * '<S40>'  : 'Controller/Discrete PID Controller2/N Copy/Disabled wSignal Specification'
 * '<S41>'  : 'Controller/Discrete PID Controller2/N Gain/Disabled'
 * '<S42>'  : 'Controller/Discrete PID Controller2/P Copy/Disabled'
 * '<S43>'  : 'Controller/Discrete PID Controller2/Parallel P Gain/Internal Parameters'
 * '<S44>'  : 'Controller/Discrete PID Controller2/Reset Signal/Disabled'
 * '<S45>'  : 'Controller/Discrete PID Controller2/Saturation/Enabled'
 * '<S46>'  : 'Controller/Discrete PID Controller2/Saturation Fdbk/Disabled'
 * '<S47>'  : 'Controller/Discrete PID Controller2/Sum/Sum_PI'
 * '<S48>'  : 'Controller/Discrete PID Controller2/Sum Fdbk/Disabled'
 * '<S49>'  : 'Controller/Discrete PID Controller2/Tracking Mode/Disabled'
 * '<S50>'  : 'Controller/Discrete PID Controller2/Tracking Mode Sum/Passthrough'
 * '<S51>'  : 'Controller/Discrete PID Controller2/Tsamp - Integral/TsSignalSpecification'
 * '<S52>'  : 'Controller/Discrete PID Controller2/Tsamp - Ngain/Passthrough'
 * '<S53>'  : 'Controller/Discrete PID Controller2/postSat Signal/Forward_Path'
 * '<S54>'  : 'Controller/Discrete PID Controller2/preInt Signal/Internal PreInt'
 * '<S55>'  : 'Controller/Discrete PID Controller2/preSat Signal/Forward_Path'
 */
#endif                                 /* Controller_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
