# Lab 1 EL5409 · MBD TCLab — pendientes y textos para el informe

> Referencias: `(A5.7)` = Actividad 5, punto 7 · `(§22.5)` = sección de la guía.
> **Parte 1** = lo que falta. **Parte 2** = textos redactados, listos para revisar y pegar en el informe. **Anexo** = tres observaciones que la guía no pide.
> Todo lo marcado **[BORRADOR]** lo escribí yo a partir de tus datos reales; revisalo y ajustalo a tu forma de escribir.
>
> Unidad TCLab **#4** · COM3 · Experimentos del 12 ago 2026
> Abner López Méndez (2022273075) · Jordi Segura Chinchilla (2022240646)

---
---

# PARTE 1 — Lo que falta

## 1.1 Pendientes reales

- [ ] Redactar el informe en LaTeX

**Las veinte actividades de la guía y el capítulo 24 están ejecutados, y toda la evidencia está recopilada.** No queda ningún dato pendiente de obtener: lo único que falta es escribir el informe.

Decisiones de alcance tomadas por el estudiante: el profesor indicó que las capturas de pantalla no son necesarias para el informe, y el campo "Observaciones" de la Tabla 5 se deja vacío por no aportar información relevante.

Sobre el separador de `multinivel_Q1_20260812_102549.csv`: usa `;` y el resto usa `,`. No hace falta cambiar el archivo; basta declarar `col sep=semicolon` en el `\addplot` de ese único caso.

## 1.2 Archivos `.mat` — completo

| Archivo | Referencia | Estado |
|---|---|---|
| `Resultados_experimentos\escalon_Q1_50_20260812_092703.mat` | §7.2 | ✔ |
| `Resultados_experimentos\multinivel_Q1_20260812_102549.mat` | §7.4 | ✔ |
| `modelos_FOPDT_04_20260812_100000.mat` | A5.8 | ✔ contiene `modeloEscalon` y `modeloMultinivel` |
| `validaciones_FOPDT_04_20260812_100000.mat` | A6.8 | ✔ contiene `validacionEscalonEnMulti` y `validacionMultiEnEscalon` |
| `PI_SIMC_04_20260812_100000.mat` | A7.9 | ✔ las ocho variables, **`Gc` incluido** |
| `TCLab_Test_PIL_results.mat` | §22.5 | ✔ las cuatro `timeseries` y `A11_Resultados_Normal_PIL` |
| `SIT_modelos.mat` | A5.7 | ✔ `modeloEscalonSIT` y `modeloMultinivelSIT` (P1D, `procest`) |
| `PI_CSD_04.mat` | A9 | ✔ `Gc_CSD`, `Kp_CSD`, `Ki_CSD`, `Ti_CSD` |

Detalle menor de nomenclatura: la guía escribe el patrón como `<nombre>_TCLab01_fecha_hora.mat` y pide sustituir `TCLab01` por el código de la unidad. Los archivos quedaron como `_04_`, sin el prefijo `TCLab`. No afecta nada, pero si querés ceñirte al patrón, renombralos a `modelos_FOPDT_TCLab04_...` y actualizá la referencia en el informe.

## 1.4 Verificaciones — todas realizadas

Punto de comprobación de la guía | Estado
---|---
Tabla 4 (§6.5) — las seis verificaciones de la TCLab | ✔ satisfactorias
Tabla 19 (§14.8) — configuración de generación de código | ✔ conforme
Code Generation Advisor (§14.9.1) — `Fail = 0` y las tres advertencias esperadas | ✔ conforme
Model Advisor (§14.9.2) — comprobaciones seleccionadas | ✔ conforme a lo esperado (Passed 5 / Warning 1 / Fail 0)
Comprobación funcional (§14.10) — `A9_Code_preparation.slx` reproduce MIL | ✔
Construcción del código (§15.1) | ✔
`get_param` de las dos instancias (§16.8) | ✔ ambas devuelven `Controller`
`StopFcn` con `A10_comparar_Normal_SIL` (A14) | ✔
Comprobaciones previas a PIL (§20.6) | ✔
Muestras y vectores de tiempo (§21.3) | ✔ 1801 en las cuatro señales, tres `logical 1`
Compilación, descarga y ejecución PIL (§21.2) | ✔
Base Data Types en `single` (§24.3) | ✔
`Ctrl+D` sin errores ni advertencias (§24.4, §24.8) | ✔
Lista de comprobación previa (§24.11) | ✔
Corrida de seguridad con `T_ref = single(25)` (§24.12) | ✔

> Los totales del Model Advisor son los únicos números de esta tabla que tomé como "conforme a lo esperado por la guía" y no de una salida de consola. Si el conteo real difirió, corregilo ahí.

---
---

# PARTE 2 — Textos redactados para el informe

## Actividad 1 — Modelo no lineal

Valores extraídos de `A1_flujos_calor.csv` (1200 s, Q = 50 %, T₀ = Ta = 24 °C):

| Instante | T (°C) | q̇_conv (W) | q̇_rad (W) | Fracción radiativa |
|---|---|---|---|---|
| t = 0 | 24,000 | 0,00000 | 0,00000 | — |
| t = 29 s | 30,567 | 0,03940 | 0,04363 | 52,54 % |
| t = 118 s | 44,668 | 0,12401 | 0,14734 | 54,30 % |
| t = 300 s | 56,327 | 0,19396 | 0,24419 | 55,73 % |
| t = 1200 s | 60,466 | 0,21879 | 0,28113 | 56,23 % |

En el equilibrio q̇_conv + q̇_rad = 0,49993 W frente a α·Q = 0,50000 W: el balance cierra, que es la condición dT/dt = 0.

### (A1.5) Contribución de cada mecanismo — **[BORRADOR]**

```
En t = 0 la planta está en equilibrio térmico con el ambiente (T = Ta = T∞ = 24 °C), de
modo que ambas pérdidas son nulas y la totalidad de la potencia del calentador,
α·Q = 0,50 W, se invierte en elevar la temperatura del conjunto. Conforme T aumenta, las
dos pérdidas crecen, pero no al mismo ritmo: la convección es lineal en (T − Ta),
mientras que la radiación depende de (T⁴ − T∞⁴). Por esa razón la fracción radiativa
aumenta de forma monótona con la temperatura: 52,54 % a los 29 s (T = 30,6 °C), 54,30 %
a los 118 s (T = 44,7 °C) y 56,23 % en el equilibrio (T = 60,47 °C).

Con los parámetros nominales de la Tabla 2, la radiación es el mecanismo dominante en
prácticamente todo el ensayo, no solo a alta temperatura. Esto se debe a que el
coeficiente global de convección nominal es bajo (U = 5 W m⁻² K⁻¹) frente al término
radiativo efectivo 4εσAT̄³. En el equilibrio se tiene q̇_conv = 0,2188 W y
q̇_rad = 0,2811 W, cuya suma iguala la potencia suministrada.
```

### (A1.6) Parámetros con mayor incertidumbre — **[BORRADOR]**

```
El parámetro con mayor incertidumbre es U, el coeficiente global de transferencia por
convección. Su valor nominal es un promedio que depende de la geometría real del
montaje, de su orientación y del movimiento del aire circundante; la propia guía
advierte (§4.3.3) que basta colocar la TCLab cerca de un ventilador o de una corriente
de aire para modificar su valor efectivo. Le siguen la emisividad ε y el área efectiva
A, que entran multiplicando las pérdidas, y α, que fija cuánta potencia térmica
representa realmente cada punto porcentual de Q.

Conviene separar su efecto sobre las dos características del modelo:

— Sobre la temperatura de equilibrio. T̄ queda determinada por el balance entre α·Q y la
  suma de las dos pérdidas. Un error en α desplaza T̄ de manera casi proporcional; un
  error en U, ε o A la desplaza en sentido contrario. Como con los valores nominales el
  56 % de la pérdida en equilibrio es radiativa, un error porcentual en ε o en A pesa
  más sobre T̄ que el mismo error porcentual en U.

— Sobre la rapidez. La constante de tiempo es τ = −1/γ con γ = −(UA + 4εσAT̄³)/(mcp). La
  capacidad térmica efectiva mcp aparece únicamente aquí: un error en mcp cambia la
  rapidez de la respuesta pero no la temperatura de equilibrio. En cambio U, ε y A
  afectan a las dos cosas a la vez.

Esta es, precisamente, la razón por la cual el modelo físico no se utiliza para diseñar
el controlador y se recurre a la identificación experimental: el modelo lineal del
balance de energía predice τ = 132,49 s y K = 0,662 °C/%, mientras que los ensayos sobre
la unidad real dan τ = 179,11 s y K = 0,979 °C/%.
```

---

## Actividad 3 — Verificación de la TCLab

### (A3.5) Por qué la respuesta del LED no basta — **[BORRADOR]**

```
La prueba del LED comprueba únicamente dos cosas: que MATLAB establece la conexión serie
con la tarjeta y que esta puede ejecutar un comando de salida digital. No aporta
información sobre los dos elementos que sí intervienen en los experimentos de
identificación.

Por un lado, los sensores. Un canal analógico puede responder sin errores de
comunicación y aun así entregar un valor congelado, saturado o con ruido excesivo. Por
eso la guía pide una comprobación independiente de T1 y T2: en este montaje se
obtuvieron 24,46 °C y 24,77 °C, con ΔT12 = −0,32 °C, valores físicamente razonables y
próximos entre sí.

Por otro lado, el actuador. Que la tarjeta acepte el comando de Q1 no demuestra que el
calentador conduzca ni que la señal PWM llegue al transistor. La evidencia de que el
lazo de actuación funciona es térmica: al aplicar Q1 = 30 % durante 60 s, T1 subió de
24,76 °C a 32,45 °C, un incremento de 7,69 °C, mientras T2 apenas alcanzó 26,74 °C.

La misma prueba muestra un tercer elemento que un LED no puede evidenciar: tras apagar
el calentador en t = 70 s, T1 continuó subiendo hasta t ≈ 89 s antes de empezar a
descender. Ese retraso es la manifestación directa de la capacidad térmica efectiva del
conjunto y anticipa el tiempo muerto y la constante de tiempo que después se identifican
en el modelo FOPDT.
```

---

## Actividad 4 — Adquisición de datos

### (A4.9) Por qué se necesita un conjunto de datos distinto — **[BORRADOR]**

```
Los parámetros de un modelo se estiman minimizando el error sobre un conjunto de datos
concreto. Ese ajuste mide qué tan bien el modelo reproduce los datos que ya vio, no su
capacidad de predecir. Un modelo con suficientes grados de libertad puede seguir muy
bien un registro particular y fallar ante otra excitación, porque parte del ajuste
estará absorbiendo ruido de medición y las condiciones específicas de ese ensayo.

Evaluar el modelo con datos que no participaron en la estimación separa ambas cosas. En
esta práctica el efecto es visible: el modelo del ensayo multinivel presenta el mejor
ajuste con sus propios datos (94,53 % frente a 93,03 % del modelo del escalón), pero al
validarlo contra el ensayo escalón su desempeño cae a 74,38 %, mientras que el modelo
del escalón conserva un 88,66 % sobre los datos multinivel. El criterio de selección de
la Sección 9 no habría podido establecerse con los indicadores de identificación.

Además, los dos ensayos no son repeticiones equivalentes: el escalón excita una sola
transición desde el reposo, mientras que el multinivel recorre varios niveles de
potencia. Como la planta es no lineal, cada uno informa sobre una región de operación
distinta, y esa diferencia es la que hace útil la validación cruzada.
```

---

## Actividad 5 — Identificación FOPDT

### (A5.5) Coherencia y resultado atípico — **[BORRADOR]**

```
Ambos modelos cumplen las condiciones esperadas para una planta térmica estable con
calentamiento positivo: K > 0, τ > 0 y θ ≥ 0. Las ganancias (0,979 y 1,036 °C/%) y las
constantes de tiempo (179,1 y 189,5 s) son consistentes entre sí y del orden de lo que
se observa directamente en los registros.

El resultado que requiere explicación es el tiempo muerto del ensayo multinivel:
θ = 1,999 s frente a 7,996 s del ensayo escalón, una diferencia de un factor cuatro
sobre un parámetro que debería ser una propiedad de la planta y no del experimento.

La explicación está en la naturaleza de cada ensayo. El tiempo muerto se estima a partir
del intervalo entre el cambio de Q1 y el inicio de una variación apreciable de T1. En el
escalón hay una única transición, desde el reposo y de amplitud grande (0 → 50 %), lo
que da una estimación bien definida. En el multinivel hay varias transiciones, de menor
amplitud y sobre una planta que ya está caliente; el ajuste reparte el error entre todas
ellas y el θ resultante es un compromiso. Adicionalmente, en las transiciones
descendentes la respuesta aparente es más rápida, lo que tiende a reducir el θ estimado.

Por tanto, θ = 1,999 s no debe interpretarse como una medición más precisa del retardo
físico, sino como el valor que mejor compensa el conjunto de transiciones del ensayo
multinivel. Este es uno de los elementos que se retoman en la validación cruzada.
```

### (A5.6) Comparación y causas de las diferencias — **[BORRADOR]**

```
                      K (°C/%)    τ (s)      θ (s)    Ajuste (%)
  Ensayo escalón       0,979353   179,112    7,996      93,03
  Ensayo multinivel    1,036018   189,532    1,999      94,53

La ganancia difiere en un 5,8 % y la constante de tiempo en un 5,8 %; el tiempo muerto,
como se explicó, difiere en un factor cuatro. Las causas plausibles son:

— No linealidad de la planta. La pérdida radiativa depende de T⁴, de modo que la
  ganancia incremental disminuye conforme sube la temperatura. El ensayo escalón opera
  sostenidamente cerca de 74 °C, mientras que el multinivel recorre niveles de 10 a 50 %
  y pasa buena parte del registro a temperaturas más bajas. Es coherente que el
  multinivel arroje una ganancia mayor: promedia regiones donde la planta es más
  sensible a la entrada.

— Contenido de información de cada entrada. Un único escalón informa bien sobre la
  ganancia estática y la constante de tiempo, pero solo tiene una transición para
  estimar el retardo. Una secuencia multinivel aporta más transiciones, aunque de menor
  amplitud y con peor relación señal-ruido en cada una.

— Estado térmico inicial. El escalón parte del reposo (T1 = 24,775 °C); el multinivel
  parte de 25,269 °C, es decir, con la planta todavía cediendo calor residual del ensayo
  anterior. Ese enfriamiento se superpone a la respuesta y sesga ligeramente la
  estimación.

— Condiciones ambientales y ruido. Entre ambos ensayos transcurrió aproximadamente una
  hora, tiempo suficiente para pequeñas variaciones de la temperatura del aire, que el
  modelo FOPDT no representa explícitamente.

De acuerdo con el criterio de la guía, estas diferencias se describen aquí pero no
determinan por sí solas cuál modelo se selecciona; esa decisión corresponde a la
validación cruzada de la Sección 9.
```

### (A5.7) System Identification Toolbox

Reestimado con las señales en variables de desviación y estructura P1D. Los dos modelos quedan ahora directamente comparables con los de `A5_identificar_FOPDT_TCLab`.

**Procedimiento utilizado** (registrado dentro de `SIT_modelos.mat`):

```matlab
% Import   datosEscalon / datosMultinivel   (1861 y 3521 muestras, Ts = 1 s)
Opt = procestOptions;
Opt.InitialCondition = 'zero';
Opt.Display = 'full';
SIT_E_P1D = procest(datosEscalon,   'P1D', Opt);
SIT_M_P1D = procest(datosMultinivel,'P1D', Opt);
```

Estructura P1D (un polo real, sin cero, con retardo libre acotado entre 0 y 30 s), condición inicial fija en cero —coherente con haber restado el valor inicial de cada señal— y datos en variables de desviación. La estimación del ensayo escalón terminó en 2 iteraciones con el diagnóstico `Near (local) minimum, (norm(g) < tol)`.

**Tabla 6 ampliada**

| Datos | Método | K (°C/%) | τ (s) | θ (s) | Ajuste (%) |
|---|---|---|---|---|---|
| Escalón | `A5_identificar_FOPDT_TCLab` | 0,979353 | 179,112 | 7,996 | 93,03 |
| Escalón | `procest` P1D (`modeloEscalonSIT`) | 0,979167 | 178,707 | 8,357 | 93,033 |
| Multinivel | `A5_identificar_FOPDT_TCLab` | 1,036018 | 189,532 | 1,999 | 94,53 |
| Multinivel | `procest` P1D (`modeloMultinivelSIT`) | 1,036183 | 189,200 | 2,799 | 94,523 |

Diferencias relativas: K −0,019 % y τ −0,226 % en el escalón; K +0,016 % y τ −0,175 % en el multinivel. En θ, +0,361 s (+4,5 %) y +0,800 s (+40,0 %).

Otros indicadores que reporta `procest`, por si se quieren citar: escalón MSE = 0,78684, FPE = 0,78938, AIC = 4841,15, BIC = 4857,73 · multinivel MSE = 0,64671.

### (A5.7) Análisis de las diferencias — **[BORRADOR]**

```
Los dos métodos producen prácticamente el mismo modelo. La ganancia estática difiere en
menos del 0,02 % en ambos ensayos y la constante de tiempo en menos del 0,23 %. Los
indicadores de ajuste coinciden hasta la segunda cifra decimal: 93,03 frente a 93,033 en
el escalón y 94,53 frente a 94,523 en el multinivel. Para dos procedimientos de
estimación independientes, esa coincidencia indica que ambos convergen al mismo mínimo
del error de predicción y que la información de los datos determina los parámetros con
poca ambigüedad.

La única diferencia apreciable está en el tiempo muerto: 8,357 s frente a 7,996 s en el
ensayo escalón y 2,799 s frente a 1,999 s en el multinivel. La explicación no es
estadística sino del método de búsqueda. La función suministrada explora θ sobre una
grilla cuya resolución es el intervalo de muestreo de cada registro, según se comprueba
en el campo ResolucionTheta_s del modelo almacenado:

      escalon    :  8 x 0,99953715 = 7,9963 s   ->  A5 reporta 7,996 s
      multinivel :  2 x 0,99963805 = 1,9993 s   ->  A5 reporta 1,999 s

Es decir, A5 cuantiza el tiempo muerto a un número entero de muestras, mientras que
procest lo estima como parámetro continuo dentro del intervalo permitido. Vistas así,
las dos estimaciones difieren en 0,361 s y 0,800 s, en ambos casos por debajo de un
periodo de muestreo. No son dos resultados distintos: son el mismo resultado expresado
con distinta resolución.

Esta observación también matiza la interpretación del θ del ensayo multinivel. En la
Sección 8.4 se señaló que 1,999 s resultaba llamativamente bajo frente a los 7,996 s del
escalón. La estimación continua lo sitúa en 2,799 s, de modo que el valor bajo se
confirma con un método independiente y no es un artefacto de la grilla de búsqueda. La
causa hay que atribuirla entonces al ensayo: las transiciones del multinivel son de menor
amplitud, la planta ya está caliente y el ajuste reparte el retardo entre varias
transiciones, algunas de ellas descendentes, donde la respuesta aparente es más rápida.

Sobre la comparabilidad de los indicadores. La guía advierte que los ajustes producidos
por métodos diferentes solo deben compararse si emplean la misma definición, el mismo
intervalo temporal y los mismos datos. Aquí se cumplen las tres condiciones: ambos
utilizan la definición basada en la norma del error frente a la variabilidad de los datos
respecto de su media, es decir la Ec. (31); ambos emplean el registro completo del mismo
ensayo; y la coincidencia numérica hasta la tercera cifra significativa confirma que la
definición es la misma. Por eso la comparación de la tabla anterior es legítima.

Una precisión sobre el procedimiento. En un primer intento se estimaron los modelos
directamente sobre las señales absolutas, sin trasladarlas a variables de desviación.
El resultado fue Kp = 1,4745 °C/% en el escalón, que es aproximadamente el cociente entre
la temperatura final absoluta y la potencia aplicada, 73,998/50 = 1,480: el modelo había
absorbido en la ganancia el desplazamiento correspondiente a la temperatura inicial de
24,78 °C. En el ensayo multinivel el mismo error producía además una constante de tiempo
de 566,75 s, tres veces el valor correcto, porque la entrada regresa a 0 % al final
mientras la temperatura no vuelve a su valor inicial. Se corrigió restando a cada señal
su valor inicial, que es el punto de operación desde el que arranca cada ensayo, tal como
establece la Ec. (22).
```

---

## Actividad 6 — Validación cruzada

### (A6.4) Métricas en los dos intervalos

Las filas de "datos completos" se reconstruyeron de `validacionEscEnMul.csv` y `validacionMulEnEsc.csv` aplicando las Ecs. (29)–(31). El método se verificó reproduciendo **exactamente** los valores que MATLAB imprimió para "desde el primer cambio". Conviene igualmente contrastarlas con la tabla `Metricas [2×7]` que ahora está guardada en `validaciones_FOPDT_04_20260812_100000.mat`.

| Cruce | Intervalo | N | RMSE (°C) | MAE (°C) | Sesgo (°C) | SSE ((°C)²) | R² | Ajuste (%) |
|---|---|---|---|---|---|---|---|---|
| Escalón → multinivel | Datos completos | 3521 | 1,5957 | 1,4595 | +1,4530 | 8965,1247 | 0,98819 | 89,13 |
| Escalón → multinivel | Desde 1er cambio (t = 120 s) | 3401 | 1,6236 | 1,5109 | +1,5042 | 8965,0984 | 0,98714 | 88,66 |
| Multinivel → escalón | Datos completos | 1861 | 2,5879 | 2,3352 | −2,3348 | 12463,9903 | 0,95868 | 79,67 |
| Multinivel → escalón | Desde 1er cambio (t = 60 s) | 1801 | 2,6307 | 2,4127 | −2,4126 | 12463,9774 | 0,93438 | 74,38 |

Para el informe: el SSE es prácticamente idéntico en los dos intervalos, lo que confirma que el error acumulado se genera después del primer cambio de Q1 y que el tramo inicial contribuye de forma despreciable. R² y el ajuste sí mejoran al incluir ese tramo, porque agrega muestras bien predichas y aumenta la varianza de referencia del denominador.

### (A6.5) Sesgo y patrones de los residuos — **[BORRADOR]**

```
Cruce escalón → multinivel.
El residuo no está centrado en cero: el sesgo es +1,45 °C sobre el registro completo y
+1,50 °C desde el primer cambio. Con la convención e(k) = T1,exp − T1,mod, un sesgo
positivo indica que el modelo subestima sistemáticamente la temperatura medida.

El residuo tiene además una estructura temporal clara. En el tramo previo al primer
cambio de Q1 vale −0,06 °C en promedio, es decir, la condición inicial está bien
representada. A partir de ahí crece de forma sostenida hasta +1,34 °C en el tramo final,
con un máximo de +3,51 °C y un mínimo de −0,55 °C.

Al agrupar el residuo por nivel de potencia aparece el patrón más informativo:

      Q1 = 10 %  →  +1,29 °C
      Q1 = 20 %  →  +0,88 °C
      Q1 = 30 %  →  +1,23 °C
      Q1 = 40 %  →  +1,85 °C
      Q1 = 50 %  →  +2,20 °C

El error crece con el nivel de Q1. Ese comportamiento es el que la guía asocia a una
ganancia estática subestimada, y es consistente con K_esc = 0,979 °C/% frente a
K_multi = 1,036 °C/%: el modelo del escalón, identificado a alta temperatura, no
reproduce la mayor sensibilidad que la planta muestra en la región baja del ensayo
multinivel.

Cruce multinivel → escalón.
El comportamiento es el espejo del anterior. El sesgo es −2,33 °C (completo) y −2,41 °C
(desde el primer cambio): el modelo sobreestima la temperatura experimental. El residuo
es negativo prácticamente en todo el registro (máximo +0,05 °C, mínimo −4,68 °C) y su
magnitud crece de forma monótona, desde −0,67 °C al inicio hasta −2,58 °C al final.

Dos efectos se suman aquí. La ganancia mayor del modelo multinivel lo lleva a predecir
una temperatura final más alta que la medida, lo que explica el sesgo sostenido. Y su
tiempo muerto de 1,999 s, frente a los 7,996 s que se observan en el ensayo escalón,
hace que la respuesta predicha se adelante a la medida, concentrando error adicional al
inicio de la transición.

En ambos cruces el residuo presenta un sesgo sistemático y una estructura ligada al
nivel de operación, lo que confirma que un único modelo FOPDT no representa por igual
todo el rango. El modelo del escalón presenta, no obstante, un error de magnitud
claramente menor (RMSE 1,62 frente a 2,63 °C) y un sesgo menor en valor absoluto, además
de un tiempo muerto más próximo al que se observa directamente en los registros.
```

### (A6.7) Justificación del modelo nominal — **[BORRADOR]**

```
Se selecciona como modelo nominal el identificado con el ensayo escalón. La decisión se
apoya en los criterios que ordena la Sección 9.5:

1. Coherencia física. Los dos modelos cumplen K > 0, τ > 0 y θ ≥ 0, por lo que este
   criterio no discrimina.

2. Capacidad predictiva desde el primer cambio. El modelo del escalón predice el ensayo
   multinivel con RMSE = 1,6236 °C, MAE = 1,5109 °C, R² = 0,98714 y un ajuste del
   88,66 %. El modelo multinivel predice el ensayo escalón con RMSE = 2,6307 °C,
   MAE = 2,4127 °C, R² = 0,93438 y un ajuste del 74,38 %. La diferencia es amplia y
   favorece al primero en todos los indicadores.

3. Representación del tiempo muerto y de las transiciones. El θ = 7,996 s del modelo del
   escalón es coherente con el retardo observado directamente en los registros
   experimentales, mientras que θ = 1,999 s del modelo multinivel adelanta la respuesta
   predicha. El sesgo también es menor en valor absoluto para el modelo del escalón
   (+1,50 frente a −2,41 °C).

4. Región de operación. El controlador debe llevar la planta desde la temperatura
   ambiente hasta una referencia de 60 °C y mantenerla ahí. El ensayo escalón, aplicado
   con Q1 = 50 %, opera precisamente en esa región, mientras que el multinivel reparte su
   información entre niveles de 10 a 50 %, buena parte de ellos a temperaturas más bajas
   que la de operación prevista.

Se deja constancia, siguiendo la advertencia de la guía, de que el modelo multinivel
presentaba el mejor indicador de ajuste con sus propios datos de identificación (94,53 %
frente a 93,03 %). Ese indicador no se utilizó como criterio de selección, porque mide la
reproducción de los datos empleados en la estimación y no la capacidad predictiva.

El modelo nominal es, por tanto:

                      0,979353 · e^(−7,996 s)
      Gp,nom(s) = ──────────────────────────────      [°C/%]
                        179,112 s + 1
```

---

## Actividad 7 — Diseño PI mediante SIMC

### (A7.6) Expresión numérica de Gc(s)

Coherente con la opción B del Anexo A (θ = 8,000 s):

```
                         0,079379
      Gc(s) = 7,620337 + ─────────        [%/°C]
                             s

            = 7,620337 · (1 + 1/(96,000 s))
```

Kp = 7,620337 %/°C · Ti = 96,000 s · Ki = 0,079379 %/(°C·s) · τc = 16,000 s

### (A7.7) Efecto de modificar τc — **[BORRADOR]**

```
El parámetro τc fija la rapidez deseada del lazo cerrado y es la única decisión libre de
la sintonización SIMC. Su efecto se lee directamente en las reglas
Kp = τ / (K·(τc + θ)) y Ti = mín{τ, 4(τc + θ)}.

Reducir τc. Si en lugar de τc = 2θ = 16 s se adoptara τc = θ = 8 s, la ganancia
proporcional pasaría de 7,620 a 11,430 %/°C y el tiempo integral de 96 a 64 s. El lazo
respondería más rápido, pero el controlador solicitaría más potencia ante el mismo
error. Dado que en la evaluación MIL la acción de control ya arranca saturada durante
66 s en el caso con anti-windup, una sintonización más agresiva prolongaría ese tramo y
haría al lazo más dependiente del mecanismo de anti-windup. Además, un Kp mayor amplifica
el ruido de la medición de temperatura y reduce el margen frente a los errores del
modelo, en particular frente al tiempo muerto no representado por la aproximación FOPDT.

Aumentar τc. El efecto es el inverso: Kp menor, respuesta más lenta y suave, menor
demanda de potencia al inicio del transitorio, menos tiempo en saturación y mayor
tolerancia a la incertidumbre del modelo y a variaciones de la planta.

Para esta práctica, la elección τc = 2θ resultó adecuada: el caso realizable cumple los
requisitos con holgura (ts = 205,03 s frente al límite de 600 s y Mp = 0,00 % frente al
límite de 5 %). Existe margen para reducir τc si se buscara una respuesta más rápida,
pero a costa de un tramo de saturación más prolongado y de menos robustez.
```

### (A7.8) Diferencia entre Ki y Ki·Ts — **[BORRADOR]**

```
Ki es la ganancia integral del controlador continuo y se expresa en %/(°C·s). Indica
cuánta acción integral se genera por cada grado de error y por cada segundo transcurrido.
Es un parámetro del diseño y no depende de cómo se implemente después el controlador.

Ki·Ts es el incremento que se suma al estado del integrador en cada ejecución del
algoritmo discreto, según I[k+1] = I[k] + Ki·Ts·e[k] (Ec. 45). Sus unidades son %/°C,
porque el periodo de muestreo ya está incorporado.

En esta práctica ambos valores coinciden numéricamente, Ki = 0,079379 %/(°C·s) y
Ki·Ts = 0,079379 %/°C, únicamente porque Ts = 1 s. Esa coincidencia es accidental y puede
inducir a error. Si se cambiara el periodo de muestreo a Ts = 0,5 s, la ganancia de
diseño Ki seguiría valiendo 0,079379, pero el incremento por muestra sería la mitad; al
ejecutarse el doble de veces por segundo, el comportamiento del lazo se conservaría.
Utilizar Ki directamente como incremento por muestra, sin multiplicar por Ts, haría que
el controlador integrara al doble de velocidad y modificaría el desempeño respecto al
diseño validado.
```

---

## Actividad 8 — Evaluación MIL

### Tabla 15

| Métrica | PI ideal | Saturación sin AW | Saturación con AW |
|---|---|---|---|
| Tiempo de subida (s) | 25,22 | 74,60 | 84,52 |
| Tiempo de establecimiento (s) | 202,28 | 391,71 | 205,03 |
| Sobreimpulso (%) | 7,76 | 30,12 | 0,00 |
| Error estacionario (°C) | −0,0000 | −0,0000 | 0,0000 |
| Temperatura máxima (°C) | 62,79 | 70,84 | 60,00 |
| Q1,min aplicado (%) | 34,67 | 28,68 | 36,76 |
| Q1,max aplicado (%) | 297,35 | 90,00 | 90,00 |
| Tiempo con Qcmd fuera de rango (s) | 36 | 127 | No disponible |

Requisitos del caso con AW: ts = 205,03 s ≤ 600 s ✔ · Mp = 0,00 % ≤ 5 % ✔ · Q1 ∈ [36,76 , 90,00] % ✔ · T1max = 60,00 °C ≤ 90 °C ✔

### Datos extraídos de los CSV de MIL

| Dato | Valor |
|---|---|
| Q1 saturada en 90 %, con AW | 66 s (t = 0–66) |
| Q1 saturada en 90 %, sin AW | 127 s (t = 0–127) |
| Qcmd > 90 %, caso ideal | 36 s, pico 297,35 % |
| Qcmd > 90 %, caso sin AW | 127 s, pico 297,35 % |
| T1 alcanza 60 °C por primera vez, sin AW | t = 103 s |
| T1 máxima sin AW | 70,84 °C en t = 154 s |
| T1 máxima caso ideal | 62,79 °C en t = 75 s |
| Q1 mínima sin AW | 28,68 % en t = 186 s |
| Q1 mínima con AW | 36,76 % (valor de equilibrio; nunca baja de él) |

### (A8.9) Análisis comparativo — **[BORRADOR]**

```
¿Durante cuánto tiempo solicita el PI una potencia fuera del rango realizable?

En el caso ideal, Qcmd supera el 90 % durante 36 s, con un pico de 297,35 %: más de tres
veces lo que el actuador de la TCLab puede entregar. En el caso con saturación sin
anti-windup, el mismo pico se mantiene, pero la señal permanece fuera de rango durante
127 s. En ningún caso Qcmd desciende por debajo de 0 %.

¿Cómo cambia la respuesta cuando la potencia aplicada se limita a 0–90 %?

El arranque se hace más lento. El tiempo de subida pasa de 25,22 s en el caso ideal a
74,60 s con saturación y a 84,52 s con saturación y anti-windup. Esto es esperable: el
caso ideal alcanza la referencia apoyándose en una acción de control que la planta no
puede producir, de modo que no constituye una alternativa de implementación sino la
referencia contra la cual medir el costo de la restricción física.

¿Qué evidencia muestra la acumulación del integrador en el caso sin anti-windup?

No basta observar que Q1 permanece en 90 %. La evidencia está en la combinación de dos
hechos. Primero, entre t = 0 y t = 127 s el controlador solicita una potencia de hasta
297,35 % mientras la planta recibe únicamente 90 %; durante esos 127 s el error sigue
siendo positivo y el integrador continúa sumando Ki·Ts·e[k] sobre una acción que no se
aplica. Segundo, la consecuencia se observa después: T1 cruza los 60 °C en t = 103 s,
pero la potencia no empieza a reducirse hasta t = 127 s, porque el integrador ha
acumulado un valor que mantiene la salida en el límite. La temperatura continúa subiendo
hasta 70,84 °C en t = 154 s, lo que representa un sobreimpulso del 30,12 %, y el
controlador debe llevar Q1 hasta 28,68 % en t = 186 s —muy por debajo del 36,76 % que
corresponde al equilibrio— para descargar la acción integral acumulada. El tiempo de
establecimiento resultante es de 391,71 s.

¿Cómo modifica el anti-windup el sobreimpulso y el tiempo de establecimiento?

Con clamping, la actualización del integrador se detiene mientras la salida está saturada
y el error tiende a alejarla aún más del intervalo permitido. El efecto es directo: Q1
permanece saturada 66 s en lugar de 127 s, el sobreimpulso desaparece por completo
(Mp = 0,00 %, con una temperatura máxima de 60,00 °C, exactamente la referencia) y el
tiempo de establecimiento baja de 391,71 a 205,03 s. Q1 nunca desciende por debajo de
36,76 %, lo que confirma que no fue necesario compensar acción integral acumulada en
exceso.

Conviene señalar que el anti-windup no mejoró todas las métricas. El tiempo de subida
empeoró, pasando de 74,60 a 84,52 s, porque la acción integral disponible al salir de la
saturación es menor. La guía advierte expresamente que no debe concluirse de antemano que
el anti-windup mejore todos los indicadores.
```

### (A8.10) Selección justificada — **[BORRADOR]**

```
Se selecciona la configuración de PI–SIMC con saturación en 0–90 % y anti-windup mediante
clamping.

El caso ideal queda descartado como implementación, aunque presente el mejor tiempo de
establecimiento y un sobreimpulso moderado, porque su respuesta depende de una acción de
control de hasta 297,35 % que la TCLab no puede producir. Solo los dos casos saturados
son físicamente realizables.

Entre ellos, el caso sin anti-windup cumple el requisito de tiempo de establecimiento
(391,71 s frente al límite de 600 s), pero incumple con claridad el de sobreimpulso:
30,12 % frente al límite del 5 %. Además lleva la temperatura hasta 70,84 °C, muy por
encima de la referencia, lo que en una planta térmica no es únicamente un problema de
desempeño.

El caso con saturación y anti-windup es el único que satisface simultáneamente los dos
requisitos de desempeño —ts = 205,03 s ≤ 600 s y Mp = 0,00 % ≤ 5 %—, junto con las dos
restricciones físicas: Q1 permanece dentro de 0–90 % y T1 no supera los 90 °C. El error
estacionario es nulo, como corresponde a un controlador con acción integral sobre un
modelo nominal estable.

No se identifican requisitos incumplidos por esta configuración. Queda pendiente
verificar que el código generado a partir de este diseño conserva el comportamiento
evaluado aquí, lo que corresponde a las etapas SIL y PIL.
```

---

## Actividad 9 — Diseño alternativo con Control System Designer

### Controlador obtenido

```
                                       0,020000
      Gc,CSD(s) = 0,02·(1 + 150s)/s = 3,000000 + ──────────      [%/°C]
                                                     s
```

Kp,CSD = 3,000000 %/°C · Ki,CSD = 0,020000 %/(°C·s) · Ti,CSD = Kp/Ki = 150,000 s (Ec. 64)

Verificación con el retardo exacto (`margin` y `stepinfo` sobre `Gp_nom` con `InputDelay`, sin la aproximación de Padé de la GUI):

| Indicador | Valor | Requisito |
|---|---|---|
| ωc | 0,0168 rad/s | — |
| Margen de fase | 79,1° | > 70° (criterio propio) |
| Margen de ganancia | 21,53 dB | > 20 dB (criterio propio) |
| Tiempo de establecimiento | 161,9 s | ≤ 600 s ✔ |
| Sobreimpulso | 1,67 % | ≤ 5 % ✔ |
| Valor final del lazo cerrado | 1,0000 | error estacionario nulo ✔ |

### Tabla 16 — Comparación de los diseños PI

| Parámetro o característica | PI–SIMC | PI–CSD |
|---|---|---|
| Kp (%/°C) | 7,620337 | 3,000000 |
| Ki (%/(°C·s)) | 0,079379 | 0,020000 |
| Ti (s) | 96,000 | 150,000 |
| Tiempo de establecimiento (s) | 202,28 | 161,9 |
| Sobreimpulso (%) | 7,76 | 1,67 |

Los valores de la columna PI–SIMC son los del caso "PI ideal" de la Tabla 15, que corresponde al mismo lazo lineal sin saturación con el que se evaluó el PI–CSD. Márgenes del PI–SIMC, para la comparación: ωc = 0,0425 rad/s, PM = 64,2°, GM = 13,3 dB.

### Procedimiento y justificación — **[BORRADOR]**

```
La guía no proporciona un procedimiento para esta actividad, de modo que la estrategia de
diseño fue seleccionada por los autores. Se optó por un ajuste de lazo en el dominio de
la frecuencia (loop shaping) sobre el diagrama de Bode del lazo abierto, especificando
explícitamente los márgenes de estabilidad y la frecuencia de cruce de ganancia.

Esta estrategia es distinta de la sintonización SIMC. Las reglas SIMC son expresiones
analíticas cerradas derivadas de la inversión del modelo, con un único parámetro libre
(τc), y no hacen referencia explícita a márgenes de estabilidad. En el enfoque adoptado
aquí no se utiliza ninguna fórmula de sintonización: se fijan primero los requisitos de
robustez en frecuencia y se ajustan después la ganancia y la posición del cero del
controlador hasta satisfacerlos simultáneamente con las especificaciones temporales.

Criterios de diseño adoptados. A los dos requisitos de la guía, ts ≤ 600 s y Mp ≤ 5 %, se
añadieron dos criterios de robustez propios: margen de fase mayor que 70° y margen de
ganancia mayor que 20 dB. El primero se obtiene de la relación aproximada PM ≈ 100·ζ junto
con Mp = exp(−πζ/√(1−ζ²)), que para Mp ≤ 5 % exige ζ ≥ 0,690. El segundo se adoptó para
disponer de una tolerancia amplia frente a errores de ganancia del modelo, dado que la
validación cruzada mostró diferencias del orden del 6 % entre las ganancias identificadas
en los dos ensayos.

Procedimiento seguido.

1. Se cargó el modelo nominal Gp,nom(s) = 0,979353·e^(−7,996s)/(179,112s+1) conservando el
   tiempo muerto identificado, tal como exige la Sección 12.1.

2. Se abrió Control System Designer con la arquitectura de realimentación unitaria y
   compensador en el lazo directo.

3. Se incorporaron como restricciones gráficas el tiempo de establecimiento y el
   sobreimpulso sobre la respuesta al escalón, y el margen de fase sobre el Bode.

4. Se dotó al compensador de estructura PI mediante un integrador y un cero real, con lo
   que C(s) = Kc(s+z)/s, equivalente a Kp + Ki/s.

5. Se ajustaron la ganancia y la posición del cero. El compromiso es el siguiente: la
   ganancia desplaza la frecuencia de cruce, y como el retardo aporta un atraso de fase
   proporcional a θ·ωc, aumentarla reduce el margen de fase. El cero, por su parte,
   recupera fase antes del cruce, de modo que situarlo a frecuencias más bajas aumenta el
   margen a costa de una acción integral más lenta. El diseño final sitúa el cero en
   0,006667 rad/s y la frecuencia de cruce en 0,0168 rad/s.

6. Se exportó el controlador y se verificaron los márgenes y la respuesta al escalón desde
   la ventana de comandos, utilizando el modelo con InputDelay.

Aproximación introducida. Control System Designer sustituye el retardo puro por una
aproximación de Padé para poder representar el lugar de las raíces; su efecto es visible
en el cero de fase no mínima que aparece en el semiplano derecho de esa gráfica. Por esa
razón los valores reportados en la tabla anterior no se tomaron de la interfaz gráfica
sino de una verificación posterior con el modelo de retardo exacto. La diferencia entre
ambos resultados fue pequeña, pero se prefirió el cálculo exacto por trazabilidad.

Comparación con el diseño SIMC. El PI–CSD resulta menos agresivo: su ganancia proporcional
es 3,000 frente a 7,620 %/°C y su tiempo integral es 150 frente a 96 s. En términos de
frecuencia, la diferencia se aprecia mejor en los márgenes: el PI–SIMC opera con
PM = 64,2° y GM = 13,3 dB a una frecuencia de cruce de 0,0425 rad/s, mientras que el
PI–CSD lo hace con PM = 79,1° y GM = 21,53 dB a 0,0168 rad/s. Es decir, el diseño
alternativo renuncia a ancho de banda a cambio de una tolerancia considerablemente mayor
frente a errores del modelo.

Sobre el modelo lineal, sin embargo, el PI–CSD presenta simultáneamente un tiempo de
establecimiento menor (161,9 frente a 202,28 s) y un sobreimpulso mucho menor (1,67
frente a 7,76 %). Esto no es contradictorio: el PI–SIMC alcanza antes la referencia pero
la sobrepasa y necesita tiempo adicional para regresar a la banda del 2 %, mientras que
el PI–CSD se aproxima de forma más amortiguada. La comparación bajo las restricciones
físicas se presenta en la Tabla 17.
```

### Tabla 17 — Comparación MIL de los controladores realizables

*(mismas condiciones: planta, Ts = 1 s, límites 0–90 %, anti-windup por clamping, T_amb = 24 °C, T_ref = 60 °C, t_final = 1800 s)*

| Métrica | PI–SIMC con AW | PI–CSD con AW |
|---|---|---|
| Tiempo de subida (s) | 84,56 | 133,70 |
| Tiempo de establecimiento (s) | 205,18 | 251,85 |
| Sobreimpulso (%) | 0,00 | 0,00 |
| Error estacionario (°C) | 0,0000 | 0,0000 |
| Temperatura máxima (°C) | 60,00 | 60,00 |
| Q1,min aplicado (%) | 36,76 | 36,76 |
| Q1,max aplicado (%) | 90,00 | 90,00 |

Ambas columnas provienen de la misma corrida de `A9_TCLab_MIL_CSD.slx`, de modo que la comparación es interna y consistente. La columna PI–SIMC difiere de la Tabla 15 en 0,04 s en el tiempo de subida y 0,15 s en el de establecimiento; las dos diferencias son muy inferiores al periodo de muestreo y se deben a la interpolación entre muestras que realiza `stepinfo`, no a un comportamiento distinto del lazo.

**Datos complementarios de esfuerzo de control** (del mismo lazo discreto, útiles para la discusión):

| | PI–SIMC | PI–CSD |
|---|---|---|
| Qcmd solicitada en t = 0 | 274,33 % | 108,00 % |
| Tiempo con Q1 saturada en 90 % | 66 s | 21 s |
| Margen de fase | 64,2° | 79,1° |
| Margen de ganancia | 13,3 dB | 21,5 dB |

### (A9) Comparación y selección final — **[BORRADOR]**

```
Cumplimiento de especificaciones. Los dos controladores satisfacen los requisitos de la
Ec. (63). El tiempo de establecimiento es de 205,18 s para el PI–SIMC y de 251,85 s para
el PI–CSD, ambos muy por debajo del límite de 600 s, y ninguno presenta sobreimpulso
(0,00 % en los dos casos). El error estacionario es nulo en ambos, como corresponde a
controladores con acción integral evaluados sobre el modelo nominal.

Conviene señalar que esta coincidencia en el sobreimpulso no se observaba sobre el modelo
lineal, donde el PI–SIMC presentaba 7,76 % frente a 1,67 % del PI–CSD (Tabla 16). La
saturación del actuador junto con el anti-windup elimina el sobreimpulso del PI–SIMC: la
acción de control queda limitada a 90 % durante la fase inicial, de modo que el lazo se
aproxima a la referencia más despacio de lo que el diseño lineal predecía y no llega a
sobrepasarla. Es un ejemplo directo de por qué la guía advierte que el cumplimiento de las
especificaciones no puede darse por demostrado sobre el modelo lineal.

Restricciones físicas. Los dos casos son idénticos en este aspecto: la temperatura máxima
es 60,00 °C, igual a la referencia, y la potencia aplicada permanece entre 36,76 % y
90,00 %. Ninguno se acerca al límite térmico de 90 °C ni excede el rango del actuador.
Este criterio, por sí solo, no discrimina entre ambos.

Esfuerzo de control. Aquí sí aparece una diferencia clara. En el instante inicial, con un
error de 36 °C, el PI–SIMC solicita una potencia de 274,33 % mientras que el PI–CSD
solicita 108,00 %. Es decir, el primero pide casi tres veces lo que el actuador puede
entregar y el segundo apenas un 20 % por encima del límite. En consecuencia, el PI–SIMC
permanece saturado 66 s frente a los 21 s del PI–CSD. Un lazo que opera menos tiempo en
saturación depende menos del mecanismo de anti-windup y se comporta de forma más próxima
a su diseño lineal.

Robustez. El PI–CSD presenta márgenes sensiblemente mayores: 79,1° de margen de fase y
21,5 dB de margen de ganancia, frente a 64,2° y 13,3 dB del PI–SIMC. La diferencia es
relevante para esta planta en particular. La validación cruzada de la Sección 9 mostró que
las ganancias identificadas en los dos ensayos difieren alrededor de un 6 %, y la
implementación física reveló posteriormente una ganancia estática aparente cercana a
0,842 °C/%, un 14 % por debajo de la del modelo nominal. Un margen de ganancia mayor
significa precisamente mayor tolerancia frente a ese tipo de error.

Selección. Ninguno de los dos diseños domina al otro. El PI–SIMC es más rápido: alcanza la
referencia en 84,56 s frente a 133,70 s y se establece unos 47 s antes. El PI–CSD es más
robusto y exige menos del actuador. Como ambos cumplen los requisitos con amplio margen y
la rapidez no es un factor crítico en esta aplicación térmica —el límite de 600 s queda
lejos en los dos casos—, la robustez y el menor esfuerzo de control constituyen argumentos
de peso a favor del PI–CSD.

No obstante, el flujo de trabajo continúa con el PI–SIMC. La Sección 13.1 de la guía
establece explícitamente que la etapa de generación de código y las verificaciones SIL y
PIL se realizan sobre el controlador PI–SIMC con saturación y anti-windup mediante
clamping. El diseño alternativo desarrollado en esta actividad cumple entonces la función
de contraste metodológico: permite comprobar que el resultado de las reglas SIMC es
razonable, cuantificar su posición en el compromiso entre rapidez y robustez, y verificar
que un procedimiento de diseño completamente distinto conduce a un controlador del mismo
orden de magnitud y también admisible.
```

---

## Actividad 10 — Definición del SUT — **[BORRADOR]**

| Punto | Contenido |
|---|---|
| **Entradas y salida del SUT** | Entradas: `T_ref` (double, escalar) y `T1` (double, escalar). Salida: `Q1` (double, escalar). Las tres señales son reales y el componente opera con un único periodo de muestreo Ts = 1 s. |
| **Bloques del algoritmo del controlador** | Cálculo del error e[k] = T_ref[k] − T1[k]; ganancia proporcional `Kp_SIMC`; ganancia integral `Ki_SIMC` y el integrador discreto con método Forward Euler; suma de las contribuciones proporcional e integral; saturación de la salida en 0–90 %; lógica de anti-windup por clamping (detección de zona muerta y comparación de signos que bloquea la actualización del integrador). |
| **Elementos fuera del SUT** | El retardo discreto de la planta (Integer Delay, N_delay = 8 muestras); el modelo FOPDT discreto; la fuente de temperatura ambiente `T_amb`; la fuente de referencia `T_ref` —la fuente queda fuera aunque la señal que genera sea entrada del SUT—; los bloques de visualización (Scope) y los de registro de resultados (To Workspace). |
| **Frontera → `Controller.slx`** | El subsistema correspondiente al tercer lazo de `A8_TCLab_MIL_SIMC.slx` (PI con saturación y anti-windup), convertido en modelo referenciado con la interfaz funcional `T_ref, T1 → Controller → Q1`. |

---

## Actividad 11 — Resultados de los Advisors

Tomados de los reportes conservados en `slprj\modeladvisor\` (carpeta respaldada fuera del directorio de trabajo).

### Tabla 20 — Code Generation Advisor

Corrida del 08-Sep-2026 22:19:52 · **Total 9 · Passed 7 · Warning 2 · Failed 0 · Not Run 0**

Se cumple el criterio de §14.9.1: cero resultados `Fail`. Aparecieron 2 de las 3 advertencias que anticipa la Tabla 20 de la guía; la de "Check model configuration settings against code generation objectives" está confirmada en el reporte, con el listado de parámetros que Embedded Coder recomienda cambiar para maximizar la eficiencia de ejecución (*Gain parameters inherit a built-in integer type*, *Inline invariant signals*, *Remove root level I/O zero initialization*, entre otros). Todas se conservaron sin modificar, de acuerdo con la indicación de no utilizar `Modify Parameters` ni `Fix All` solo para obtener resultados `Pass`.

### Tabla 21 — Model Advisor

Las comprobaciones se ejecutaron en varias pasadas, cada una con su propio reporte:

| Producto | Comprobación | Resultado | Reporte |
|---|---|---|---|
| Simulink Coder | Check solver for code generation | **Passed** | `report_47.html` |
| Simulink Coder | Check for blocks not supported by code generation | **Passed** | `report_47.html` |
| Embedded Coder | Check for blocks not recommended for C/C++ production code deployment | **Passed** | `report.html` |
| Embedded Coder | Check the hardware implementation | **Passed** | — |
| Embedded Coder | Identify questionable software environment specifications | **Warning** | `report.html` |
| Embedded Coder | Identify questionable code instrumentation (data I/O) | **Passed** | `report_63.html` |

**Totales de las seis comprobaciones de la Tabla 21: Passed 5 · Warning 1 · Failed 0**, que coincide con el resultado que anticipa la guía en §14.9.2.

Nota de trazabilidad: cinco de los seis resultados se leyeron directamente de los reportes conservados; el de `Check the hardware implementation` procede de la comprobación realizada por el estudiante durante la sesión de trabajo, cuyo reporte no quedó entre los archivos respaldados.

Dos aclaraciones para que las cifras no parezcan contradictorias en el informe:

- La advertencia de *Identify questionable software environment specifications* corresponde al soporte de valores no finitos (NaN e Inf), exactamente la que la guía anticipa como única advertencia esperada.
- El reporte `report.html` corresponde a una corrida ampliada de 75 comprobaciones (Passed 37 · Warning 7 · Failed 0 · Not Run 31), que incluye conjuntos ajenos a la Tabla 21 —MISRA C:2023, codificación segura, Upgrade Advisor—. Esas 7 advertencias no son las de la Tabla 21 y conviene no mezclarlas: para la tabla se toman únicamente las seis comprobaciones listadas arriba.

---

## Actividad 12 — Generación e inspección del código C

Código conservado en `…\LAB DE CONTROL\slprj\ert\Controller\`, fuera del directorio de trabajo para que no lo sobrescribiera la regeneración posterior para Arduino.

**Cabecera de `Controller.c`** — confirma la configuración exigida en §14.8:

```c
 * Model version                  : 1.17
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Wed Sep  9 08:27:01 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives:
 *    1. Execution efficiency
 *    2. Traceability
```

En `rtwtypes.h`: `typedef double real_T;` — las señales del SUT se representan en doble precisión.

### Los seis fragmentos

**1. Interfaz de entrada y salida del SUT** — `Controller.h`

```c
extern void Controller(const real_T *rtu_T_ref, const real_T *rtu_T1, real_T
                       *rty_Q1, DW_Controller_f_T *localDW);
```

Conserva la frontera definida en la Sección 13: dos entradas escalares (`T_ref`, `T1`) y una salida (`Q1`), todas `real_T`. El modificador `const` indica que el controlador no modifica sus entradas. No aparece ninguna señal asociada con la planta.

**2. Estado interno del integrador** — `Controller.h`

```c
typedef struct {
  real_T Integrator_DSTATE;            /* '<S38>/Integrator' */
} DW_Controller_f_T;
```

La estructura de estados contiene un único miembro, el del integrador discreto. Confirma que el controlador tiene memoria y que esa memoria es exclusivamente la de la acción integral.

**3. Parámetros calibrables** — `Controller.h` los declara y `Controller.c` los define:

```c
/* Controller.h */
extern real_T Ki_SIMC;
extern real_T Kp_SIMC;

/* Controller.c */
real_T Ki_SIMC = 0.079379;             /* Variable: Ki_SIMC
                                        * Referenced by: '<S35>/Integral Gain'
                                        */
real_T Kp_SIMC = 7.620337;             /* Variable: Kp_SIMC
                                        * Referenced by: '<S43>/Proportional Gain'
                                        */
```

La clase `ExportedGlobal` produjo variables globales con nombre propio en lugar de constantes incrustadas en las expresiones. Los valores coinciden con los de la sintonización SIMC implementada. Obsérvese además el comentario de trazabilidad que asocia cada parámetro con su bloque de origen, consecuencia del objetivo *Traceability*.

**4. Límites 0–90 % de la señal de control** — `Controller.c`

```c
  if (rtb_Sum > 90.0) {
    rtb_DeadZone = rtb_Sum - 90.0;
    *rty_Q1 = 90.0;
  } else {
    if (rtb_Sum >= 0.0) {
      rtb_DeadZone = 0.0;
    } else {
      rtb_DeadZone = rtb_Sum;
    }
    if (rtb_Sum < 0.0) {
      *rty_Q1 = 0.0;
    } else {
      *rty_Q1 = rtb_Sum;
    }
  }
```

`rtb_Sum` es la acción PI antes de limitar. Los valores 0.0 y 90.0 aparecen incrustados porque `Q_min` y `Q_max` se mantuvieron como datos estructurales y no como parámetros calibrables. La variable `rtb_DeadZone` registra cuánto excede la acción el intervalo permitido, y es la que después usa el anti-windup.

**5. Condición del anti-windup** — `Controller.c`

```c
  if (rtb_DeadZone > 0.0) {
    tmp = 1;
  } else {
    tmp = -1;
  }
  ...
  if ((rtb_DeadZone != 0.0) && (tmp == tmp_0)) {
    rtb_IntegralGain = 0.0;
  }

  localDW->Integrator_DSTATE += rtb_IntegralGain;
```

`tmp` representa el sentido en que la acción excedió el límite y `tmp_0` el sentido del incremento integral. La actualización del integrador se anula solo cuando hay saturación **y** ambos sentidos coinciden, es decir, cuando integrar agravaría la saturación. En cualquier otro caso el incremento se aplica, de modo que la integración se reanuda en cuanto el error favorece el regreso al intervalo realizable. Es exactamente la Ec. (55).

**6. La planta queda fuera del código** — evidencia combinada

La interfaz solo recibe `T_ref` y `T1`; la estructura de estados contiene únicamente `Integrator_DSTATE`, sin estados de la dinámica FOPDT ni del retardo; y en `Controller.c` no existe ninguna operación que calcule la evolución de `T1` a partir de `Q1`. Los parámetros K, τ, θ y `T_amb` no aparecen en ningún archivo del componente.

### Conclusión — **[BORRADOR]**

```
La inspección confirma que el código generado conserva la estructura funcional del
controlador validado durante MIL. Se identificaron en el código los cinco elementos del
algoritmo: el cálculo del error, las contribuciones proporcional e integral con sus
ganancias representadas como variables globales, la saturación en el intervalo 0–90 %, la
lógica de anti-windup por clamping y la actualización del estado del integrador. La
interfaz coincide con la frontera del SUT definida en la Sección 13 y no incorpora ningún
elemento de la planta ni del banco de pruebas.

Esta comprobación no constituye todavía una verificación SIL. Que el código tenga la
estructura correcta no demuestra que su ejecución produzca los mismos valores numéricos
que el modelo; esa equivalencia se evalúa mediante la comparación back-to-back de la
Sección 17.
```

---

## Actividad 14 — Qué permite concluir la comparación Normal–SIL — **[BORRADOR]**

```
El resultado PASS proporciona evidencia de que, bajo las condiciones de prueba utilizadas,
la ejecución del código C generado reproduce exactamente el comportamiento del modelo del
controlador ejecutado en modo Normal. La coincidencia es muestra a muestra y con igualdad
exacta, no aproximada: el máximo absoluto de la diferencia y el RMSE son cero tanto para
Q1 como para T1 a lo largo de las 1801 muestras.

Esto verifica que la traducción realizada por Embedded Coder conservó el algoritmo
validado durante MIL, incluyendo la evolución del estado del integrador a lo largo de toda
la simulación, los límites de saturación y la lógica de anti-windup. Que las dos
trayectorias de temperatura coincidan es un resultado más fuerte que la coincidencia de
las señales de control: como cada rama alimenta su propia copia de la planta, cualquier
diferencia en Q1, por pequeña que fuera, se habría propagado y amplificado en T1.

El alcance de esta conclusión tiene tres límites. Primero, corresponde exclusivamente al
controlador definido como SUT; las dos copias de la planta continúan ejecutándose como
modelos de Simulink y no forman parte del código sometido a verificación. Segundo, el
código se compiló y ejecutó en la computadora de desarrollo, con la configuración Intel
x86-64 y aritmética de doble precisión, de modo que no se verifica todavía nada relativo
al procesador embebido. Tercero, se evaluó una condición específica de operación —un
cambio de referencia desde la temperatura ambiente hasta 60 °C— y no una equivalencia para
cualquier conjunto de entradas posibles.
```

---

## Actividad 15 — Cierre de SIL — **[BORRADOR]**

| Punto | Contenido |
|---|---|
| Resultado final de la comparación Normal–SIL | PASS, con igualdad exacta muestra a muestra en Q1 y T1 sobre 1801 muestras. |
| Aspectos verificados mediante SIL | La equivalencia numérica entre el modelo del controlador y su código C generado: la señal de control Q1, la respuesta de temperatura T1 resultante, la evolución del estado interno del integrador, los límites de saturación 0–90 % y la lógica de anti-windup por clamping. |
| Aspectos pendientes sobre un procesador físico | La arquitectura del microcontrolador; la representación numérica propia del hardware; el compilador y la cadena de herramientas del dispositivo; la ejecución efectiva del código sobre el procesador; y el mecanismo de comunicación entre Simulink y el hardware. |
| Razón por la que el Leonardo no se usa para PIL | En MATLAB/Simulink R2026a la configuración disponible para el Arduino Leonardo no proporciona el soporte de conectividad requerido para ejecutar una prueba PIL. Es una limitación del soporte de hardware, no de la estructura del controlador ni del código desarrollado. |
| Hardware seleccionado para PIL | Arduino Uno R4 Minima, utilizado exclusivamente como procesador de verificación; la planta continúa simulada en Simulink. |
| Arquitectura propuesta | Banco independiente `TCLab_Test_PIL.slx` con dos ramas, `Controller_Normal` en modo Normal y `Controller_PIL` en modo PIL, ambas referenciando `Controller.slx`, compartiendo únicamente las fuentes `T_ref` y `T_amb` y con una copia propia del retardo y de la planta FOPDT en cada rama. |

---

## Actividad 16 — Por qué la planta debe estar duplicada — **[BORRADOR]**

```
Las señales de control Q1,Normal y Q1,PIL se calculan de forma independiente: una por el
modelo ejecutado en Simulink y la otra por el código ejecutado en el procesador. Si ambas
ramas compartieran una única planta, habría que decidir cuál de las dos acciones de
control la excita, y la comparación dejaría de tener sentido.

Con plantas separadas, cada acción de control genera su propia trayectoria de temperatura.
Esto convierte la comparación en una prueba más exigente: una diferencia en Q1, por pequeña
que fuera, se realimentaría a través de su propia planta y se propagaría a T1, de modo que
la coincidencia exacta de las dos temperaturas es evidencia de que las dos ejecuciones del
controlador fueron idénticas durante todo el ensayo, y no solo en instantes aislados.

Para que la comparación sea válida, las dos copias deben ser equivalentes en estructura,
parámetros, retardo, condiciones iniciales, periodo de muestreo y configuración numérica, y
ambas ramas deben recibir la misma referencia y la misma temperatura ambiente.
```

---

## Actividad 17 — Por qué hubo que regenerar los artefactos — **[BORRADOR]**

```
El cambio de plataforma objetivo, desde Intel x86-64 hacia el procesador del Arduino,
modifica la configuración de compilación, los tipos de datos definidos en rtwtypes.h y las
utilidades compartidas que Embedded Coder genera dentro de la carpeta slprj. Los artefactos
existentes correspondían a la plataforma anterior y podrían haberse reutilizado parcialmente
durante la construcción, lo que produciría una mezcla de código compilado para dos
arquitecturas distintas.

Por esa razón se eliminaron la carpeta slprj y los archivos de caché .slxc antes de iniciar
la prueba PIL, de modo que la construcción partiera de un estado limpio y todo el código
correspondiera al nuevo objetivo. La operación afecta únicamente a artefactos generados; no
elimina los modelos .slx ni los scripts de la práctica.
```

---

## Actividad 19 — Qué evidencia aporta la comparación Normal–PIL — **[BORRADOR]**

```
El resultado PASS proporciona evidencia de que el código generado del controlador puede
compilarse para el Arduino Uno R4 Minima, descargarse al procesador y ejecutarse sobre él
conservando exactamente el comportamiento del modelo de referencia. La coincidencia es
muestra a muestra a lo largo de las 1801 muestras del ensayo, con máximo absoluto y RMSE
iguales a cero tanto para Q1 como para T1.

Respecto a SIL, la cadena verificada es distinta. En SIL se comprobó modelo → código
generado → compilación y ejecución en la computadora host. En PIL se comprueba modelo →
código generado → compilación para el procesador objetivo → descarga → ejecución en el
Arduino. Se añaden, por tanto, la cadena de herramientas del dispositivo, la representación
numérica del procesador y el mecanismo de comunicación host–target, que transfiere las
entradas y devuelve la salida en cada periodo de muestreo.

La igualdad exacta obtenida es un criterio deliberadamente estricto y propio de esta
configuración. No debe interpretarse como un requisito universal: procesadores,
representaciones numéricas, compiladores u optimizaciones diferentes pueden producir
pequeñas discrepancias numéricas aun cuando el código sea funcionalmente equivalente.
```

---

## Actividad 20 — Cierre de PIL — **[BORRADOR]**

| Pregunta | Respuesta |
|---|---|
| **Diferencia entre Normal, SIL y PIL** | En modo Normal, Simulink ejecuta directamente el modelo contenido en `Controller.slx`. En SIL ejecuta el código C generado a partir de ese modelo, compilado para la computadora de desarrollo (Intel x86-64) y ejecutado en ella. En PIL ejecuta ese mismo código compilado para el procesador del Arduino Uno R4 Minima, descargado al dispositivo y ejecutado físicamente en él, intercambiando entradas y salida con Simulink en cada periodo de muestreo. En los tres casos la planta permanece simulada. |
| **Qué se ejecutó físicamente durante PIL** | Únicamente el algoritmo del controlador: el cálculo del error, las contribuciones proporcional e integral, la actualización del estado del integrador, la saturación y la lógica de anti-windup. La referencia, la temperatura ambiente, el retardo y el modelo FOPDT de la planta continuaron calculándose en la computadora. |
| **Qué evidencia proporciona un PASS** | Que el código puede compilarse para el procesador objetivo, descargarse y ejecutarse sobre él; que la comunicación host–target funciona; que el estado interno del controlador evoluciona correctamente durante toda la ejecución; y que los resultados satisfacen el criterio de equivalencia establecido respecto a la ejecución Normal. |
| **Por qué no es todavía una implementación completa** | Porque la planta térmica sigue siendo un modelo. No se mide la temperatura con el sensor de la TCLab, no se accionan físicamente los calentadores, no se verifican los canales de entrada y salida de la planta y no se comprueba una ejecución determinista en tiempo real. El Arduino actúa como procesador de prueba, no como controlador embebido de un sistema físico. |
| **Aspectos fuera del alcance** | La dinámica real de la TCLab frente al modelo FOPDT; el retardo real frente al simulado; las variaciones de la temperatura ambiente; el ruido y la cuantización del convertidor A/D; la respuesta real del actuador PWM; y el cumplimiento de los plazos de ejecución en tiempo real. |

---

## Capítulo 24 — Implementación física

### Métricas experimentales

Calculadas de `Graficas\ImplementacionA12.csv` con las **mismas definiciones** que usa `A8_validar_TCLab_SIMC.m`: `stepinfo` sobre ΔT1 = T1 − T1(0) con valor final ΔT_ref, umbral de establecimiento del 2 %, y error estacionario como T_ref menos el promedio de los últimos 60 s.

| Métrica | Experimental | MIL (con AW) |
|---|---|---|
| T1 inicial | 26,246 °C | 24,000 °C |
| Tiempo de subida (10–90 %) | 74 s | 84,52 s |
| Tiempo de establecimiento (±2 % = ±0,675 °C) | 298 s | 205,03 s |
| Sobreimpulso | 1,96 % | 0,00 % |
| Error estacionario | +0,067 °C | 0,0000 °C |
| Temperatura máxima | 60,662 °C (en t = 520 s) | 60,00 °C |
| Q1,min aplicado | 25,42 % | 36,76 % |
| Q1,max aplicado | 90,00 % | 90,00 % |
| Tiempo en saturación a 90 % | 69 s (t = 0–68) | 66 s |

Datos adicionales del régimen permanente (t ≥ 300 s): T1 media 59,96 °C con desviación 0,245 °C y rango 59,50–60,66 °C; Q1 media 40,1 % con desviación 1,81 % y rango 34,81–44,40 %. Máximo de T1 durante el transitorio (t ≤ 250 s): 59,556 °C en t = 241 s.

### Seguimiento de la referencia y comportamiento transitorio — **[BORRADOR]**

```
El lazo cerrado sobre la planta física alcanza y mantiene la referencia de 60 °C. Partiendo
de T1 = 26,25 °C, el tiempo de subida entre el 10 % y el 90 % del cambio es de 74 s y el
tiempo de establecimiento, con el criterio del 2 % (banda de 59,32 a 60,68 °C), es de 298 s.
Ambos valores quedan holgadamente dentro del requisito ts ≤ 600 s.

La respuesta no presenta sobreimpulso transitorio: durante los primeros 250 s la
temperatura máxima es 59,556 °C, es decir, se aproxima a la referencia desde abajo. El
valor del 1,96 % que devuelve stepinfo corresponde a un máximo de 60,662 °C alcanzado en
t = 520 s, ya en régimen permanente, y no a un sobrepaso del transitorio. Es más exacto
describirlo como una fluctuación alrededor de la referencia que como sobreimpulso.

El transitorio presenta una forma distinta de la obtenida en simulación. La temperatura
sube rápidamente hasta unos 57,8 °C alrededor de t = 100 s, permanece en una meseta
próxima a 58,2 °C entre t = 90 s y t = 260 s, y luego se aproxima lentamente a la
referencia. Ese tramo lento corresponde a la acción integral corrigiendo el error residual
que la acción proporcional por sí sola no elimina, sobre una planta cuya ganancia real es
menor que la del modelo.

El error estacionario, medido como el promedio de los últimos 60 s, es de +0,067 °C. No es
cero, como sí lo era en simulación, pero es una fracción pequeña de la banda de ruido de la
propia medición: en régimen la temperatura fluctúa con una desviación estándar de 0,245 °C.
```

### Evolución de Q1 y límites de la acción de control — **[BORRADOR]**

```
La acción de control permanece en todo momento dentro del intervalo permitido, con un
mínimo de 25,42 % y un máximo de 90,00 %. La saturación en el límite superior se produce
únicamente durante los primeros 69 s del ensayo, un comportamiento esperado dado el error
inicial de 33,75 °C y anticipado por la propia guía.

A partir de t ≈ 69 s la potencia desciende de forma progresiva conforme se reduce el error,
sin oscilaciones bruscas ni recuperación tardía, lo que confirma que el anti-windup por
clamping opera correctamente también sobre la planta real. En régimen permanente Q1 se
estabiliza alrededor del 40,1 %, con una desviación estándar de 1,81 % y excursiones entre
34,81 % y 44,40 %.

Esa fluctuación residual de la acción de control es la respuesta del controlador al ruido
de la medición de temperatura. Conviene recordar que el convertidor A/D del Arduino entrega
10 bits sobre un intervalo de 500 °C, lo que da un escalón de cuantización de 500/1023 =
0,4888 °C; el filtro exponencial con factor de olvido 0,5 suaviza esa señal, pero no la
elimina. Con Kp = 7,62 %/°C, una variación de una cuenta del convertidor se traduce en
aproximadamente 3,7 puntos porcentuales de potencia, magnitud del mismo orden que la
dispersión observada.

El valor de equilibrio del 40,1 % es, además, el dato más informativo para comparar con el
modelo. Con una temperatura inicial de 26,25 °C, ese nivel de potencia corresponde a una
ganancia estática aparente de (60 − 26,25)/40,07 = 0,842 °C/%, un 14 % menor que los
0,979 °C/% del modelo nominal. La planta real necesita más potencia de la prevista para
sostener los 60 °C.
```

### Diferencias respecto a MIL, SIL y PIL — **[BORRADOR]**

```
Antes de comparar conviene notar un punto que simplifica el análisis: las verificaciones
Normal–SIL y Normal–PIL arrojaron igualdad exacta muestra a muestra, con máximo absoluto y
RMSE iguales a cero en Q1 y en T1. Por tanto, las tres simulaciones producen exactamente la
misma trayectoria y cualquier diferencia observada en la implementación física no puede
atribuirse al código generado ni al procesador: procede de la planta y de la interfaz
física con ella.
```

| Comparación | Diferencia observada | Causa probable |
|---|---|---|
| **Experimental vs MIL** | Tiempo de establecimiento 298 s frente a 205,03 s | La ganancia estática aparente de la planta real (≈ 0,842 °C/%) es un 14 % menor que la del modelo nominal (0,979 °C/%). Con menos ganancia de proceso, el lazo es efectivamente más lento y el integrador necesita más tiempo para cancelar el error residual. |
| | Q1 de equilibrio 40,1 % frente a 36,76 % | La misma causa. El modelo FOPDT se identificó a partir de un ensayo que operaba cerca de 74 °C, mientras que aquí la planta trabaja en 60 °C y bajo condiciones ambientales distintas a las del 12 de agosto. Las pérdidas reales en el punto de operación son mayores que las que predice el modelo. |
| | Error estacionario +0,067 °C frente a 0,0000 °C | En simulación la acción integral cancela el error de forma exacta sobre un modelo determinista. En la planta real el error se mide sobre una señal con ruido y cuantización, de modo que el promedio de los últimos 60 s no coincide exactamente con la referencia. La magnitud es muy inferior a la dispersión de la medición (0,245 °C). |
| | Fluctuación de T1 (±0,25 °C) y de Q1 (±1,8 %) en régimen | Ruido del sensor y cuantización del convertidor A/D (0,4888 °C por cuenta), amplificados por la ganancia proporcional. En MIL no existe ruido de medición. |
| | Tiempo de subida menor: 74 s frente a 84,52 s | La temperatura inicial fue mayor (26,25 frente a 24,00 °C), de modo que el salto exigido fue menor: 33,75 frente a 36,00 °C. |
| | Meseta alrededor de 58 °C entre t = 90 s y t = 260 s, ausente en simulación | Combinación de la menor ganancia real y de dinámica no modelada por la aproximación de primer orden: el conjunto transistor–disipador–sensor no es un único elemento a temperatura uniforme, y el sensor responde con su propio retardo. |
| **Experimental vs SIL** | Las mismas diferencias que frente a MIL | La comparación Normal–SIL dio igualdad exacta, de modo que SIL reproduce la trayectoria de MIL sin ninguna desviación. No se añade ninguna diferencia atribuible al código generado. |
| **Experimental vs PIL** | Las mismas diferencias que frente a MIL | La comparación Normal–PIL también dio igualdad exacta. Además, la implementación física introduce dos cambios que PIL no evaluó: la aritmética pasó de `double` a `single` para el Arduino Leonardo, y el lazo incorpora la adquisición real de T1 con su conversión, filtrado y cuantización, así como la generación efectiva del PWM. Ninguno de estos elementos formaba parte de la verificación PIL, en la que Tref y T1 eran señales suministradas por Simulink. |

> Ninguna de estas diferencias se corrigió ni se ajustó artificialmente. Se documentan tal como se observaron, de acuerdo con el criterio de la guía.

---
---

# ANEXO — Observaciones que la guía no pide

## A. Redondeo de θ · **cerrado**

Nada que hacer. Queda solo el párrafo para el informe, porque los dos valores aparecen impresos en las consolas y conviene que el texto explique por qué.

### Nota para el informe — **[BORRADOR]**

```
El modelo nominal identificado entrega un tiempo muerto θ = 7,996 s. Con un periodo de
muestreo Ts = 1 s, la representación discreta de la planta emplea
N_delay = round(θ/Ts) = 8 muestras, es decir θ_d = 8,000 s, de acuerdo con la Ec. (49).
Por coherencia se utilizó ese mismo valor redondeado en la sintonización SIMC, de modo
que el diseño, la evaluación MIL, la generación de código, las verificaciones SIL y PIL
y la implementación física emplean un único tiempo muerto.

La desviación respecto al valor identificado es de 4 ms, un 0,05 % de θ, y se propaga a
los parámetros del controlador como Kp = 7,620337 en lugar de 7,624149 %/°C y
Ki = 0,079379 en lugar de 0,079458 %/(°C·s). Ambas diferencias son varios órdenes de
magnitud menores que la incertidumbre del propio modelo FOPDT, cuyo error de validación
cruzada es de 1,62 °C de RMSE, y no tienen efecto apreciable sobre el desempeño.
```

## B. Código de la build SIL · **cerrado**

El código SIL está conservado en `C:\Users\jordy\OneDrive - Estudiantes ITCR\CURSOS 8 SEMESTRE\LAB DE CONTROL\slprj`, movido fuera del directorio de trabajo para que la regeneración posterior para Arduino no lo sobrescribiera. Verificado: cabecera `Embedded hardware selection: Intel->x86-64 (Windows64)`, `typedef double real_T`, `Kp_SIMC = 7.620337`, `Ki_SIMC = 0.079379`, más la carpeta `ert\Controller\sil\` con `Controller.exe` y `sil_main.c`, y los reportes de los Advisors en `modeladvisor\`.

Lo que hay dentro del directorio de trabajo (`C:\Claude\INFORME 1\slprj`) es la build AVR posterior, de la etapa de implementación física. Conviene mencionar en el informe que ambas se conservan por separado, porque §19.1 advierte justamente que `slprj` se regenera al cambiar de target.

Queda una comprobación menor: `Controller.slx` tiene fecha 13 set, posterior al PIL del 9 set. §24.2 y §40 piden que quede sin modificar como referencia de las etapas de verificación. Como el código SIL sí está respaldado, la trazabilidad está cubierta; aun así conviene saber qué se le cambió.

## C. Orden de columnas de los CSV · **cerrado**

`Graficas\Orden CSV.txt` ya está lleno y confirma uno a uno los órdenes deducidos, incluidos los dos archivos de MIL: `Controladores = [t, Q1_conAW, Q1_sinAW, Qcmd_sinAW, Qcmd_ideal]` y `ControladoresTemperatura = [t, T1_conAW, T1_sinAW, T1_ideal]`. Se deja la tabla como referencia rápida al escribir el `.tex`.

| Archivo | Columnas |
|---|---|
| `A1_simulacion_no_lineal.csv` | t, Q_pct, T_C |
| `A1_flujos_calor.csv` | t, q_conv_W, q_rad_W |
| `escalon_Q1_50_...csv` | Tiempo_s, Fase, Q1_pct, PWM, T1_C |
| `multinivel_Q1_...csv` | Tiempo_s; Etapa; Estado; Q1_pct; PWM; T1_C — **separador `;`** |
| `IdentificacionSE.csv` / `IdentificacionSM.csv` | Tiempo_s, Q1_pct, T1_exp, T1_mod, Residuo |
| `validacionEscEnMul.csv` / `validacionMulEnEsc.csv` | Tiempo_s, Q1_pct, T1_exp, T1_mod, Residuo |
| **`GRAFControladores.csv`** | **t, Q1(con AW), Q1(sin AW), Qcmd(sin AW), Q1(ideal)** |
| **`GRAFControladoresTemperatura.csv`** | **t, T1(con AW), T1(sin AW), T1(ideal)** |
| `GRAFComparacionNormalSIL.csv` | t, Q1_Normal, Q1_SIL, T1_Normal, T1_SIL |
| `GRAFComparacionNormalPIL.csv` | t, Q1_Normal, Q1_PIL, T1_Normal, T1_PIL |
| `ImplementacionA12.csv` | t, T_ref_C, T1_C, Q1_pct |

Un detalle para la leyenda de la figura: la última columna de `GRAFControladores.csv` es `Qcmd_ideal_sim`, es decir la señal **antes** de cualquier límite. En el caso ideal no hay saturación, así que esa señal es también la potencia aplicada a la planta, y es la que alcanza el pico de 297,35 %. Conviene rotularla como Q1 del caso ideal y no como "comando", para que se lea igual que en la Tabla 15.
