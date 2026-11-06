/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: Controller_BoP.h
 *
 * Code generated for Simulink model 'Controller_BoP'.
 *
 * Model version                  : 1.1
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Fri Nov  6 10:15:43 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Generic->32-bit Embedded Processor
 * Code generation objectives:
 *    1. Execution efficiency
 *    2. Traceability
 * Validation result: Not run
 */

#ifndef Controller_BoP_h_
#define Controller_BoP_h_
#ifndef Controller_BoP_COMMON_INCLUDES_
#define Controller_BoP_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "rt_nonfinite.h"
#include "math.h"
#endif                                 /* Controller_BoP_COMMON_INCLUDES_ */

#include "Controller_BoP_types.h"
#include "rtGetNaN.h"
#include <string.h>
#include "rt_defines.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block states (default storage) for system '<Root>' */
typedef struct {
  real_T I;                            /* '<Root>/ley_control' */
  real_T nq;                           /* '<Root>/ley_control' */
} DW_Controller_BoP_T;

/* Real-time Model Data Structure */
struct tag_RTM_Controller_BoP_T {
  const char_T * volatile errorStatus;
  DW_Controller_BoP_T *dwork;
};

/*
 * Exported Global Parameters
 *
 * Note: Exported global parameters are tunable parameters with an exported
 * global storage class designation.  Code generation will declare the memory for
 * these parameters and exports their symbols.
 *
 */
extern real_T BoP_Kd;                  /* Variable: BoP_Kd
                                        * Referenced by: '<Root>/BoP_Kd'
                                        * Ganancia derivativa, sobre v_hat del Kalman [rad/(mm/s)]
                                        */
extern real_T BoP_Ki;                  /* Variable: BoP_Ki
                                        * Referenced by: '<Root>/BoP_Ki'
                                        * Ganancia integral continua [rad/(mm s)]
                                        */
extern real_T BoP_Kp;                  /* Variable: BoP_Kp
                                        * Referenced by: '<Root>/BoP_Kp'
                                        * Ganancia proporcional [rad/mm]
                                        */
extern real_T BoP_Nq;                  /* Variable: BoP_Nq
                                        * Referenced by: '<Root>/BoP_Nq'
                                        * Cuadros seguidos con la bola quieta para integrar [-]
                                        */
extern real_T BoP_Ts;                  /* Variable: BoP_Ts
                                        * Referenced by: '<Root>/BoP_Ts'
                                        * Periodo usado en la integral [s]
                                        */
extern real_T BoP_e_clip;              /* Variable: BoP_e_clip
                                        * Referenced by: '<Root>/BoP_e_clip'
                                        * Recorte del error que entra al integrador [mm]
                                        */
extern real_T BoP_th_lim;              /* Variable: BoP_th_lim
                                        * Referenced by: '<Root>/BoP_th_lim'
                                        * Saturacion de la inclinacion pedida [rad]
                                        */
extern real_T BoP_v_int;               /* Variable: BoP_v_int
                                        * Referenced by: '<Root>/BoP_v_int'
                                        * Umbral de bola quieta [mm/s]
                                        */

/* Model entry point functions */
extern void Controller_BoP_initialize(RT_MODEL_Controller_BoP_T *const
  Controller_BoP_M, real_T *Controller_BoP_U_r_mm, real_T
  *Controller_BoP_U_x_hat_mm, real_T *Controller_BoP_U_v_hat_mm_s, boolean_T
  *Controller_BoP_U_habilitado, real_T *Controller_BoP_Y_th_cmd_rad, real_T
  *Controller_BoP_Y_I_rad, boolean_T *Controller_BoP_Y_saturado);
extern void Controller_BoP_step(RT_MODEL_Controller_BoP_T *const
  Controller_BoP_M, real_T Controller_BoP_U_r_mm, real_T
  Controller_BoP_U_x_hat_mm, real_T Controller_BoP_U_v_hat_mm_s, boolean_T
  Controller_BoP_U_habilitado, real_T *Controller_BoP_Y_th_cmd_rad, real_T
  *Controller_BoP_Y_I_rad, boolean_T *Controller_BoP_Y_saturado);
extern void Controller_BoP_terminate(RT_MODEL_Controller_BoP_T *const
  Controller_BoP_M);

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
 * '<Root>' : 'Controller_BoP'
 * '<S1>'   : 'Controller_BoP/ley_control'
 */
#endif                                 /* Controller_BoP_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
