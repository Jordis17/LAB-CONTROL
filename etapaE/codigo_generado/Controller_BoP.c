/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: Controller_BoP.c
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

#include "Controller_BoP.h"
#include <math.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include <string.h>

/* Exported block parameters */
real_T BoP_Kd = 0.00045161873056426543;/* Variable: BoP_Kd
                                        * Referenced by: '<Root>/BoP_Kd'
                                        * Ganancia derivativa, sobre v_hat del Kalman [rad/(mm/s)]
                                        */
real_T BoP_Ki = 0.00039699255499671724;/* Variable: BoP_Ki
                                        * Referenced by: '<Root>/BoP_Ki'
                                        * Ganancia integral continua [rad/(mm s)]
                                        */
real_T BoP_Kp = 0.00059548883249507583;/* Variable: BoP_Kp
                                        * Referenced by: '<Root>/BoP_Kp'
                                        * Ganancia proporcional [rad/mm]
                                        */
real_T BoP_Nq = 4.0;                   /* Variable: BoP_Nq
                                        * Referenced by: '<Root>/BoP_Nq'
                                        * Cuadros seguidos con la bola quieta para integrar [-]
                                        */
real_T BoP_Ts = 0.033333333333333333;  /* Variable: BoP_Ts
                                        * Referenced by: '<Root>/BoP_Ts'
                                        * Periodo usado en la integral [s]
                                        */
real_T BoP_e_clip = 30.0;              /* Variable: BoP_e_clip
                                        * Referenced by: '<Root>/BoP_e_clip'
                                        * Recorte del error que entra al integrador [mm]
                                        */
real_T BoP_th_lim = 0.17453292519943295;/* Variable: BoP_th_lim
                                         * Referenced by: '<Root>/BoP_th_lim'
                                         * Saturacion de la inclinacion pedida [rad]
                                         */
real_T BoP_v_int = 25.0;               /* Variable: BoP_v_int
                                        * Referenced by: '<Root>/BoP_v_int'
                                        * Umbral de bola quieta [mm/s]
                                        */

/* Model step function */
void Controller_BoP_step(RT_MODEL_Controller_BoP_T *const Controller_BoP_M,
  real_T Controller_BoP_U_r_mm, real_T Controller_BoP_U_x_hat_mm, real_T
  Controller_BoP_U_v_hat_mm_s, boolean_T Controller_BoP_U_habilitado, real_T
  *Controller_BoP_Y_th_cmd_rad, real_T *Controller_BoP_Y_I_rad, boolean_T
  *Controller_BoP_Y_saturado)
{
  DW_Controller_BoP_T *Controller_BoP_DW = Controller_BoP_M->dwork;
  real_T a__1;
  real_T eps_;
  real_T tmp;

  /* MATLAB Function: '<Root>/ley_control' incorporates:
   *  Constant: '<Root>/BoP_Kd'
   *  Constant: '<Root>/BoP_Ki'
   *  Constant: '<Root>/BoP_Kp'
   *  Constant: '<Root>/BoP_Nq'
   *  Constant: '<Root>/BoP_Ts'
   *  Constant: '<Root>/BoP_e_clip'
   *  Constant: '<Root>/BoP_th_lim'
   *  Constant: '<Root>/BoP_v_int'
   *  Inport: '<Root>/habilitado'
   *  Inport: '<Root>/r_mm'
   *  Inport: '<Root>/v_hat_mm_s'
   *  Inport: '<Root>/x_hat_mm'
   */
  if (Controller_BoP_U_habilitado) {
    eps_ = Controller_BoP_U_x_hat_mm - Controller_BoP_U_r_mm;
    a__1 = (BoP_Kp * eps_ + Controller_BoP_DW->I) + BoP_Kd *
      Controller_BoP_U_v_hat_mm_s;
    *Controller_BoP_Y_th_cmd_rad = fmin(fmax(a__1, -BoP_th_lim), BoP_th_lim);
    *Controller_BoP_Y_saturado = (*Controller_BoP_Y_th_cmd_rad != a__1);
    if (fabs(Controller_BoP_U_v_hat_mm_s) < BoP_v_int) {
      Controller_BoP_DW->nq++;
    } else {
      Controller_BoP_DW->nq = 0.0;
    }

    if (rtIsNaN(eps_)) {
      tmp = (rtNaN);
    } else if (eps_ < 0.0) {
      tmp = -1.0;
    } else {
      tmp = (eps_ > 0.0);
    }

    if (rtIsNaN(a__1)) {
      a__1 = (rtNaN);
    } else if (a__1 < 0.0) {
      a__1 = -1.0;
    } else {
      a__1 = (a__1 > 0.0);
    }

    if ((!*Controller_BoP_Y_saturado || !(tmp == a__1)) &&
        (Controller_BoP_DW->nq >= fmax(BoP_Nq, 1.0))) {
      Controller_BoP_DW->I += BoP_Ki * BoP_Ts * fmin(fmax(eps_, -BoP_e_clip),
        BoP_e_clip);
    }
  } else {
    /* Outport: '<Root>/th_cmd_rad' */
    *Controller_BoP_Y_th_cmd_rad = 0.0;
    Controller_BoP_DW->I = 0.0;
    Controller_BoP_DW->nq = 0.0;

    /* Outport: '<Root>/saturado' */
    *Controller_BoP_Y_saturado = false;
  }

  /* Outport: '<Root>/I_rad' incorporates:
   *  MATLAB Function: '<Root>/ley_control'
   */
  *Controller_BoP_Y_I_rad = Controller_BoP_DW->I;
}

/* Model initialize function */
void Controller_BoP_initialize(RT_MODEL_Controller_BoP_T *const Controller_BoP_M,
  real_T *Controller_BoP_U_r_mm, real_T *Controller_BoP_U_x_hat_mm, real_T
  *Controller_BoP_U_v_hat_mm_s, boolean_T *Controller_BoP_U_habilitado, real_T
  *Controller_BoP_Y_th_cmd_rad, real_T *Controller_BoP_Y_I_rad, boolean_T
  *Controller_BoP_Y_saturado)
{
  DW_Controller_BoP_T *Controller_BoP_DW = Controller_BoP_M->dwork;

  /* Registration code */

  /* states (dwork) */
  (void) memset((void *)Controller_BoP_DW, 0,
                sizeof(DW_Controller_BoP_T));

  /* external inputs */
  *Controller_BoP_U_r_mm = 0.0;
  *Controller_BoP_U_x_hat_mm = 0.0;
  *Controller_BoP_U_v_hat_mm_s = 0.0;
  *Controller_BoP_U_habilitado = false;

  /* external outputs */
  *Controller_BoP_Y_th_cmd_rad = 0.0;
  *Controller_BoP_Y_I_rad = 0.0;
  *Controller_BoP_Y_saturado = false;

  /* SystemInitialize for MATLAB Function: '<Root>/ley_control' */
  Controller_BoP_DW->I = 0.0;
  Controller_BoP_DW->nq = 0.0;
}

/* Model terminate function */
void Controller_BoP_terminate(RT_MODEL_Controller_BoP_T *const Controller_BoP_M)
{
  /* (no terminate code required) */
  UNUSED_PARAMETER(Controller_BoP_M);
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
