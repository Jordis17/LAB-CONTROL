# Orden de columnas de los CSV de la Etapa C

Todos en `etapaC/resultados/`, con fila de encabezado, separador coma y punto decimal.

| Archivo | Columnas |
|---|---|
| `C1_kalman.csv` | `sigma_a_mm_s2` · `K1` · `K2_1_s` · `std_xhat_mm` · `std_vhat_mm_s` (solo por ruido de medición) · `std_th_deg` (temblor del plato debido a ese ruido) · `PM_deg` · `GM_sup_dB` |
| `C1_bode.csv` | `w_rad_s` · `mag_dB` · `fase_deg` · `re_L` · `im_L`: ganancia de lazo L(e^{jωTs}) nominal |
| `C1_robustez.csv` | `caso` (1 nominal, 2 retardo 60 ms, 3 retardo 90 ms, 4 retardo 120 ms, 5 c = 0,685, 6 h_sup = 40, 7 h_sup = 60) · `PM_deg` · `GM_sup_dB` · `GM_inf_dB` · `wc_rad_s` · `radio_max` |
| `C1_estructuras.csv` | `estructura_1PD_2PID_3PIDcond` · `ts_s` · `Mp_pct` · `ess_mm` · `th_max_deg` · `desnivel_max_x_mm` · `desnivel_ess_mm` · `std_th_ss_deg` |
| `C1_estructuras_regulacion.csv`, `C1_estructuras_desnivel.csv` | `t_s` (instante de captura) · `xh_PD_mm` · `th_PD_rad` · `xh_PID_mm` · `th_PID_rad` · `xh_PIDcond_mm` · `th_PIDcond_rad` |

`C1_controlador.mat`: `Ctrl` (Kp, Ki, Kd [rad/mm, rad/(mm·s), rad/(mm/s)], Ts, th_lim [rad],
e_clip [mm], v_int [mm/s], Nq, Kf, kalman_sigma_a, kalman_sigma_m, te, zeta, a, w, Ti,
omega_n_servo, margenes, P_diseno, fecha) y `Rq` (requisitos y definiciones).
