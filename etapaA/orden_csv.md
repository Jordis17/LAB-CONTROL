# Orden de columnas de los CSV de la Etapa A

Todos los CSV tienen una fila de encabezado, separador coma y punto decimal. Los generan
`A1_modelo_no_lineal_BoP.m` y `A2_linealizar_BoP.m` en `etapaA/resultados/`.

Convención de signos: error = lineal − no lineal.

## A1

| Archivo | Columnas |
|---|---|
| `A1_cinematica_servo_plato.csv` | `phi_deg` ángulo del servo X (servo Y en neutro) · `th_deg` inclinación del plato (cinemática directa) · `th_recta_deg` pendiente del neutro × phi · `desviacion_deg` = th − recta |
| `A1_acople_mecanismo.csv` | `thx_pedido_deg`, `thy_pedido_deg` · `phix_deg`, `phiy_deg` servos calculados eje por eje · `err_thx_deg`, `err_thy_deg` inclinación real 3D − pedida |
| `A1_verificacion_parabola.csv` | `t_s` · `x_modelo_mm` · `x_teorico_mm` = −½·c·g·sin(2°)·t² · `error_mm` |
| `A1_error_camara.csv` | `th_deg` · `x_mm` posición sobre el plato · `Xm_mm` lo que mide la cámara · `Xm_menos_x_mm` · `Xm_menos_lineal_mm` = Xm − (x − h·th) |

## A2

| Archivo | Columnas |
|---|---|
| `A2_comparacion_A01_rapida.csv`, `A2_comparacion_A01_lenta.csv`, `A2_comparacion_A10_rapida.csv`, `A2_comparacion_A10_lenta.csv` | `t_s` · `thx_deg` · `thxd_deg_s` · `x_nl_mm` · `x_li_mm` · `err_x_mm` · `Xm_nl_mm` · `Xm_li_mm` · `err_Xm_mm` · `eacc_total_mm_s2` · `eacc_sen_mm_s2` · `eacc_centrif_mm_s2` · `eacc_resto_mm_s2` |
| `A2_comparacion_2ejes.csv` | `t_s` · `thx_deg` · `thy_deg` · `x_nl_mm` · `x_li_mm` · `y_nl_mm` · `y_li_mm` · `err_x_mm` · `err_y_mm` · `dx_acople_mm` · `dy_acople_mm` (no lineal con 2 ejes − no lineal con 1 eje) |
| `A2_barrido_amplitud.csv` | `A_deg` · `modo_1rapida_2lenta` · `T_s` · `tr_s` · `max_thd_deg_s` · `max_x_nl_mm` · `max_err_x_mm` · `err_rel_x_pct` · `rmse_x_mm` · `max_err_Xm_mm` · `err_rel_Xm_pct` · `th_eq_sen_deg` · `th_eq_centrif_deg` |

## Archivos .mat

| Archivo | Variable | Contenido |
|---|---|---|
| `A1_resultados.mat` | `A1` | `P`, pendiente del mecanismo, alcance, error de la parábola, error de acople y error de la cámara |
| `A2_modelo_lineal.mat` | `A2` | `P`, `L` (modelo lineal: A, B, C, D, num/den, ceros), modelos discretos sin y con retardo, jacobianos, casos, barrido, rango válido y tabla del término centrífugo |
