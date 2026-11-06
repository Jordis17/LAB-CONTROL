# Tabla de correspondencia modelo ↔ código — Controller_BoP

Código generado el 2026-11-06 con MATLAB R2026a (vigente: modelo v1.2, después de E3; respecto de v1.1 solo cambian la fecha y la versión del encabezado, así que las líneas citadas siguen valiendo) (Simulink Coder 26.1, `ert.tlc`, *Reusable
function*, Generic → 32-bit Embedded Processor). Archivos en `codigo_generado/`. Las líneas son
de `Controller_BoP.c` y `Controller_BoP.h`.

## Interfaz

| Modelo (`Controller_BoP.slx`) | Código | Tipo |
|---|---|---|
| Inport 1 `r_mm` | argumento `Controller_BoP_U_r_mm` de `Controller_BoP_step` (.c:63–67) | `real_T` (double) |
| Inport 2 `x_hat_mm` | `Controller_BoP_U_x_hat_mm` | `real_T` |
| Inport 3 `v_hat_mm_s` | `Controller_BoP_U_v_hat_mm_s` | `real_T` |
| Inport 4 `habilitado` | `Controller_BoP_U_habilitado` | `boolean_T` |
| Outport 1 `th_cmd_rad` | `*Controller_BoP_Y_th_cmd_rad` | `real_T` |
| Outport 2 `I_rad` | `*Controller_BoP_Y_I_rad` (.c:134) | `real_T` |
| Outport 3 `saturado` | `*Controller_BoP_Y_saturado` | `boolean_T` |
| Llamada por cuadro (Ts) | `Controller_BoP_step(M, ...)` | — |
| Inicialización | `Controller_BoP_initialize(M, ...)` (.c:138–166) | — |

*Reusable function*: el estado viaja en `RT_MODEL_Controller_BoP_T` → `dwork`. El firmware crea
**una estructura de estado por eje** y llama `Controller_BoP_step` dos veces por cuadro.

## Estado interno

| Modelo | Código |
|---|---|
| `persistent I` (integrador, rad) | `DW_Controller_BoP_T.I` (.h:47) |
| `persistent nq` (cuadros con la bola quieta) | `DW_Controller_BoP_T.nq` (.h:48), guardado como `real_T` |
| Inicialización `if isempty(I)` → 0 | `memset` del DW y `I = 0`, `nq = 0` en `_initialize` (.c:149, 164–165) |

## Parámetros calibrables (`Simulink.Parameter`, ExportedGlobal)

| Modelo | Código | Valor generado |
|---|---|---|
| `BoP_Kp` | `real_T BoP_Kp` (.c:37; `extern` en .h:73) | 5,9548883e-4 rad/mm |
| `BoP_Ki` | `BoP_Ki` (.c:33) | 3,9699255e-4 rad/(mm·s) |
| `BoP_Kd` | `BoP_Kd` (.c:29) | 4,5161873e-4 rad/(mm/s) |
| `BoP_Ts` | `BoP_Ts` (.c:45) | 0,0333… s |
| `BoP_th_lim` | `BoP_th_lim` (.c:53) | 0,17453 rad (10°) |
| `BoP_e_clip` | `BoP_e_clip` (.c:49) | 30 mm |
| `BoP_v_int` | `BoP_v_int` (.c:57) | 25 mm/s |
| `BoP_Nq` | `BoP_Nq` (.c:41) | 4 |

Los valores coinciden con `etapaC/resultados/C1_controlador.mat` (corrida en MATLAB).

## Algoritmo (`bop_ley_control.m` → `Controller_BoP_step`)

| Línea de `bop_ley_control.m` | Código | Comentario |
|---|---|---|
| `if habilitado` (en `ley_control_BoP_bloque`) | `if (Controller_BoP_U_habilitado)` (.c:88) | |
| `eps_ = x_hat - r` | `eps_ = x_hat - r` (.c:89) | |
| `u = Kp*eps_ + I + Kd*v_hat` | `a__1 = (BoP_Kp*eps_ + DW->I) + BoP_Kd*v_hat` (.c:90–91) | Mismo orden de operaciones |
| `th_cmd = min(max(u, -th_lim), th_lim)` | `fmin(fmax(a__1, -BoP_th_lim), BoP_th_lim)` (.c:92) | **Saturación** |
| `saturado = (th_cmd ~= u)` | `(*th_cmd != a__1)` (.c:93) | Comparación exacta, intencional (Advisor, advertencia 5) |
| `nq_n = nq + 1` o `0` según `abs(v_hat) < v_int` | `if (fabs(v_hat) < BoP_v_int) nq++ else nq = 0` (.c:94–98) | Integración condicional |
| `sign(eps_)`, `sign(u)` | `tmp` y `a__1` con −1/0/1 y manejo de NaN (.c:100–114) | Los `rtIsNaN` y `rtNaN` vienen de `sign()` de MATLAB; por eso aparecen `rt_nonfinite.c` y `rtGetNaN.c` |
| `congelar = usar_aw && saturado && sign(eps_) == sign(u)`; `integra = ~congelar && nq_n >= max(Nq,1)` | `(!sat \|\| !(tmp == a__1)) && (nq >= fmax(BoP_Nq, 1.0))` (.c:116–117) | **Anti-windup por clamping** + integración condicional (De Morgan de `~congelar`; `usar_aw = true` fijo en el bloque) |
| `I_n = I + Ki*Ts*sat(eps_, ±e_clip)` | `DW->I += BoP_Ki*BoP_Ts*fmin(fmax(eps_, -BoP_e_clip), BoP_e_clip)` (.c:118–119) | Integrador con el error recortado |
| rama `habilitado = false`: `th_cmd = 0`, `I = 0`, `nq = 0`, `saturado = false` | .c:121–129 | |
| `I_est = I` | `*Y_I_rad = DW->I` (.c:134) | Integrador ya actualizado, igual que el MIL |

## Comprobaciones

- **Ausencia de la planta:** no hay `sin`, `cos`, `acos` ni `atan2`, ni restos de la dinámica de
  la bola o de la cinemática (E2, inspección automática: PASS).
- **Tipos:** todo `real_T` (double) y `boolean_T`.
- **Ejecución del código C:** se compiló `Controller_BoP.c` con gcc en una PC x86-64 (Claude,
  2026-11-06) y se le pasaron las entradas de los 5 ensayos de E1 (`resultados/E1_caso_*.csv`).
  Diferencia máxima con el MIL: 4,2e-11 rad en th_cmd, 5,6e-12 rad en I y 0 diferencias en
  `saturado`. No da exactamente 0 porque los CSV guardan las entradas con 10 cifras
  significativas; el SIL (Etapa F) compara con la precisión completa. No reemplaza al SIL.

## Observaciones para la implementación (Etapa H)

1. **`nq` es double y crece sin tope** mientras la bola está quieta. En double no hay problema
   práctico (es exacto hasta 2^53 cuadros). Si en la copia para la ESP32 se pasa a single, se
   pierde precisión pasados ~16 millones de cuadros (unos 6 días a 30 fps). No afecta una
   prueba, pero conviene anotarlo.
2. **Double en la ESP32:** la FPU del ESP32 es de precisión simple; double se emula por
   software. Para 2 llamadas cada 33 ms sobra tiempo, pero si se pasa a single se hace en la
   copia y se verifica aparte, sin tocar este modelo.
3. **`ert_main.c`** es el ejemplo de `main` que genera Embedded Coder. El firmware no lo usa.
4. El encabezado dice "Validation result: Not run": el chequeo de objetivos no se corre al
   compilar. El Advisor se corrió aparte (`resultados/advisor/`).
