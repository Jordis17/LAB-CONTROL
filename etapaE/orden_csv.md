# Orden de columnas de los CSV de la Etapa E

Todos en `etapaE/resultados/`, con fila de encabezado, separador coma y punto decimal.

| Archivo | Columnas |
|---|---|
| `E1_equivalencia.csv` | `caso` · `eje` · Parte A (función del bloque vs MIL): `A_th_maxdif`, `A_th_rmse`, `A_th_igual`, `A_I_maxdif`, `A_I_rmse`, `A_sat_distintos` · Parte B (`Controller_BoP.slx` vs MIL): `B_th_maxdif`, `B_th_rmse`, `B_th_igual`, `B_I_maxdif`, `B_I_rmse`, `B_sat_distintos` (en rad; NaN si no se ejecutó) |
| `E1_caso_<caso>_eje<e>.csv` (solo con Simulink) | `k` · `t_s` · `r_mm` · `xh_mm` · `vh_mm_s` · `habilitado` · `th_MIL_rad` · `th_SLX_rad` · `dif_th_rad` · `I_MIL_rad` · `I_SLX_rad` · `dif_I_rad` · `sat_MIL` · `sat_SLX` |
| `E2_inspeccion.csv` | `chequeo` · `esperado` (presente/ausente) · `encontrado` (0/1) · `ocurrencias` · `resultado` (PASS/FAIL) |
