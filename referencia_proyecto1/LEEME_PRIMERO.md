# Referencia del Proyecto 1 (TCLab) para el proyecto final

Este paquete existe para que la IA del proyecto final sepa **qué se hizo y con qué formato** en el
Proyecto 1. La planta es otra y el controlador será otro: esto es referencia de método y de
formato, **no** de resultados.

## Cómo debe leer esto la IA

1. Las reglas de trabajo del proyecto final están en el `CLAUDE.md` de la **raíz del proyecto**
   (`Proyecto FINAL LAB Control/CLAUDE.md`), con la sección 0 ya llena. Mandan sobre todo lo
   demás de este paquete. La plantilla sin llenar quedó renombrada como
   `03_plantilla_proyecto_final/plantilla_CLAUDE_sin_llenar.md.txt` para que Claude Code no la
   cargue como instrucciones; no usarla.
2. Usar `02_datos_y_trazabilidad/Datos_Lab1_TCLab_por_actividad.md` para ver **qué se registró en
   cada etapa** y con qué nivel de detalle. Es el mejor ejemplo del formato de registro.
3. Usar `01_informe/` como referencia del documento final: estructura de secciones, tablas,
   figuras y nivel de redacción.
4. Usar `04_matlab_simulink/` para ver **cómo se implementó**: formato de los scripts (cómo se
   parametrizan, cómo imprimen en consola, cómo guardan los `.mat`), estructura de los modelos de
   Simulink y configuración de generación de código. Si solo se van a revisar dos cosas, que sean
   `scripts/A5_identificar_FOPDT_TCLab.m` y `modelos/Controller.slx`.

## Advertencia

**Ningún valor numérico de este paquete aplica al proyecto final.** Los parámetros del modelo, las
ganancias del controlador y las métricas son de una planta térmica distinta. La IA no debe
reusarlos, ni tomarlos como punto de partida, ni ajustar los nuevos para que se parezcan.

Tampoco se traslada automáticamente el **método**: el Proyecto 1 usó un modelo de primer orden con
tiempo muerto, estable en lazo abierto, y reglas SIMC. Si la planta nueva no cumple esas hipótesis
(por ejemplo si es inestable en lazo abierto, integradora, de orden superior o MIMO), hay que elegir
otro método de diseño y justificarlo. Ver la sección 3.3 de `CLAUDE.md`.

## Contenido

```
01_informe/
  informe_proyecto1_compilado.pdf   el informe final, 9 páginas, formato IEEE
  latex/                            fuente completa
    informe.tex, preambulo.tex, referencias.bib
    sec/01…08                       una sección por archivo
    informe_completo.tex            la misma cosa en un solo archivo, sin BibTeX
  datos_graficas_csv/               los CSV que alimentan las figuras (pgfplots)

02_datos_y_trazabilidad/
  Datos_Lab1_TCLab_por_actividad.md  todos los resultados, ordenados por actividad
  FALTANTES_Lab1_TCLab.md            inventario de evidencia + textos redactados por actividad
  verificacion_instructivo_informe.md  auditoría del informe contra el instructivo de formato

03_plantilla_proyecto_final/
  CLAUDE.md                          reglas de trabajo del proyecto final (COMPLETAR sección 0)

04_matlab_simulink/                  archivos de MATLAB/Simulink del Proyecto 1 — ver inventario
  scripts/                           17 scripts y funciones (.m)
  modelos/                           8 modelos de Simulink (.slx)
  resultados_mat/                    12 archivos de resultados (.mat), con las subcarpetas
                                     Resultados_experimentos/ y Resultados_control/ que usan los scripts
  codigo_generado/                   5 archivos C del controlador
  guias/                             los 2 PDF del curso
  figuras_png/                       4 PNG de figuras que no tienen CSV equivalente
```

## Inventario de `04_matlab_simulink/`

Copiado de `C:\Claude\INFORME 1` el 2026-11-02. Los archivos conservan su fecha de modificación
original. Las descripciones salen del encabezado de cada archivo. Los `.slx` no tienen descripción
propia, así que su línea se dedujo de las anotaciones, los bloques de primer nivel y la
configuración del modelo.

Recordatorio: `A7_SIMC_controller_TCLab.m`, `A8_init_TCLab_SIMC.m`, el código generado y todos los
`.mat` traen escritos los valores del Proyecto 1 (K, τ, θ, ganancias). Aplica la advertencia de
arriba.

### `scripts/` (17)

| Archivo | Para qué sirve |
|---|---|
| `A1_simular_modelo_no_lineal_TCLab.m` | Actividad 1: simula T1 con el modelo no lineal (balance de energía con convección y radiación, temperaturas en kelvin) para Q1 = 50 % constante. |
| `A2_linealizar_modelo_TCLab.m` | Actividad 2: calcula el equilibrio para Q̄ = 50 %, obtiene γ y β, saca K y τ, arma ΔT(s)/ΔQ(s) y compara el modelo lineal con el no lineal ante una perturbación pequeña y otra grande. |
| `A3_prueba_LED_TCLab.m` | Función: prueba segura del LED del TCLab (tres parpadeos por PWM en D9) con `arduino(puerto,"Leonardo")` y apagado garantizado con `onCleanup`. |
| `A3_prueba_sensores_TCLab.m` | Función: lee T1 y T2 durante un tiempo dado sin activar los calentadores. |
| `A3_prueba_Q1_TCLab.m` | Función: prueba funcional del calentador Q1 al 30 % (reposo, calentamiento y enfriamiento) con límite de temperatura de 45 °C. |
| `A4_experimento_escalon_Q1_TCLab.m` | Función: aplica un escalón de Q1 (50 % por defecto, máximo 90 %), registra Q1→T1 y guarda solo el `.mat` en `Resultados_experimentos/`; no identifica ni analiza. |
| `A4_experimento_multinivel_Q1_TCLab.m` | Función: aplica el perfil multinivel de Q1 (0-20-40-10-50-30-0 %) y guarda el `.mat` en `Resultados_experimentos/`; no identifica ni analiza. |
| `A4_graficar_experimento_Q1_TCLab.m` | Función: abre con un selector un `.mat` de experimento (escalón o multinivel) y vuelve a generar la figura de entrada y salida. |
| `A5_identificar_FOPDT_TCLab.m` | Función: identifica K, τ y θ de un modelo FOPDT en variables de desviación a partir de un `.mat` de experimento (tabla con `Tiempo_s`, `Q1_pct`, `T1_C`). |
| `A6_validar_FOPDT_TCLab.m` | Función: valida un FOPDT fijo (la salida de A5 o un vector `[K tau theta]`) contra otro experimento, sin reajustar sus parámetros. |
| `A7_SIMC_controller_TCLab.m` | Actividad 7: calcula Kp, Ti y Ki del PI por SIMC a partir del FOPDT nominal y guarda el resultado en `Resultados_control/PI_SIMC_<unidad>_<fecha>.mat`. |
| `A8_init_TCLab_SIMC.m` | Inicializa planta FOPDT (dinámica y retardo por separado), Ts, discretización ZOH, retardo entero, condiciones de operación, límites y parámetros del PI. Es el `InitFcn` de los modelos MIL, SIL y PIL. |
| `A8_validar_TCLab_SIMC.m` | Compara en una sola simulación las tres variantes MIL del PI–SIMC (ideal, saturado sin anti-windup, saturado con anti-windup por clamping) y calcula sus métricas a partir de las variables To Workspace. |
| `A9_metricas_CSD.m` | Calcula tr, ts, Mp, ess, Tmax, Q1min y Q1max para PI–SIMC con AW y PI–CSD con AW, con las mismas definiciones que `A8_validar_TCLab_SIMC.m`. |
| `A10_comparar_Normal_SIL.m` | Comparación back-to-back Normal–SIL a partir de `Q1_Normal`, `T1_Normal`, `Q1_SIL`, `T1_SIL` (timeseries). |
| `A11_comparar_Normal_PIL.m` | Comparación back-to-back Normal–PIL a partir de `Q1_Normal`, `T1_Normal`, `Q1_PIL`, `T1_PIL`; se corre a mano después de la simulación PIL. |
| `A12_visualizar_Implementacion_TCLab.m` | Grafica `T_ref`, `T1` y `Q1` desde `logsout` después del experimento físico con Monitor & Tune. |

Nota: los seis archivos `A3_…` y `A4_…` son funciones cuyo nombre interno no coincide con el del
archivo (por ejemplo, `A3_prueba_LED_TCLab.m` declara `A3a_prueba_LED_TCLab`). MATLAB las ejecuta
por el nombre del archivo, así que se llaman como `A3_prueba_LED_TCLab("COM8")`.

### `modelos/` (8)

| Archivo | Para qué sirve |
|---|---|
| `A8_TCLab_MIL_SIMC.slx` | Banco MIL del PI–SIMC con los tres casos en paralelo (1: sin saturación, 2: saturado sin AW, 3: saturado con AW) sobre la planta FOPDT discreta con retardo. `InitFcn = A8_init_TCLab_SIMC`; sus bloques To Workspace generan las variables que lee `A8_validar_TCLab_SIMC.m`. |
| `A9_Code_preparation.slx` | Caso 3 (saturado con AW) con el controlador separado en un bloque Model (`Controller_SUT`) que referencia `Controller.slx`; paso previo a la generación de código. |
| `A9_TCLab_MIL_CSD.slx` | MIL comparativo PI–SIMC con AW frente a PI–CSD con AW, con la misma planta; genera `T1_CSD_sim` y `Q1_CSD_sim` para `A9_metricas_CSD.m`. |
| `Controller.slx` | Modelo del controlador `T_ref, T1 → Discrete PID Controller (PI) → Q1` usado en generación de código, SIL y PIL. `ert.tlc`, *Reusable function*, hardware board Arduino Uno (Atmel→AVR). |
| `Controller_implementacion.slx` | Copia de `Controller.slx` para la implementación física; hardware board Arduino Leonardo. |
| `TCLab_Test_SIL.slx` | Banco Normal–SIL: `Controller_Normal` y `Controller_SIL` referencian `Controller.slx`, cada rama con su propia planta; registra `Q1/T1_Normal` y `Q1/T1_SIL`. |
| `TCLab_Test_PIL.slx` | Banco Normal–PIL: igual al de SIL pero con `Controller_PIL` en modo Processor-in-the-loop; registra `Q1/T1_Normal` y `Q1/T1_PIL`. |
| `TCLab_Implementation.slx` | Lazo físico sobre Arduino Leonardo, sin modelo de planta. Contiene Analog Input, Gain/Bias, Moving Average, conversión a `single`, el bloque Model que referencia `Controller_implementacion`, Saturation y PWM. |

### `resultados_mat/` (12)

| Archivo | Contenido |
|---|---|
| `Resultados_experimentos/escalon_Q1_50_20260812_092703.mat` | `datos` (tabla) y `metadatos` del ensayo escalón Q1 = 50 %, guardado por `A4_experimento_escalon_Q1_TCLab.m`. |
| `Resultados_experimentos/multinivel_Q1_20260812_102549.mat` | `datos`, `perfil` y `metadatos` del ensayo multinivel, guardado por `A4_experimento_multinivel_Q1_TCLab.m`. |
| `modelos_FOPDT_04_20260812_100000.mat` | `modeloEscalon` y `modeloMultinivel`: salidas de `A5_identificar_FOPDT_TCLab`. |
| `validaciones_FOPDT_04_20260812_100000.mat` | `validacionEscalonEnMulti` y `validacionMultiEnEscalon`: salidas de `A6_validar_FOPDT_TCLab`. |
| `PI_SIMC_04_20260812_100000.mat` | `K, tau, theta, tau_c, Kp, Ti, Ki, Gc` (la estructura de `.mat` que pide la guía). |
| `Resultados_control/PI_SIMC_TCLab01_20260908_194951.mat` | Lo mismo más `Gp`, `codigoTCLab` y `origenModelo`; es el archivo que guarda `A7_SIMC_controller_TCLab.m`. |
| `PI_CSD_04.mat` | `Kp_CSD, Ki_CSD, Ti_CSD, Gc_CSD`: PI diseñado con Control System Designer. |
| `C.mat` | Espacio de trabajo guardado del diseño con Control System Designer: controlador `C` (zpk), `Gp_nom`, lazo cerrado `Tcl`, márgenes `Gm`, `Pm`, `Wcp`, datos `iddata` y modelos `idproc`. |
| `SIT_E.mat` | Modelo `idproc` (System Identification Toolbox) `SIT_E` estimado con el escalón, con los vectores de datos usados. |
| `SIT_M.mat` | Modelos `idproc` `SIT_E` y `SIT_M` (escalón y multinivel), con los vectores de datos usados. |
| `SIT_modelos.mat` | `modeloEscalonSIT` y `modeloMultinivelSIT` (`idproc`). |
| `TCLab_Test_PIL_results.mat` | `Q1_Normal`, `T1_Normal`, `Q1_PIL`, `T1_PIL` (timeseries) y la struct `A11_Resultados_Normal_PIL` con los resultados de A11. |

### `codigo_generado/` (5)

Sacados de `slprj`; no se copió el resto de esa carpeta.

| Archivo | Origen en INFORME 1 | Datos del encabezado |
|---|---|---|
| `Controller.c`, `Controller.h`, `Controller_private.h`, `Controller_types.h` | `slprj/ert/Controller/` | Generados el 9 sep 2026 13:17 para el modelo `Controller` versión 1.19; `ert.tlc`, hardware Atmel→AVR, objetivos *Execution efficiency* y *Traceability*. |
| `rtwtypes.h` | `slprj/ert/_sharedutils/` | Generado el 13 sep 2026 19:46 al compilar `Controller_implementacion` (versión 1.27); tipos para AVR (`int` de 16 bits). |

Para tener en cuenta:

- El `Controller.slx` incluido es la versión 1.20 (guardado el 9 sep a las 13:54), una revisión
  después de la que generó el código.
- `rtwtypes.h` no es de la misma compilación que `Controller.c`: la carpeta `_sharedutils` se
  regeneró al compilar `Controller_implementacion`. Las dos compilaciones son para Atmel→AVR, así
  que las definiciones de tipos deberían coincidir (inferencia, no comprobado contra el original).
- Es la única versión del código del controlador en INFORME 1. No se encontró otra copia (por
  ejemplo, una compilación x86-64 para SIL) ni respaldos con código fuera de `slprj`.

### `guias/` (2)

| Archivo | Para qué sirve |
|---|---|
| `lab1-tclab_Lab01_MBD_TCLab.pdf` | Guía oficial del laboratorio (Model-Based Design del TCLab). |
| `lab1-tclab_Instructivo_informe.pdf` | Instructivo de formato del informe. |

### `figuras_png/` (4)

Solo las figuras que no tienen CSV equivalente.

| Archivo | Qué muestra |
|---|---|
| `Perturbacion pequena.png` | Actividad 2: modelo lineal frente al no lineal ante ΔQ = +5 % y el error de la aproximación. |
| `Perturbacion de mayor amplitud.png` | Actividad 2: lo mismo con ΔQ = +40 %. |
| `Prueba del calentador Q1.png` | Actividad 3: T1, T2 y el comando Q1 = 30 % durante la prueba del calentador. |
| `Controller.png` | Diagrama del modelo `Controller.slx` (T_ref, T1 → PI(z) → Q1). |

No se copiaron porque sí tienen CSV equivalente en `INFORME 1\Graficas`: `Entrada y temperatura.png`
(`A1_simulacion_no_lineal.csv`), `Transferencia de calor.png` y `Balance de potencia.png`
(`A1_flujos_calor.csv`). Esos dos CSV no están en `01_informe/datos_graficas_csv/`, así que la
Actividad 1 no tiene figura ni datos de figura en este paquete.

### Faltantes

De la lista pedida no faltó nada: aparecieron scripts, modelos, `.mat`, los cinco archivos de código
C, los dos PDF del curso y PNG sin CSV equivalente.

Cosas que uno esperaría y no existen en INFORME 1:

- No hay un `.mat` de resultados de SIL equivalente a `TCLab_Test_PIL_results.mat`. Los datos
  Normal–SIL solo quedan en `01_informe/datos_graficas_csv/GRAFComparacionNormalSIL.csv`.
- No hay código generado de una compilación SIL separada (ver `codigo_generado/`).

### Dejado fuera a propósito

- `slprj/` completa (solo se sacaron los cinco archivos de código), `TCLab_Implementation_ert_rtw/`
  (incluye `coder_instr_task_info.m`, que genera Simulink Coder) y `A9_TCLab_MIL_CSD.slxc`. En
  INFORME 1 no había `.asv`, `.bak`, reportes HTML ni temporales.
- El código generado de `Controller_implementacion` y `TCLab_Implementation` (sigue en `slprj/` y
  `TCLab_Implementation_ert_rtw/` de INFORME 1).
- `Controller.pdf` (el mismo diagrama que `Controller.png`), `Graficas/Orden CSV.txt` (orden de
  columnas de los CSV), `Graficas/avances.txt`, los CSV de `Graficas/` que no están en
  `01_informe/`, las carpetas `Informe/`, `Informe_IEEE/` y `Claude outputs/`, e
  `Informe_IEEE_latex.zip` (el informe ya está en `01_informe/`).

## Convenciones que sí conviene conservar

- **Un CSV por figura**, exportado desde MATLAB con `writematrix`/`writetable`, y un archivo de
  texto que documente el orden de las columnas. Las gráficas del informe se hacen en LaTeX con
  pgfplots leyendo esos CSV, no con capturas de MATLAB.
- **El modelo del controlador que se usa en SIL y PIL no se toca.** Cualquier variante para
  implementación es una copia con otro nombre.
- **Los bancos de prueba SIL y PIL son archivos separados**, cada rama con su propia copia de la
  planta.
- **Un archivo de estado** del proyecto, actualizado al cerrar cada etapa, con parámetros, métricas,
  decisiones y ubicación de archivos.
