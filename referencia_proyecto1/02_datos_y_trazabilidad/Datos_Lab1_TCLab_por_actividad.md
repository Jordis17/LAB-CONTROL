# Datos del Laboratorio 1 — TCLab (EL-5409)

Registro de todos los resultados obtenidos, ordenados por actividad según
`lab1-tclab_Lab01_MBD_TCLab.pdf`.

**Todos los valores de este documento provienen de ejecuciones reales de MATLAB, Simulink o la
TCLab.** Ninguno es estimado ni supuesto.

- Unidad: **TCLab n.º 4**, puerto **COM3**
- Temperatura ambiente de referencia: **24 °C**
- Fecha de los experimentos: **12 de agosto de 2026**
- Integrantes: Abner López Méndez (2022273075), Jordi Segura Chinchilla (2022240646)
- Carpeta de trabajo: `C:\Claude\INFORME 1`

---

## Índice de actividades

| Act. | Sección de la guía | Tema |
|---|---|---|
| 1 | §4 | Modelo no lineal |
| 2 | §5 | Linealización en Q = 50 % |
| 3 | §6 | Verificación previa de la planta |
| 4 | §7 | Experimentos de identificación |
| 5 | §8 | Identificación de modelos FOPDT |
| 6 | §9 | Validación cruzada y selección del nominal |
| 7 | §10 | Diseño del PI mediante SIMC |
| 8 | §11 | Evaluación Model-in-the-Loop |
| 9 | §12 | Diseño alternativo con Control System Designer |
| 10 | §13 | Definición del sistema bajo prueba |
| 11 | §14 | Preparación del controlador para generación de código |
| 12 | §15 | Generación e inspección del código C |
| 13 | §16 | Construcción del banco Normal–SIL |
| 14 | §17 | Ejecución y comparación Normal–SIL |
| 15 | §18 | Cierre de SIL y preparación para PIL |
| 16–18 | §19–§22 | Banco PIL, configuración del target y ejecución |
| 19 | §22 | Comparación Normal–PIL |
| 20 | §23 | Cierre de la verificación PIL |
| — | §24 | Implementación física sobre la TCLab |

---

## Actividad 1 — Modelo no lineal

**Archivo:** `A1_simular_modelo_no_lineal_TCLab.m`

Simulación del balance de energía con `Q = 50 %` partiendo de temperatura ambiente.

| Resultado | Valor |
|---|---|
| Temperatura de equilibrio `T_eq` | **60,470 °C** |
| Pérdida por convección en equilibrio | **0,21879 W** |
| Pérdida por radiación en equilibrio | **0,28113 W** |
| Suma de pérdidas | 0,49993 W |
| Potencia entregada `α·Q` | 0,50000 W |
| Fracción radiativa en equilibrio | **56,23 %** |
| Fracción radiativa en t = 29 s | 52,54 % |

El balance cierra: las pérdidas igualan la potencia entregada con un residuo de 7 × 10⁻⁵ W.
La fracción radiativa crece de 52,54 % a 56,23 % conforme sube la temperatura — es el origen de la
no linealidad.

**CSV generados**

- `Graficas/A1_simulacion_no_lineal.csv` → columnas `t, Q_pct, T_C`
- `Graficas/A1_flujos_calor.csv` → columnas `t, q_conv_W, q_rad_W`

---

## Actividad 2 — Linealización en Q = 50 %

**Archivo:** `A2_linealizar_modelo_TCLab.m`

| Parámetro | Valor | Unidad |
|---|---|---|
| Punto de operación `Q̄` | 50 | % |
| Temperatura de equilibrio `T̄` | **60,4704** | °C (333,6204 K) |
| `γ` | **−7,547729 × 10⁻³** | 1/s |
| `β` | **5,000000 × 10⁻³** | °C/(%·s) |
| Constante de tiempo `τ` | **132,4902** | s |
| Ganancia estática `K` | **0,662451** | °C/% |

**Función de transferencia**

```
G(s) = 0,6625 / (132,4902 s + 1)     [°C/%]
```

### Comparación modelo no lineal vs modelo lineal

| Perturbación | T final NL | T final lineal | Error final | Error máx. | RMSE |
|---|---|---|---|---|---|
| `ΔQ = 5 %` | 63,753 °C | 63,783 °C | **0,029388 °C** | 0,029167 °C | **0,022145 °C** |
| `ΔQ = 40 %` | 85,225 °C | 86,968 °C | **1,7437 °C** | 1,7344 °C | **1,3368 °C** |

Al multiplicar la amplitud por ocho, el error crece unas sesenta veces. La aproximación lineal solo
es válida cerca del punto de operación.

**Evidencia gráfica:** `Perturbacion pequena.png`, `Perturbacion de mayor amplitud.png`
(solo existen como PNG, no hay CSV).

---

## Actividad 3 — Verificación previa de la planta

**Archivos:** `A3_prueba_LED_TCLab.m`, `A3_prueba_sensores_TCLab.m`, `A3_prueba_Q1_TCLab.m`

**Montaje:** TCLab n.º 4, COM3, 12 ago 2026 09:20, `T_amb = 24 °C`.

### Conexión y LED

Comunicación establecida sin errores. El LED responde al comando.

### Sensores

| Medición | Valor |
|---|---|
| `T1` en reposo | **24,46 °C** |
| `T2` en reposo | **24,77 °C** |
| Diferencia `ΔT12 = T1 − T2` | **−0,32 °C** |

Ambas lecturas son consistentes con la temperatura ambiente y la diferencia entre sensores es
despreciable frente al rango de trabajo.

### Calentador Q1

| Fase | Intervalo |
|---|---|
| Reposo | 0 – 9 s |
| `Q1 = 30 %` | 10 – 69 s |
| Enfriamiento | 70 – 130 s |

| Resultado | Valor |
|---|---|
| `T1` inicial | 24,76 °C |
| `T1` final del calentamiento | 32,45 °C |
| Incremento de `T1` | **+7,69 °C** |
| `T2` máxima | 26,74 °C |
| `T1` sigue subiendo hasta | **t ≈ 89 s** (19 s después de apagar Q1) |

El retraso entre apagar el calentador y el máximo de `T1` es la primera evidencia experimental del
tiempo muerto de la planta. El acoplamiento térmico hacia `T2` es débil (+2 °C frente a +7,69 °C).

**Conclusión:** las tres pruebas resultaron normales, se autorizó continuar con la identificación.

---

## Actividad 4 — Experimentos de identificación

**Archivos:** `A4_experimento_escalon_Q1_TCLab.m`, `A4_experimento_multinivel_Q1_TCLab.m`

| | Ensayo escalón | Ensayo multinivel |
|---|---|---|
| Hora de inicio | 09:27 | 10:25 |
| Entrada `Q1` | escalón 0 → 50 % | escalones sucesivos 10 → 50 % |
| `T1` inicial | **24,775 °C** | **25,269 °C** |
| Duración | **1860,11 s** | **3520,18 s** |
| Muestras | **1861** | **3521** |
| Periodo de muestreo | 1 s | 1 s |

Entre ambos ensayos se dejó enfriar la planta, de modo que las condiciones iniciales son comparables
(diferencia de 0,49 °C).

**Archivos `.mat`**

- `escalon_Q1_50_20260812_092703.mat`
- `multinivel_Q1_20260812_102549.mat`

**CSV**

- `Graficas/IdentificacionSE.csv` y `Graficas/IdentificacionSM.csv` →
  columnas `Tiempo_s, Q1_pct, T1_experimental_C, T1_modelo_C, Residuo_C`
- CSV crudos: `escalon_Q1_50_20260812_092703.csv` (separador `,`),
  `multinivel_Q1_20260812_102549.csv` (separador `;`).
  Ambos traen una columna de texto de fase que rompe pgfplots.

---

## Actividad 5 — Identificación de modelos FOPDT

**Archivo:** `A5_identificar_FOPDT_TCLab.m` · Toolbox: `procest` con estructura `P1D`

Estructura ajustada:

```
Gp(s) = K · e^(−θ s) / (τ s + 1)     [°C/%]
```

| Ensayo | Método | K (°C/%) | τ (s) | θ (s) | Ajuste (%) |
|---|---|---|---|---|---|
| Escalón | `A5_identificar_FOPDT_TCLab` | **0,979353** | **179,112** | **7,996** | **93,03** |
| Escalón | `procest` P1D | 0,979167 | 178,707 | 8,357 | 93,033 |
| Multinivel | `A5_identificar_FOPDT_TCLab` | **1,036018** | **189,532** | **1,999** | **94,53** |
| Multinivel | `procest` P1D | 1,036183 | 189,200 | 2,799 | 94,523 |

Los dos métodos coinciden en `K` y `τ` hasta la tercera cifra significativa. La única diferencia
apreciable está en `θ`: el script cuantiza el retardo a un número entero de muestras
(`ResolucionTheta_s ≈ 1 s`) mientras que `procest` lo estima como variable continua. Las diferencias
resultantes, **0,361 s** y **0,800 s**, son menores que un periodo de muestreo.

### Cómo se configuró System Identification Toolbox

- Datos en **variables de desviación** (restar el valor inicial, no la media)
- Estructura **`P1D`** — habilita explícitamente la estimación del retardo
- `InitialCondition = 'zero'`
- `Display = 'full'`

**Nota importante.** Con las señales **absolutas** la estimación converge a
`K ≈ 1,47 °C/%` y `θ = 0`. Ese valor no es la ganancia del proceso sino el cociente
`T1(∞)/ΔQ1 = 73,998/50 = 1,48`, porque el estimador debe explicar también el nivel inicial de
temperatura. Restar la media en lugar del valor inicial da `K ≈ 1,3893`, que tampoco es correcto.

**Archivos `.mat`:** `modelos_FOPDT_04_20260812_100000.mat`, `SIT_modelos.mat`

---

## Actividad 6 — Validación cruzada y selección del modelo nominal

**Archivo:** `A6_validar_FOPDT_TCLab.m`

Cada modelo se simuló con la entrada del experimento que **no** se usó para identificarlo,
manteniendo fijos `K`, `τ` y `θ`.

### Métricas completas

| Cruce | Intervalo | N | RMSE (°C) | MAE (°C) | Sesgo (°C) | SSE | R² | Ajuste (%) |
|---|---|---|---|---|---|---|---|---|
| Escalón → multinivel | completo | 3521 | 1,5957 | 1,4595 | +1,4530 | 8965,1247 | 0,98819 | 89,13 |
| Escalón → multinivel | **desde 1.er cambio** | 3401 | **1,6236** | **1,5109** | **+1,5042** | 8965,0984 | **0,98714** | **88,66** |
| Multinivel → escalón | completo | 1861 | 2,5879 | 2,3352 | −2,3348 | 12463,9903 | 0,95868 | 79,67 |
| Multinivel → escalón | **desde 1.er cambio** | 1801 | **2,6307** | **2,4127** | **−2,4126** | 12463,9774 | **0,93438** | **74,38** |

El intervalo *desde el primer cambio* es el que evalúa la respuesta dinámica; es el que se reporta
en el informe.

### Residuo del cruce escalón → multinivel, por nivel de potencia

| `Q1` | Residuo medio |
|---|---|
| 10 % | +1,29 °C |
| 20 % | +0,88 °C |
| 30 % | +1,23 °C |
| 40 % | +1,85 °C |
| 50 % | +2,20 °C |

El residuo no es ruido alrededor de cero sino un patrón que crece con el nivel de potencia. El
modelo del escalón **subestima** la temperatura de forma creciente; el del multinivel presenta el
sesgo opuesto (−2,41 °C, sobreestima). Ambos patrones apuntan a que la ganancia efectiva de la
planta no es constante.

### Modelo nominal seleccionado

**Se seleccionó el modelo identificado con el ensayo escalón.**

```
Gp,nom(s) = 0,979353 · e^(−7,996 s) / (179,112 s + 1)     [°C/%]
```

Justificación:

1. Mejor capacidad predictiva sobre datos independientes: RMSE 38 % menor y ajuste 14,3 puntos
   porcentuales mayor.
2. La referencia de trabajo es 60 °C, que corresponde aproximadamente a `Q1 = 50 %`, justamente la
   condición del ensayo escalón.
3. `θ = 8,00 s` equivale a ocho periodos de muestreo, lo que permite representar el retardo de forma
   exacta en la implementación discreta.

**Archivo `.mat`:** `validaciones_FOPDT_04_20260812_100000.mat`

**CSV:** `Graficas/validacionEscEnMul.csv`, `Graficas/validacionMulEnEsc.csv` →
columnas `Tiempo_s, Q1_pct, T1_experimental_C, T1_modelo_C, Residuo_C`

---

## Actividad 7 — Diseño del PI mediante SIMC

**Archivo:** `A7_SIMC_controller_TCLab.m`

Reglas aplicadas, con `τc = 2θ`:

```
Kp = (1/K) · τ / (τc + θ)
Ti = mín{ τ , 4(τc + θ) }
Ki = Kp / Ti
```

### Cálculo con θ sin redondear

| Parámetro | Valor |
|---|---|
| `τc` | 15,992 s |
| `Kp` | 7,624149 %/°C |
| `Ti` | 95,952 s |
| `Ki` | 0,079458 %/(°C·s) |

### Valores implementados (θ redondeado a 8 s = 8 muestras)

| Parámetro | Valor |
|---|---|
| `τc` | **16 s** |
| `τc + θ` | 24 s |
| `Kp` | **7,620337 %/°C** |
| `Ti` | **96 s** |
| `Ki` | **0,079379 %/(°C·s)** |

Como `4(τc + θ) = 96 s < τ = 179,1 s`, el tiempo integral queda truncado por la segunda rama de la
regla.

**Estos son los valores usados en MIL, SIL, PIL e implementación física. Decisión cerrada.**

### Márgenes de estabilidad

| Métrica | Valor |
|---|---|
| Frecuencia de cruce `ωc` | **0,0425 rad/s** |
| Margen de fase | **64,2°** |
| Margen de ganancia | **13,3 dB** |

**Archivo `.mat`:** `PI_SIMC_04_20260812_100000.mat`
(contiene `K, tau, theta, tau_c, Kp, Ti, Ki, Gc`)

---

## Actividad 8 — Evaluación Model-in-the-Loop

**Archivos:** `A8_init_TCLab_SIMC.m`, `A8_TCLab_MIL_SIMC.slx`, `A8_validar_TCLab_SIMC.m`

### Condiciones de simulación (comunes a los tres casos)

| Parámetro | Valor |
|---|---|
| `Ts` | 1 s |
| `t_final` | 1800 s |
| `T_amb` | 24 °C |
| `T_ref` | 60 °C |
| Límites de `Q1` | [0, 90] % |
| `N_delay` | 8 muestras |
| `θ_d` | 8 s |
| Solver | FixedStepDiscrete |
| Planta discretizada | `Gp_d = 0,005453/(z − 0,9944)` con `z⁻⁸` |

Implementación discreta (Euler hacia adelante):

```
I[k+1]    = I[k] + Ki·Ts·e[k]
Qcmd[k]   = Kp·e[k] + I[k]
```

### Tabla 15 — Métricas de los tres casos

| Métrica | PI ideal | Saturado sin AW | Saturado con AW |
|---|---|---|---|
| Tiempo de subida (s) | 25,22 | 74,60 | **84,52** |
| Tiempo de establecimiento (s) | 202,28 | 391,71 | **205,03** |
| Sobreimpulso (%) | 7,76 | 30,12 | **0,00** |
| Error estacionario (°C) | −0,0000 | −0,0000 | 0,0000 |
| `T1` máxima (°C) | 62,79 | 70,84 | **60,00** |
| `Q1` mínimo aplicado (%) | 34,67 | 28,68 | 36,76 |
| `Q1` máximo aplicado (%) | 297,35 | 90,00 | 90,00 |
| Tiempo con `Qcmd` fuera de rango (s) | 36 | 127 | — |
| Tiempo con `Q1` saturada (s) | — | **127** | **66** |

### Evidencia del windup (verificada contra los CSV)

| Observación | Valor |
|---|---|
| `Qcmd` en t = 0 (ideal y sin AW) | 274,469 % |
| `Qcmd` máximo (ideal y sin AW) | **297,3533 % en t = 8 s** |
| `T1` cruza 60 °C en el caso sin AW | t = **103 s** |
| El comando vuelve al rango útil | t = **127 s** (24 s después) |
| `T1` máxima sin AW | 70,842 °C en t = 154 s |
| `Q1` baja a 28,68 % (descarga del integrador) | t = **186 s** |
| `T1` máxima del caso ideal | 62,794 °C en t = 75 s |
| `T1` máxima con AW | 60,000 °C (nunca sobrepasa) |

### Cumplimiento de requisitos (`ts ≤ 600 s`, `Mp ≤ 5 %`)

| Caso | `ts` | `Mp` | ¿Cumple? |
|---|---|---|---|
| PI ideal | 202,28 s | 7,76 % | **No** (Mp) — y además es irrealizable |
| Saturado sin AW | 391,71 s | 30,12 % | **No** (Mp, por factor de seis) |
| Saturado con AW | 205,03 s | 0,00 % | **Sí** |

**Configuración seleccionada: PI–SIMC con saturación y anti-windup por clamping.**

**CSV**

- `Graficas/GRAFControladores.csv` → `t, Q1(con AW), Q1(sin AW), Qcmd(sin AW), Qcmd_ideal`
- `Graficas/GRAFControladoresTemperatura.csv` → `t, T1(con AW), T1(sin AW), T1(ideal)`

---

## Actividad 9 — Diseño alternativo con Control System Designer

**Archivos:** `A9_TCLab_MIL_CSD.slx`, `A9_metricas_CSD.m` · `.mat`: `PI_CSD_04.mat`

### Estrategia empleada

Loop shaping sobre el diagrama de Bode del lazo abierto — **no** las reglas SIMC. Se añadió un
integrador y un cero real, y se ajustó la ganancia hasta cumplir dos criterios propios más exigentes
que los de SIMC: **margen de fase > 70°** y **margen de ganancia > 20 dB**.

Entrada en la herramienta: ganancia **0,02** y cero en **−0,0066667**.

CSD aproxima el retardo mediante Padé para trazar el lugar de las raíces. Los márgenes y métricas
reportados se **recalcularon con el retardo exacto** usando `margin` y `stepinfo` con `InputDelay`.

### Controlador obtenido

```
Gc,CSD(s) = 3,000000 + 0,020000/s
```

| Parámetro | Valor |
|---|---|
| `Kp,CSD` | **3,000000 %/°C** |
| `Ki,CSD` | **0,020000 %/(°C·s)** |
| `Ti,CSD` | **150 s** |
| Frecuencia de cruce | **0,0168 rad/s** |
| Margen de fase | **79,1°** |
| Margen de ganancia | **21,53 dB** |
| `ts` lineal | **161,9 s** |
| `Mp` lineal | **1,67 %** |
| Valor final | 1,0000 |

### Tabla 16 — Comparación sobre el modelo lineal

| Parámetro | PI–SIMC | PI–CSD |
|---|---|---|
| `Kp` (%/°C) | 7,620337 | 3,000000 |
| `Ki` (%/(°C·s)) | 0,079379 | 0,020000 |
| `Ti` (s) | 96 | 150 |
| Tiempo de establecimiento (s) | 202,28 | 161,9 |
| Sobreimpulso (%) | 7,76 | 1,67 |

### Tabla 17 — Comparación en MIL (misma corrida, mismas condiciones)

| Métrica | PI–SIMC con AW | PI–CSD con AW |
|---|---|---|
| Tiempo de subida (s) | 84,56 | **133,70** |
| Tiempo de establecimiento (s) | 205,18 | **251,85** |
| Sobreimpulso (%) | 0,00 | 0,00 |
| Error estacionario (°C) | 0,0000 | 0,0000 |
| Temperatura máxima (°C) | 60,00 | 60,00 |
| `Q1` mínimo aplicado (%) | 36,76 | 36,76 |
| `Q1` máximo aplicado (%) | 90,00 | 90,00 |

> La columna PI–SIMC difiere de la Tabla 15 en 0,04 s y 0,15 s. Es interpolación sub-muestra de
> `stepinfo`, no un cambio de comportamiento.

### Esfuerzo de control

| Métrica | PI–SIMC | PI–CSD |
|---|---|---|
| `Qcmd` inicial | **274,33 %** | **108,00 %** |
| Tiempo con `Q1` saturada | **66 s** | **21 s** |

### Selección

Ambos cumplen `ts ≤ 600 s` y `Mp ≤ 5 %`. **Ninguno domina al otro:** el PI–SIMC establece 47 s antes,
el PI–CSD pide un comando inicial 2,5 veces menor, satura un tercio del tiempo y tiene márgenes
mayores. Un criterio de robustez favorecería al PI–CSD.

**Para las etapas de código, SIL y PIL se usa el PI–SIMC**, según fija la §13.1 de la guía. El
PI–CSD queda como contraste metodológico.

---

## Actividad 10 — Definición del sistema bajo prueba

**Archivo de partida:** `A8_TCLab_MIL_SIMC.slx`

| Elemento | Definición |
|---|---|
| Entradas del SUT | `T_ref`, `T1` |
| Salida del SUT | `Q1` |
| Bloques que pertenecen al SUT | ley PI discreta, saturación, lógica de anti-windup |
| Elementos fuera del SUT | planta FOPDT, retardo, `T_amb`, generación de la referencia, registro |
| Frontera | se convierte en `Controller.slx` |

No se modificó la estructura ni los parámetros del controlador en esta actividad.

---

## Actividad 11 — Preparación del controlador para generación de código

**Archivos:** `A9_Code_preparation.slx`, `Controller.slx`

### Tabla 19 — Configuración de generación de código

| Configuración | Valor |
|---|---|
| System target file | `ert.tlc` |
| Language | C |
| Language standard | C99 (ISO) |
| Solver type | Fixed-step |
| Solver | Discrete (no continuous states) |
| Fixed-step size | `Ts` = 1 s |
| Hardware board | None |
| Device vendor | Intel |
| Device type | x86-64 (Windows64) |
| Code interface packaging | Reusable function |
| Instancias por modelo de nivel superior | Multiple |
| Default parameter behavior | Inlined |
| `Kp_SIMC` | ExportedGlobal |
| `Ki_SIMC` | ExportedGlobal |

### Code Generation Advisor

Objetivos, en orden: `Execution efficiency`, `Traceability`.

| Resultado | Cantidad |
|---|---|
| Total | 9 |
| Passed | **7** |
| Warning | **2** |
| **Failed** | **0** |

### Tabla 21 — Model Advisor

| Resultado | Cantidad | Esperado por la guía |
|---|---|---|
| Passed | **5** | 5 |
| Warning | **1** | 1 |
| **Failed** | **0** | 0 |

La advertencia es *Identify questionable software environment specifications* (soporte de valores no
finitos). No afecta al algoritmo implementado. **No se aplicaron correcciones automáticas**
(`Fix All`, `Modify Parameters`) para eliminarla.

> Existe además una corrida ampliada de 75 comprobaciones — Passed 37, Warning 7, Failed 0,
> Not Run 31 — que incluye MISRA, codificación segura y Upgrade Advisor. **Es ajena a la Tabla 21;
> no mezclar ambos conteos.**

### Comprobación funcional

`A9_Code_preparation.slx` sigue reproduciendo el comportamiento validado en MIL: entradas solo
`T_ref` y `T1`, salida solo `Q1`, `0 ≤ Q1 ≤ 90 %`, planta fuera de `Controller.slx`.

---

## Actividad 12 — Generación e inspección del código C

**Comando:** `slbuild("Controller","ModelReferenceCoderTarget")`

**Ubicación del código:** `slprj\ert\Controller\`
Respaldado en `C:\Users\jordy\OneDrive - Estudiantes ITCR\CURSOS 8 SEMESTRE\LAB DE CONTROL\slprj`
(se movió fuera del directorio de trabajo para que la regeneración para Arduino no lo
sobrescribiera).

### Cabecera del archivo generado

```
Target selection: ert.tlc
Embedded hardware selection: Intel->x86-64 (Windows64)
Code generation objectives: Execution efficiency, Traceability
```

### Correspondencia modelo ↔ código

| Característica | Evidencia en el código |
|---|---|
| Interfaz | `void Controller(const real_T *rtu_T_ref, const real_T *rtu_T1, real_T *rty_Q1, DW_Controller_f_T *localDW)` |
| Estado del integrador | campo único `Integrator_DSTATE` en `DW_Controller_f_T` |
| Parámetros calibrables | `real_T Kp_SIMC = 7.620337;` y `real_T Ki_SIMC = 0.079379;` como variables globales |
| Saturación | ramas explícitas con límites `90.0` y `0.0` |
| Anti-windup | condición `(rtb_DeadZone != 0.0) && (tmp == tmp_0)` que anula el incremento integral |
| Tipo de dato | `typedef double real_T` (en `_sharedutils/rtwtypes.h`) |
| Separación controlador–planta | el archivo generado no contiene ningún modelo de planta |

### Fragmentos relevantes

Saturación:

```c
if (rtb_Sum > 90.0) {
  rtb_DeadZone = rtb_Sum - 90.0;  *rty_Q1 = 90.0;
} else {
  rtb_DeadZone = (rtb_Sum >= 0.0) ? 0.0 : rtb_Sum;
  *rty_Q1 = (rtb_Sum < 0.0) ? 0.0 : rtb_Sum;
}
```

Anti-windup por clamping:

```c
if ((rtb_DeadZone != 0.0) && (tmp == tmp_0)) {
  rtb_IntegralGain = 0.0;
}
localDW->Integrator_DSTATE += rtb_IntegralGain;
```

`rtb_DeadZone` mide cuánto excede el comando el rango permitido y vale cero mientras no hay
saturación; `tmp` y `tmp_0` codifican los signos del exceso y del término integral.

---

## Actividad 13 — Construcción del banco Normal–SIL

**Archivo:** `TCLab_Test_SIL.slx`

| Elemento | Configuración |
|---|---|
| Instancia 1 | `Controller_Normal`, `Simulation mode = Normal` |
| Instancia 2 | `Controller_SIL`, `Simulation mode = Software-in-the-loop (SIL)` |
| Modelo referenciado | `Controller.slx` (el mismo en ambas ramas) |
| Plantas | dos copias equivalentes, una por rama |
| Señales registradas | `Q1_Normal`, `T1_Normal`, `Q1_SIL`, `T1_SIL` (objetos `timeseries`) |
| `InitFcn` | `A8_init_TCLab_SIMC` |

Condiciones comunes: mismo `T_ref`, `T_amb`, parámetros de planta, condición inicial, `Ts` = 1 s y
`t_final` = 1800 s.

---

## Actividad 14 — Ejecución y comparación Normal–SIL

**Archivo:** `A10_comparar_Normal_SIL.m`

| Señal | Máximo absoluto | RMSE | Igualdad exacta | Resultado |
|---|---|---|---|---|
| `Q1` | **0** | **0** | Sí | **PASS** |
| `T1` | **0** | **0** | Sí | **PASS** |
| | | | **Global** | **PASS** |

Sobre **1801 muestras** en el intervalo 0–1800 s. Las cuatro señales tienen vectores de tiempo
idénticos.

El criterio de equivalencia se satisface con **igualdad exacta**, no solo dentro de una tolerancia.

**CSV:** `Graficas/GRAFComparacionNormalSIL.csv` →
`t, Q1_Normal, Q1_SIL, T1_Normal, T1_SIL`

---

## Actividad 15 — Cierre de SIL y preparación para PIL

| Pregunta | Respuesta |
|---|---|
| Resultado de la comparación | PASS con igualdad exacta |
| Qué verificó SIL | que la traducción de modelo a código C no introdujo diferencias numéricas: orden de operaciones, actualización del estado, saturación y anti-windup |
| Qué queda pendiente | todo lo relativo al procesador objetivo: compilador cruzado, tamaños de palabra, comportamiento aritmético del dispositivo |
| Por qué no se usa Arduino Leonardo para PIL | en MATLAB R2026a no proporciona la conectividad requerida para la prueba PIL de esta guía |
| Hardware seleccionado para PIL | **Arduino Uno R4 Minima** |

**Artefactos conservados:** `Controller.slx`, `TCLab_Test_SIL.slx`, `A8_init_TCLab_SIMC.m`,
`A10_comparar_Normal_SIL.m`, el código generado y la evidencia del PASS.

---

## Actividades 16 a 18 — Banco PIL, configuración del target y ejecución

**Archivo:** `TCLab_Test_PIL.slx`

| Elemento | Configuración |
|---|---|
| Rama Normal | `Controller_Normal`, `Simulation mode = Normal` |
| Rama PIL | `Controller_PIL`, `Simulation mode = Processor-in-the-loop (PIL)` |
| Modelo referenciado | `Controller.slx` en ambas |
| Code interface | Model reference |
| Procesador objetivo | Arduino Uno R4 Minima |
| Señales compartidas entre ramas | **solo** `T_ref` y `T_amb` |
| Copia propia por rama | retardo y planta FOPDT |
| Registro | bloques `To Workspace`, formato `Timeseries` |
| Nombres | `Q1_Normal`, `T1_Normal`, `Q1_PIL`, `T1_PIL` |
| `Ts` / `t_final` | 1 s / 1800 s → **1801 muestras por señal** |

**Callbacks:** `InitFcn = A8_init_TCLab_SIMC`; `StartFcn` y `StopFcn` **vacíos** (se eliminó
cualquier llamada automática a `A10_comparar_Normal_SIL.m`).

**Configuración del controlador conservada sin cambios:** ley PI–SIMC, saturación, anti-windup por
clamping, `Kp_SIMC = 7,620337`, `Ki_SIMC = 0,079379`, `Q_min = 0 %`, `Q_max = 90 %`, `Ts = 1 s`,
tipo de dato `double`.

Compilación para el target, descarga y ejecución PIL completadas sin errores.

---

## Actividad 19 — Comparación Normal–PIL

**Archivo:** `A11_comparar_Normal_PIL.m` · `.mat`: `TCLab_Test_PIL_results.mat`

| Señal | Máximo absoluto | RMSE | Igualdad exacta | Resultado |
|---|---|---|---|---|
| `Q1` | **0** | **0** | Sí | **PASS** |
| `T1` | **0** | **0** | Sí | **PASS** |
| | | | **Global** | **PASS** |

Sobre **1801 muestras**. No se observó ninguna diferencia que analizar, lo cual es consistente con
haber conservado el tipo `double` y la misma estructura algorítmica en las tres ejecuciones.

**CSV:** `Graficas/GRAFComparacionNormalPIL.csv` →
`t, Q1_Normal, Q1_PIL, T1_Normal, T1_PIL`

---

## Actividad 20 — Cierre de la verificación PIL

### Diferencia entre las tres ejecuciones

| | Normal | SIL | PIL |
|---|---|---|---|
| Qué se ejecuta | el modelo de Simulink | código C compilado para el host | código C compilado para el Arduino |
| Dónde | Simulink | computadora (Intel x86-64) | Arduino Uno R4 Minima |

### Qué se ejecutó físicamente durante PIL

Solo el algoritmo de control: ley PI discreta, saturación y anti-windup, con el estado del
integrador residiendo en la memoria del microcontrolador.

### Qué permaneció simulado

| Elemento | MIL | SIL | PIL |
|---|---|---|---|
| Controlador | modelo | código en host | **código en Arduino** |
| Planta | modelo | modelo | modelo |
| Retardo | simulado | simulado | simulado |
| `T_amb` | señal | señal | señal |
| Sensores | no | no | no |
| Calentadores | no | no | no |

### Qué evidencia aporta un PASS

PIL cubre los efectos del compilador cruzado, los tamaños de palabra y el comportamiento aritmético
del dispositivo, que SIL no puede detectar. **No** constituye una validación del controlador sobre
la TCLab: no se mide con el sensor real, no se acciona el calentador, no se ejercitan los canales
físicos de entrada y salida, y la ejecución no es en tiempo real contra un proceso físico.

**Punto de control registrado:** `tclab-pil-validated-v1`

---

## Capítulo 24 — Implementación física sobre la TCLab

**Archivos:** `Controller_implementacion.slx` (copia de `Controller.slx`),
`TCLab_Implementation.slx`, `A12_visualizar_Implementacion_TCLab.m`

### Configuración numérica para Arduino Leonardo

| Elemento | Tipo | Valor |
|---|---|---|
| `T_ref` | `single` | 60 °C en la prueba definitiva |
| `T1` | `single` | medición filtrada |
| `Kp_SIMC` | `single` | 7,620337, `ExportedGlobal` |
| `Ki_SIMC` | `single` | 0,079379, `ExportedGlobal` |
| `Q_min` | `single` | 0 |
| `Q_max` | `single` | 90 |
| `Ts` | — | 1 s |
| Hardware board | — | Arduino Leonardo |
| System target file | — | `ert.tlc` |

`Controller.slx` **no se modificó**: se conserva como referencia de las etapas de verificación.

### Cadena de señal

```
A0 → single → ganancia single(500/1023) → offset single(−50) °C
   → media móvil λ = 0,5 → PI–SIMC → saturación
   → ganancia single(0.9*255/100) → uint8 → PWM en D3
```

Resolución del convertidor: **LSB = 500/1023 = 0,4888 °C**

### Ejecución

Prueba previa con `T_ref = single(25)` para comprobar la lectura del sensor y los límites del
actuador. Experimento definitivo con `T_ref = single(60)`.

| Parámetro | Valor |
|---|---|
| Muestras | **608** |
| Intervalo | 0 – 607 s |
| `T1` inicial | **26,246 °C** |

### Métricas experimentales

Recalculadas desde `Graficas/ImplementacionA12.csv`, con la definición indicada:

| Métrica | Valor | Definición |
|---|---|---|
| Tiempo de subida | **74 s** | 10–90 % hacia 60 °C |
| Tiempo de establecimiento | **298 s** | banda ±2 % de \|60 − T1(0)\| = ±0,675 °C |
| Sobreimpulso | **1,96 %** | (T1máx − 60)/(60 − T1(0)) |
| Error estacionario | **0,040 °C** | 60 − media de T1 para t ≥ 300 s |
| `T1` máxima del registro | **60,662 °C** | en t = 520 s, **ya en régimen** |
| `T1` máxima antes de establecerse | **59,803 °C** | en t = 273 s, por debajo de la referencia |
| `Q1` mínimo | **25,423 %** | en t = 115 s |
| `Q1` máximo | **90,000 %** | durante el calentamiento inicial |
| Tiempo con `Q1` saturada | **69 s** | |
| `T1` en régimen | **59,960 °C** (σ = 0,245) | media para t ≥ 300 s |
| `Q1` en régimen | **40,29 %** (σ = 1,81) | media para t ≥ 300 s |
| Ganancia estática aparente | **0,837 °C/%** | (T1 régimen − T1(0)) / Q1 régimen |

El máximo absoluto no ocurre en el transitorio sino en régimen permanente; lo que la métrica de
sobreimpulso recoge es la oscilación de baja amplitud alrededor del punto de operación, no un
sobredisparo de la respuesta al escalón.

El error estacionario (0,040 °C) es menor que una décima parte del escalón mínimo del convertidor
(0,489 °C).

### Comparación con MIL

| Métrica | MIL / SIL / PIL | Experimental |
|---|---|---|
| Tiempo de subida (s) | 84,5 | 74 |
| Tiempo de establecimiento (s) | 205,0 | 298 |
| Sobreimpulso (%) | 0,00 | 1,96 |
| Error estacionario (°C) | 0,00 | 0,04 |
| `T1` máxima (°C) | 60,0 | 60,66 |
| `Q1` mínimo aplicado (%) | 36,8 | 25,42 |
| `Q1` en régimen (%) | 36,8 | 40,3 |
| Tiempo con `Q1` saturada (s) | 66 | 69 |

### Causas de las diferencias

| Diferencia | Causa |
|---|---|
| `Q1` en régimen 40,3 % vs 36,8 % | error de ganancia del modelo: ganancia aparente 0,837 frente a 0,979 °C/% nominal (≈ 15 % menor). Coherente con el sesgo detectado en la validación cruzada |
| `ts` 298 s vs 205 s | con menos ganancia efectiva de planta, el lazo cierra más lento |
| `tr` 74 s vs 84,5 s | se partió de 26,25 °C en lugar de 24 °C: el escalón real fue ≈ 6 % más pequeño |
| `Q1` ruidosa (σ = 1,81 %) | el controlador amplifica el ruido de medición por `Kp = 7,62 %/°C`: un solo LSB (0,489 °C) produce 3,7 puntos porcentuales de potencia |
| `Q1` baja a 25,4 % en t = 115 s | corrección tras la saturación inicial sobre una planta cuya dinámica real no coincide exactamente con el FOPDT |

### Cumplimiento de requisitos

| Requisito | Valor experimental | ¿Cumple? |
|---|---|---|
| `ts ≤ 600 s` | 298 s | **Sí** |
| `Mp ≤ 5 %` | 1,96 % | **Sí** |

**CSV:** `Graficas/ImplementacionA12.csv` → `t, T_ref_C, T1_C, Q1_pct`

---

## Anexo A — Inventario de archivos `.mat`

| Archivo | Contenido |
|---|---|
| `escalon_Q1_50_20260812_092703.mat` | datos crudos del ensayo escalón |
| `multinivel_Q1_20260812_102549.mat` | datos crudos del ensayo multinivel |
| `modelos_FOPDT_04_20260812_100000.mat` | `modeloEscalon`, `modeloMultinivel` |
| `validaciones_FOPDT_04_20260812_100000.mat` | `validacionEscalonEnMulti`, `validacionMultiEnEscalon` |
| `PI_SIMC_04_20260812_100000.mat` | `K, tau, theta, tau_c, Kp, Ti, Ki, Gc` |
| `SIT_modelos.mat` | modelos `idproc` de System Identification Toolbox |
| `PI_CSD_04.mat` | controlador PI–CSD |
| `TCLab_Test_PIL_results.mat` | señales de la comparación Normal–PIL |

## Anexo B — Orden de columnas de los CSV

Documentado en `Graficas/Orden CSV.txt`.

| Archivo | Columnas |
|---|---|
| `A1_simulacion_no_lineal.csv` | `t, Q_pct, T_C` |
| `A1_flujos_calor.csv` | `t, q_conv_W, q_rad_W` |
| `IdentificacionSE.csv`, `IdentificacionSM.csv` | `Tiempo_s, Q1_pct, T1_experimental_C, T1_modelo_C, Residuo_C` |
| `validacionEscEnMul.csv`, `validacionMulEnEsc.csv` | `Tiempo_s, Q1_pct, T1_experimental_C, T1_modelo_C, Residuo_C` |
| `GRAFControladores.csv` | `t, Q1(con AW), Q1(sin AW), Qcmd(sin AW), Qcmd_ideal` |
| `GRAFControladoresTemperatura.csv` | `t, T1(con AW), T1(sin AW), T1(ideal)` |
| `GRAFComparacionNormalSIL.csv` | `t, Q1_Normal, Q1_SIL, T1_Normal, T1_SIL` |
| `GRAFComparacionNormalPIL.csv` | `t, Q1_Normal, Q1_PIL, T1_Normal, T1_PIL` |
| `ImplementacionA12.csv` | `t, T_ref_C, T1_C, Q1_pct` |

Los CSV crudos `escalon_Q1_50_*.csv` y `multinivel_Q1_*.csv` traen una columna de texto (fase) que
rompe pgfplots; `multinivel_Q1_*.csv` además usa `;` como separador.

## Anexo C — Valores anotados que quedaron descartados

Al recalcular las métricas de la implementación física desde `ImplementacionA12.csv` aparecieron
diferencias con anotaciones anteriores. **El informe usa la columna de la derecha.**

| Métrica | Anotado antes | Recalculado (vigente) |
|---|---|---|
| Error estacionario | 0,067 °C | **0,040 °C** |
| `Q1` en régimen | 40,1 % | **40,29 %** |
| Ganancia aparente | 0,842 °C/% | **0,837 °C/%** |
| Máximo del transitorio | 59,556 °C en t = 241 s | **59,803 °C en t = 273 s** |
| Instante del mínimo de `Q1` | t ≈ 150 s | **t = 115 s** |

También se corrigió la Tabla 15: el máximo comandado **sin** anti-windup es 297,35 % (igual que el
caso ideal, alcanzado en t = 8 s), no 274,5 % como se había anotado.

Sin cambio: `tr` = 74 s, `ts` = 298 s, `Mp` = 1,96 %, `Q1 ∈ [25,42 , 90,00] %`, saturada 69 s,
`σ(T1)` = 0,245 °C, `σ(Q1)` = 1,81 %.
