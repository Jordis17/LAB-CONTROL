# Etapa B — Identificación y validación del modelo

## 1. Qué se identifica y por qué con estos ensayos

La planta no se puede ensayar con un escalón en lazo abierto, porque la bola se va a la pared
(CLAUDE.md, sección 3.3). Por eso:

| Qué | Ensayo | Script |
|---|---|---|
| Relación servo → plato (actuador) | Tabla de comando contra inclinación medida con la app | Ya hecho (`datos_prototipo/mecanica/`, 2026-11-04) |
| **Coeficiente de rodadura c** y **fricción f** | **B1:** plato fijo a un ángulo y bola soltada desde el reposo; la bola describe una parábola | `B1_identificar_rodadura_BoP.m` |
| **Altura de la junta h_sup** y efecto de la inclinación sobre la cámara | **B2:** bola quieta contra un borde y ese lado del plato bajando a varios ángulos | `B2_medicion_inclinada_BoP.m` |
| Retardo, periodo y ruido de la cámara | `run_benchmark.py`, `medir_ruido.py` | Instructivo, Parte 2 |

Modelo a identificar (Etapa A, plato fijo): `ẍ = −c·g·sin θ − f·sign(ẋ)`. En magnitud, como la
bola siempre rueda cuesta abajo: **|a| = c·g·|sin θ| − f**.

## 2. Cómo hacer los ensayos (PC con Linux)

**Preparación:** el sketch está en `firmware/prueba_servos/prueba_servos.ino` (necesita la librería ESP32Servo).
- Carguen en la ESP32 el sketch **`prueba_servos.ino`**, no el del lazo, porque aquí el plato
  tiene que quedarse fijo.
- La ESP32 va conectada a la PC con Linux. Para mandarle comandos desde una terminal:

  ```bash
  python -m serial.tools.miniterm /dev/ttyUSB0 115200
  ```

  Escriban `X 10` + Enter, etc. Para salir: Ctrl + ].
- En **otra terminal**, la visión **sin serial** (el puerto lo usa la terminal anterior):

  ```bash
  python scripts/main_vision.py --no-serial
  ```

  Cada corrida crea un `logs/sesion_FECHA_HORA.csv`.

### B1: rodadura con el plato fijo

Para cada eje y cada ángulo:
1. Manden un comando que incline el plato (ver la tabla de abajo).
2. **Midan el ángulo con la app**, con el celular en el centro del plato. Esperen a que el
   número se estabilice y anoten el valor del eje que corresponde.
3. Arranquen `main_vision.py --no-serial`.
4. Sostengan la bola quieta en el lado **alto**, a unos 100 mm del centro. Esperen 1 s y
   **suéltenla sin empujarla**, retirando el dedo hacia arriba.
5. Cuando la bola llegue al borde bajo y se quede quieta, Ctrl-C.
6. Repitan **3 veces** cada ángulo. Las repeticiones 1 y 2 sirven para identificar y la 3 para
   validar.

Ángulos: unos **4°, 6° y 8°** de plato en cada sentido. Con ángulos más chicos, el error de la
app (~0,1°) pesa demasiado. Comandos aproximados, según la tabla medida (el plato queda
horizontal con más o menos `X 2.5` e `Y 7`):

| Inclinación buscada | Eje X | Eje Y |
|---|---|---|
| Lado + arriba ~4° | `X -6` | `Y -1` |
| Lado + arriba ~6° | `X -10` | `Y -4` |
| Lado + arriba ~8° | `X -13` | `Y -8` |
| Lado + abajo ~4° | `X 10` | `Y 16` |
| Lado + abajo ~6° | `X 17` | `Y 21` |
| Lado + abajo ~8° | `X 25` | `Y 28` |

Lo que importa es el ángulo que **midan**, no que caiga exacto. Son 6 ángulos × 3
repeticiones × 2 ejes = 36 corridas. Si no alcanza el tiempo, hagan el eje X completo.

### B2: bola contra el borde

1. Pongan el plato horizontal (`X 2.5`, `Y 7`, revisando con la app) y la bola **quieta contra
   el borde +X**. Registren 3 s. Anoten el ángulo X de la app.
2. **Bajen el lado +X** a ~4° y después a ~8° (comando X positivo). La bola sigue contra el
   borde. Registren 3 s en cada ángulo y anoten la app.
3. Repitan contra el borde −X (comandos negativos) y, si hay tiempo, con +Y y −Y.

**Antes de B2:** comprueben que la bola contra el borde **se ve en la imagen** con el plato
inclinado. Es justo la zona donde el campo de la cámara está más justo.

## 3. Tabla de ensayos

`datos_prototipo/etapaB/ensayos.csv`, con este encabezado exacto y **sin comas en las
observaciones**:

```
archivo,ensayo,eje,comando_deg,th_app_deg,repeticion,borde,observaciones
sesion_20261106_101500.csv,B1,X,-7,6.1,1,,bien
sesion_20261106_101530.csv,B1,X,-7,6.0,2,,bien
sesion_20261106_101600.csv,B1,X,-7,6.1,3,,bien
sesion_20261106_103000.csv,B2,X,2.5,0.1,1,+X,horizontal
sesion_20261106_103010.csv,B2,X,10,4.2,1,+X,bola quieta
```

Copien los CSV de `logs/` a `datos_prototipo/etapaB/` con su nombre original.

## 4. Análisis (MATLAB o Octave)

```matlab
cd etapaB
B1_identificar_rodadura_BoP
B2_medicion_inclinada_BoP
```

**B1:**
- toma el tramo de rodadura libre de cada ensayo (con criterios fijos, los mismos para todos);
- corrige el efecto de la inclinación sobre la cámara;
- ajusta una parábola a cada ensayo;
- identifica c (modelo M1) y c con f (modelo M2) con las repeticiones 1 y 2;
- **valida con la repetición 3**: RMSE, MAE, sesgo, R², FIT y la estructura del residuo
  (autocorrelación y tendencia).

El modelo nominal se elige por la validación.

**B2:** compara el cambio medido de la posición con el que predice el modelo de medición e
identifica h_sup.

## 5. Prueba de los scripts (2026-11-06)

Se probaron en Octave con **datos sintéticos**: generados con el modelo, con c = 0,695,
f = 20 mm/s², h_sup = 55 mm, ruido de cámara de 0,5 mm y error de la app de 0,1°. **No son
mediciones y no están en el repo.**

- B1 recuperó c = 0,696 y f = 25 mm/s².
- B2 recuperó h_sup = 55,8 mm.
- Con ángulos de ~3,5°, el error de 0,1° de la app ya pesa tanto como la diferencia entre
  modelos. De ahí la recomendación de usar 4° o más.
