# Orden de columnas de los CSV de la Etapa D

Todos en `etapaD/resultados/`, con fila de encabezado, separador coma y punto decimal.

| Archivo | Columnas |
|---|---|
| `D_caso_<nombre>.csv` (una fila por cuadro de cámara) | `t_cap_s` captura · `t_calc_s` cálculo en la ESP32 · `r_x_mm`, `r_y_mm` · `y_x_mm`, `y_y_mm` medición con ruido · `xh_x_mm`, `xh_y_mm` · `vh_x_mm_s`, `vh_y_mm_s` (Kalman) · `thcmd_x_deg`, `thcmd_y_deg` · `u_x_deg`, `u_y_deg` (sin saturar) · `sat_x`, `sat_y` (0/1) · `I_x_deg`, `I_y_deg` · `x_plato_mm`, `y_plato_mm` · `thx_plato_deg`, `thy_plato_deg` (del modelo, interpolados a t_cap) |
| `D6_lineal_vs_no_lineal_D1.csv`, `D6_lineal_vs_no_lineal_D2.csv` | `t_s` · `xh_lineal_mm` · `xh_no_lineal_mm` · `dif_mm` · `th_lineal_deg` · `th_no_lineal_deg` |
| `D1_metricas.csv` | `caso` · `eje` · `x0_mm` · `r_mm` · `tr_s` · `ts_s` · `Mp_pct` · `ess_mm` · `max_abs_xhat_mm` · `max_abs_x_plato_mm` · `th_min_deg` · `th_max_deg` · `pct_saturado` · `t_saturado_s` · `std_th_ss_deg` |

Casos (`<nombre>`): `D1_requisitos`, `D2_sin_saturacion`, `D2_sat_sin_AW`, `D2_sat_con_AW`,
`D2b_PIDclasico_sat_sin_AW`, `D2b_PIDclasico_sat_con_AW`, `D3_desnivel`, `D4_dos_ejes`.
Las métricas siguen las definiciones de `etapaC/C0_requisitos_BoP.m`; con un cambio de
referencia menor a 5 mm, tr, ts y Mp quedan en NaN.
