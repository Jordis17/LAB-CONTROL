# Instructivo de pruebas — Ball on Plate

Versión del 2026-11-03. Repositorio `Jordis17/LAB-CONTROL`, rama `claude/great-bell-pprlzs`.

Este documento explica qué hay que correr y medir, en qué orden, cómo hacerlo, qué debería salir
y qué hay que devolver. Tiene cuatro partes, que se pueden hacer en paralelo:

| Parte | Dónde | Necesita el prototipo | Para qué |
|---|---|---|---|
| **1. Corridas en MATLAB** | Computadora con MATLAB | No | Confirmar en MATLAB las Etapas A, C, D y E, que hasta ahora solo se probaron en Octave |
| **2. Cámara y visión** | PC con Linux + cámara + plato | Sí (plato, bola y cámara montados) | Medir Ts, latencia y ruido, calibrar y verificar el campo de visión |
| **3. Mecánica y servos** | Prototipo + ESP32 | Sí | Reemplazar los valores de diseño por mediciones |
| **4. Ensayos de identificación (Etapa B)** | Prototipo + PC + ESP32 | Sí | Datos para identificar y validar el modelo |

Al final (sección 5) está **qué devolver y cómo nombrarlo**.

> **Regla general:** no hay que ajustar nada para que un resultado "se vea bien". Si algo sale
> raro, se anota tal cual y se manda. Un dato mal medido pero bien documentado sirve. Un dato
> corregido a mano no sirve.

---

## 0. Preparación (una sola vez)

### 0.1 Obtener la versión actual del proyecto

En la computadora con MATLAB y en la PC con Linux:

```bash
git clone https://github.com/Jordis17/LAB-CONTROL.git
```

```bash
cd LAB-CONTROL
```

```bash
git checkout claude/great-bell-pprlzs
```

Si ya lo tenían clonado:

```bash
git pull origin claude/great-bell-pprlzs
```

> Sin git: en GitHub, entrar a la rama `claude/great-bell-pprlzs` → **Code** → **Download ZIP**.

### 0.2 Cuaderno de registro

Hagan una hoja (papel o archivo) para anotar, por cada prueba: **fecha y hora, quién la hizo,
qué se hizo, condiciones** (luz, tensión de los servos, posición de la cámara) y **cualquier
cosa rara**. Esas notas van en el informe.

---

## Parte 1 — Corridas en MATLAB (no necesitan el prototipo)

### 1.1 Requisitos

- MATLAB **R2022a o más nuevo**.
- Para las Etapas A, C y D: solo MATLAB base. Control System Toolbox es opcional; si está, A2
  hace una comprobación extra.
- Para la Etapa E: **Simulink, Simulink Coder y Embedded Coder**.

### 1.2 Paso 1: versión y toolboxes

En la ventana de comandos de MATLAB:

```matlab
diary('ver_matlab.txt'); ver; diary off
```

Guarden el archivo `ver_matlab.txt` en la raíz del proyecto.

### 1.3 Orden de ejecución

Cada script guarda solo su salida de consola (`*_consola.txt`) y sus resultados en la carpeta
`resultados/` de su etapa. **Corran en este orden**, porque cada uno usa lo anterior:

| # | Carpeta (cd) | Comando | Tiempo aprox. | Debe terminar con |
|---|---|---|---|---|
| 1 | `etapaA` | `A1_modelo_no_lineal_BoP` | segundos | `FIN A1` |
| 2 | `etapaA` | `A2_linealizar_BoP` | 1–2 min | `FIN A2` |
| 3 | `etapaC` | `C1_disenar_controlador_BoP` | ~1 min | `FIN C1` |
| 4 | `etapaD` | `D1_MIL_BoP` | 1–3 min | `FIN D1` |
| 5 | `etapaE` | `E0_build_Controller_BoP` | segundos | `FIN E0` |
| 6 | `etapaE` | `E1_verificar_equivalencia_BoP` | ~1 min | `FIN E1` |
| 7 | `etapaE` | Code Generation Advisor (sección 1.5) | — | Reporte guardado |
| 8 | `etapaE` | `E2_generar_codigo_BoP` | ~1 min | `FIN E2` |

Ejemplo, desde la raíz del proyecto:

```matlab
cd etapaA
A1_modelo_no_lineal_BoP
A2_linealizar_BoP
cd ../etapaC
C1_disenar_controlador_BoP
cd ../etapaD
D1_MIL_BoP
cd ../etapaE
E0_build_Controller_BoP
E1_verificar_equivalencia_BoP
```

### 1.4 Qué revisar en cada consola (comparación rápida con Octave)

Los valores de referencia de Octave están en `etapaX/verificacion_octave/`. En MATLAB deberían
salir **iguales o casi iguales**. Si algo difiere mucho, no lo corrijan: mándenlo.

| Script | Línea a mirar | Valor en Octave |
|---|---|---|
| A1 | `Pendiente en el neutro dth/dphi` | 0,3429 |
| A1 | `phi = -45 deg -> th` / `phi = +45 deg -> th` | −13,446 / 14,069 |
| A1 | `Maximo \|x_modelo - x_teorico\|` | ~1e-13 (debe ser casi cero) |
| A2 | `Cero de Xm/TH` | ±22,372j rad/s |
| A2 | `Diferencia relativa maxima con el analitico` | ~1e-13 |
| C1 | `Kp =` / `Kd =` / `Ki =` | 0,03412 °/mm / 0,02588 °/(mm/s) / 0,02275 °/(mm·s) |
| C1 | `Margen de fase PM =` | 40,9° |
| D1 | `R1 ts` … `R4` | Los cuatro con `CUMPLE` |
| E0 | `Bloque ley_control: 12 entradas, 3 salidas` | — |
| E1 | `Resultado: Parte A PASS, Parte B PASS` | En Octave, Parte B sin ejecutar |

> **D1 tiene ruido aleatorio con semilla fija.** MATLAB y Octave generan números aleatorios
> distintos, así que las métricas de D1 pueden variar en la segunda cifra. Lo importante es
> que se cumplan R1 a R4.

### 1.5 Code Generation Advisor (Etapa E, interfaz gráfica)

1. Abrir `etapaE/Controller_BoP.slx`. Si pide parámetros, correr antes `init_Controller_BoP`.
2. Pestaña **APPS** → **Embedded Coder**. Aparece la pestaña **C CODE**.
3. En **C CODE**, abrir el menú de verificación (**Check Code** / *Code Generation Advisor*).
4. Seleccionar el modelo `Controller_BoP` y correr todas las verificaciones. Los objetivos ya
   quedan fijados por E0 en *Execution efficiency* y *Traceability*.
5. **Criterio: cero Fail.** Las advertencias (*Warning*) se anotan, no se corrigen
   automáticamente.
6. **No usar "Fix All"** ni los botones de modificación automática.
7. Guardar el reporte (*Report → Save As*, HTML) en `etapaE/resultados/advisor/`.
8. Si sale algún Fail, **no toquen el modelo**: manden captura y texto del Fail.

Después corran `E2_generar_codigo_BoP`.

### 1.6 Si un script da error

- Copien **el mensaje completo** (todas las líneas rojas, incluido archivo y número de línea) a
  un `.txt` y mándenlo.
- **No cambien nada** del script para "arreglarlo".
- **E0 es el que más probablemente falle la primera vez**, porque no se pudo probar sin
  Simulink. Si E0 falla a mitad de camino y deja un `Controller_BoP.slx` incompleto, bórrenlo
  antes de volver a correrlo (E0 no sobrescribe un modelo existente).

---

## Parte 2 — Cámara y visión (PC Linux, con el plato y la cámara montados)

Todo se hace dentro de `proyecto_ControlDIP-develop/`.

### 2.1 Instalación (una vez)

```bash
cd proyecto_ControlDIP-develop
```

```bash
chmod +x setup.sh
```

```bash
sudo ./setup.sh
```

Después **cerrar sesión y volver a entrar**, para que tomen efecto los grupos `video` y
`dialout`. En cada terminal nueva:

```bash
source venv/bin/activate
```

Opcional, para confirmar que el software está bien antes de usar la cámara:

```bash
python -m unittest discover -s tests -t .
```

### 2.2 Paso crítico: verificar el campo de visión (cámara GW600)

Según las fichas, la GW600 tiene un FOV diagonal de 68,6°. A 450 mm, el campo vertical sería
de **~301 mm**, contra un plato de 300 mm (medio milímetro de margen). Si el modo 640×480 es un
recorte del sensor, **el plato no entra**. Hay que verlo antes de cualquier otra cosa.

1. Ver qué modos ofrece la cámara y anotarlos:

   ```bash
   v4l2-ctl --list-formats-ext -d /dev/video0
   ```

   Guarden la salida:

   ```bash
   v4l2-ctl --list-formats-ext -d /dev/video0 > formatos_camara.txt
   ```

2. Ver la imagen a 640×480 con el plato **horizontal**:

   ```bash
   python scripts/calibrate_camera.py
   ```

   La fase 1 es una previsualización. Comprueben que se vean **las cuatro marcas grabadas
   completas** y **todo el borde del plato**, con algo de margen. Guarden una captura de
   pantalla: `captura_fov_640x480.png`.

3. Si no entra:
   - **Opción A:** subir la cámara. Para tener ~17 mm de margen por lado, ~500 mm sobre la
     cara superior del plato. **Midan la altura nueva con cinta**, del lente a la cara superior
     del plato horizontal.
   - **Opción B:** si `formatos_camara.txt` muestra un modo 16:9 (por ejemplo 1280×720) a
     30 fps, se puede evaluar usarlo. Anótenlo y consulten antes de cambiar `config.py`.
   - Si cambian la altura, anótenla: hay que actualizar `CAMERA_HEIGHT_MM` en `config.py` y
     `P.H_cam` en `etapaA/A0_parametros_BoP.m`.

4. **Nitidez:** el foco fijo empieza en 50 cm. Miren si la bola y las marcas se ven nítidas. Un
   desenfoque leve no importa mucho.

5. **Pórtico:** la cámara debe quedar **sobre el centro del plato** y sin moverse. Una plomada
   desde el lente ayuda a centrarla. Si el pórtico se mueve, la calibración deja de valer.

### 2.3 Exposición y balance de blancos fijos

`v4l2_config.py` intenta fijar la exposición en 5 ms y el balance en 4600 K, y verifica que la
cámara lo aceptó. Al correr cualquier script de cámara, revisen la consola. Si dice que no pudo
fijar algún control, **anótenlo**: sin eso la calibración de color no es estable.

Para ver los controles que ofrece la cámara:

```bash
v4l2-ctl -d /dev/video0 --list-ctrls > controles_camara.txt
```

### 2.4 Iluminación

Luz **difusa e indirecta**: el acrílico vino brilla. Usen la iluminación definitiva desde ahora,
porque la calibración de color solo vale para la luz con que se hizo. Eviten la luz del sol
directa.

### 2.5 Periodo de muestreo (Ts)

Se mide en los dos formatos, MJPG y YUYV:

1. Con `FOURCC = "MJPG"` en `src/config.py`:

   ```bash
   python scripts/run_benchmark.py --period | tee periodo_MJPG.txt
   ```

2. Cambiar `FOURCC = "YUYV"` en `src/config.py` y repetir:

   ```bash
   python scripts/run_benchmark.py --period | tee periodo_YUYV.txt
   ```

3. **Criterio:** 95 % de los periodos dentro de ±5 ms. Gana el formato con menor periodo y menor
   jitter. Dejen ese formato en `config.py` y anoten cuál quedó.

### 2.6 Latencia de extremo a extremo

1. Pongan la cámara mirando un monitor, lo más cerca posible.
2. Corran:

   ```bash
   python scripts/run_benchmark.py --latency | tee latencia.txt
   ```

   El script hace destellos en una ventana, a pantalla completa si se puede. No muevan nada
   durante la medición.
3. Repitan 3 veces (`latencia_1.txt`, `latencia_2.txt`, `latencia_3.txt`).
4. El resultado incluye la latencia del monitor, así que es una cota superior. Anoten el modelo
   del monitor.

> Este es el dato que más afecta al controlador. Con 120 ms ya no se cumple el tiempo de
> establecimiento en el MIL.

### 2.7 Calibración de la perspectiva (homografía)

Con el plato **horizontal**, la cámara en su lugar definitivo y la luz definitiva:

```bash
python scripts/calibrate_camera.py
```

- Fase 1: `s` para capturar.
- Fase 2: cliquear la **esquina exterior** de cada marca, **en sentido horario**, empezando por
  la marca de arriba a la izquierda en la imagen. La marca pequeña va entre el servo X (+X) y
  −Y. `r` reinicia y `c` confirma.
- Copien la consola, sobre todo los lados en píxeles, la diferencia en porcentaje y la escala
  en px/mm, a `calibracion_camara.txt`.
- Se genera `calibration.npz`: **guárdenlo**.

### 2.8 Calibración del color de la bola

```bash
python scripts/calibrate_color.py
```

Ajusten hasta que la bola salga **blanca** y todo lo demás **negro**. Muevan la bola por todo el
plato, sobre todo por las esquinas. `g` guarda (`hsv_config.json`).

### 2.9 Signo del eje Y

1. Corran la visión sin serial:

   ```bash
   python scripts/main_vision.py --no-serial
   ```

2. Empujen la bola a mano **hacia el servo Y** (lado +Y del plato).
3. Si la lectura Y **sube**, todo bien. Si **baja**, pongan `INVERT_Y = True` en
   `src/config.py`.
4. Hagan lo mismo hacia el servo X con la lectura X. Si X baja, anótenlo y consulten, porque no
   hay opción `INVERT_X`.
5. Anoten el resultado.

### 2.10 Ruido de medición

Bola **quieta en el centro**, plato horizontal, luz definitiva:

```bash
python scripts/medir_ruido.py -n 500 | tee ruido_centro.txt
```

Repítanlo con la bola cerca de una esquina (`ruido_esquina.txt`). El script dice qué poner en
`MEAS_NOISE_STD_MM`: anótenlo, pero **no cambien todavía `PROCESS_ACCEL_STD`**. Esa decisión
(pasar de 1500 a 500) se toma con este dato.

### 2.11 Exactitud de la calibración (opcional, recomendado)

Pongan la bola en 5 puntos medidos con regla sobre el plato: el centro y cerca de cada esquina.
Anoten la posición medida con regla y la que da `main_vision.py`. Criterio del pipeline: error
menor a 3 mm.

### 2.12 Archivos de la Parte 2

Todos en `datos_prototipo/camara/` (ver la sección 5):

- `formatos_camara.txt`, `controles_camara.txt`, `captura_fov_640x480.png`
- `periodo_MJPG.txt`, `periodo_YUYV.txt`, `latencia_1..3.txt`
- `calibracion_camara.txt`, `calibration.npz`, `hsv_config.json`
- `ruido_centro.txt`, `ruido_esquina.txt`, signo de los ejes y la tabla de exactitud

---

## Parte 3 — Mecánica y servos (con el prototipo)

### 3.0 Seguridad antes de energizar

El esquema de cableado completo, con la fuente externa, el GND común, el capacitor y las resistencias, está en `docs/conexiones_esp32_servos.html`.

- [ ] Los servos se alimentan de una **fuente aparte** (4,8–6 V, al menos 2 A), **no** del
      pin de 5 V de la ESP32.
- [ ] **GND común** entre la fuente de los servos y la ESP32.
- [ ] Antes de conectar los brazos, mandar el servo a neutro (pulso de 1500 µs) y montar el
      brazo **horizontal** en esa posición.
- [ ] El sketch limita el comando a ±45°. No pasar de ahí: es el tope físico del servo.
- [ ] Mano cerca del interruptor de la fuente las primeras veces.

### 3.1 Sketch mínimo para mover los servos (ESP32, Arduino IDE)

**Esto no es el firmware del controlador.** Solo sirve para poner cada servo en un ángulo fijo
desde el Monitor Serie. Necesita la librería **ESP32Servo** (*Herramientas → Administrar
bibliotecas* → buscar *ESP32Servo*). Cambien los pines si usan otros.

```cpp
// prueba_servos.ino — mover cada servo a un angulo fijo (solo para mediciones)
// Monitor Serie a 115200 baudios, "Ambos NL & CR". Comandos:
//   X 10    -> servo X a +10 grados respecto del neutro
//   Y -5    -> servo Y a -5 grados
//   C       -> ambos al neutro
#include <ESP32Servo.h>

const int PIN_X = 18;          // cambiar si se usa otro pin
const int PIN_Y = 19;
const int US_NEUTRO = 1500;    // pulso del neutro [us]
const float US_POR_GRADO = 1000.0 / 90.0;   // hoja de datos: 1 ms a 2 ms ~ 90 grados
const float LIM = 45.0;        // tope fisico del servo [grados]

Servo sx, sy;

void mover(Servo &s, float g, const char *nombre) {
  if (g > LIM) g = LIM;
  if (g < -LIM) g = -LIM;
  int us = US_NEUTRO + (int)(g * US_POR_GRADO);
  s.writeMicroseconds(us);
  Serial.printf("%s = %+.1f grados (%d us)\n", nombre, g, us);
}

void setup() {
  Serial.begin(115200);
  sx.setPeriodHertz(50);  sy.setPeriodHertz(50);
  sx.attach(PIN_X, 500, 2500);  sy.attach(PIN_Y, 500, 2500);
  mover(sx, 0, "X");  mover(sy, 0, "Y");
}

void loop() {
  if (!Serial.available()) return;
  String l = Serial.readStringUntil('\n');  l.trim();
  if (l.length() == 0) return;
  char eje = toupper(l.charAt(0));
  float g = l.substring(1).toFloat();
  if (eje == 'X') mover(sx, g, "X");
  else if (eje == 'Y') mover(sy, g, "Y");
  else if (eje == 'C') { mover(sx, 0, "X"); mover(sy, 0, "Y"); }
}
```

> El paso de 11,1 µs por grado sale de la hoja de datos. **No se sabe** si el servo real cumple
> eso: lo que importa es el ángulo del **plato** que se mide para cada comando (paso 3.3).

### 3.2 Datos del montaje (anotar)

| Dato | Cómo | Valor |
|---|---|---|
| Modelo de servo instalado | Etiqueta del servo (¿MG90D o MG90S?) | |
| Tensión de la fuente de los servos | Multímetro en los bornes, con los servos conectados | |
| Placa ESP32 exacta | Serigrafía de la placa o modelo de compra | |
| Lado del brazo en neutro | ¿La punta del brazo apunta hacia el centro del plato o hacia afuera? | (el diseño dice: hacia el centro) |
| Sentido del servo | Con `X 10`, ¿el lado +X del plato **sube** o **baja**? Lo mismo con `Y 10` | |
| Altura del centro de la junta | Con el plato horizontal: altura de la **cara superior del plato** y del **centro de la cruceta** de la junta, medidas desde la cara superior de la base | |
| Altura de la cámara | Del lente a la cara superior del plato horizontal | |

> **La altura de la junta es el dato geométrico que más pesa en el modelo.** Mide la distancia
> entre la cara del plato y el centro de rotación (h_sup, 49 mm en el diseño). El centro de la
> cruceta es el punto donde se cruzan los dos ejes de giro de la junta.

### 3.3 Relación ángulo de servo → ángulo de plato

Con un inclinómetro (sirve la app de nivel del celular, apoyado sobre el plato **en el centro y
alineado con el eje**):

1. `C` (neutro). Anoten la inclinación del plato en X y en Y: es el **desnivel en reposo**.
2. Para el eje X manden, en este orden: `X -40`, `X -30`, `X -20`, `X -10`, `X 0`, `X 10`,
   `X 20`, `X 30`, `X 40`. Anoten el ángulo del plato en X **y también en Y**, porque se mide el
   acople.
3. Vuelvan a `X 0` **desde el otro lado**: de `X 40` pasen directo a `X 0`, y de `X -40` también.
   Si el plato no vuelve al mismo ángulo, esa diferencia es la **holgura** (histéresis).
4. Repitan lo mismo para el eje Y.
5. Al final, prueben `X 45` y `X -45` con cuidado. Si el servo zumba o no llega, anótenlo: es
   la carrera real.

Tabla: `datos_prototipo/mecanica/servo_plato.csv`.

```
eje,comando_deg,desde,th_plato_x_deg,th_plato_y_deg,nota
X,-40,abajo,...,...,
```

En la columna `desde` va `abajo`, `arriba` o `neutro` (desde dónde se llegó al comando).

### 3.4 Dinámica del servo (opcional, muy útil)

El modelo supone que el servo responde como un sistema de segundo orden con ωn = 50 rad/s,
**pero es un supuesto**. Para medirlo:

1. Peguen un transportador de papel detrás del brazo de un servo.
2. Graben con el celular en **cámara lenta** (120 o 240 fps) mientras mandan `X 20` desde `X 0`
   y luego `X 0` desde `X 20`.
3. Guarden el video (`servo_escalon_X_120fps.mp4`) y anoten los fps reales del video.

---

## Parte 4 — Ensayos para la Etapa B (identificación del modelo)

**Requisitos:** Parte 2 completa (cámara calibrada, color calibrado, signo de Y) y sketch de la
3.1 funcionando.

La planta no se puede probar con un escalón en lazo abierto, porque la bola se va a la pared.
Los ensayos usan **inclinación fija y la bola suelta desde el reposo**. La bola sigue una
parábola, y de ahí sale el coeficiente de rodadura c (hoy 5/7 nominal).

### 4.1 Cómo se registra cada ensayo

- En una terminal, con la visión corriendo (escribe `logs/sesion_AAAAMMDD_HHMMSS.csv` con t,
  dt, posición cruda y filtrada, velocidades, etc.):

  ```bash
  python scripts/main_vision.py --no-serial
  ```

- **Un CSV por ensayo:** se arranca `main_vision.py`, se hace el ensayo y se corta con
  Ctrl-C. Después se renombra el archivo según la tabla de la 4.4.
- Anoten en el cuaderno, por ensayo: nombre del archivo, comando del servo, ángulo del plato
  medido con el inclinómetro, posición de suelta y observaciones.

### 4.2 Ensayo B1 — Rodadura con inclinación fija (el principal)

Para cada eje (empezar por X) y cada ángulo:

1. Con el sketch, pongan el servo en un comando fijo, por ejemplo `X 10`.
2. **Midan el ángulo del plato** con el inclinómetro y anótenlo.
3. Arranquen `main_vision.py --no-serial`.
4. Sostengan la bola quieta **contra el borde alto** del plato, o donde quepa con margen.
   Esperen 1 s y **suéltenla sin empujarla**, separando el dedo hacia arriba.
5. Dejen que ruede hasta el borde bajo y que se quede quieta 1 s. Corten con Ctrl-C.
6. Repitan **3 veces** cada ángulo.

Ángulos: comandos de servo **±10°, ±20° y ±30°** (más o menos ±3,4°, ±6,8° y ±10,2° de plato),
en los dos sentidos y en los dos ejes. Son 6 ángulos × 2 ejes × 3 repeticiones = **36 ensayos**.
Si el tiempo no alcanza, prioricen el eje X completo.

> Con ángulos chicos la bola puede no arrancar, o frenarse, por la fricción. **Anótenlo**: eso
> también es un dato (umbral de rodadura). Con ±10° de servo, si no arranca, prueben ±5°.

### 4.3 Ensayo B2 — Efecto de la inclinación sobre la medición de la cámara

Comprueba que la cámara ve una posición distinta cuando el plato está inclinado (modelo
Xm = x − h·θ de la Etapa A):

1. Con el plato horizontal, pongan la bola quieta **apoyada contra el borde +X**. Registren 3 s.
2. Manden el comando de 20° de servo que **baja el lado +X**. El signo depende del sentido que
   anotaron en la tabla de la 3.2. Así la bola queda apretada contra el mismo borde y no se
   mueve sobre el plato. Midan el ángulo del plato y registren 3 s.
3. Repitan con 30°.
4. Lo mismo contra el borde −X, con los comandos que bajan el lado −X.

Si el modelo de la Etapa A está bien, la posición medida cambia unos milímetros, aunque la bola
no se movió sobre el plato.

### 4.4 Nombres de los archivos de la Parte 4

`datos_prototipo/etapaB/` con los CSV renombrados así:

```
B1_X_cmd+10_rep1.csv    B1_X_cmd+10_rep2.csv    ...    B1_Y_cmd-30_rep3.csv
B2_X_borde+X_cmd000.csv B2_X_borde+X_cmd20.csv  B2_X_borde+X_cmd30.csv ...
```

Más una tabla `datos_prototipo/etapaB/ensayos.csv`:

```
archivo,eje,comando_deg,th_plato_medido_deg,posicion_suelta_mm,repeticion,observaciones
B1_X_cmd+10_rep1.csv,X,10,3.5,-110,1,"arranco bien"
```

---

## 5. Qué devolver y cómo

### 5.1 Estructura

Lo más simple es dejarlo todo en la carpeta del proyecto y subirlo a la rama
(`git add`, `git commit` y `git push`). Si no, en un `.zip` con esta estructura:

```
LAB-CONTROL/
├── ver_matlab.txt
├── etapaA/resultados/            (todo lo que generó MATLAB)
├── etapaC/resultados/
├── etapaD/resultados/
├── etapaE/resultados/            (incluye advisor/)
├── etapaE/Controller_BoP.slx
├── etapaE/codigo_generado/
└── datos_prototipo/
    ├── camara/                   (Parte 2)
    ├── mecanica/                 (Parte 3: servo_plato.csv, tabla de la 3.2, videos)
    ├── etapaB/                   (Parte 4: CSV y ensayos.csv)
    └── cuaderno.txt              (notas, fechas, condiciones, cosas raras)
```

### 5.2 Prioridad, si no da tiempo para todo

1. **Parte 1**, completa: no necesita el prototipo.
2. **Parte 2:** campo de visión (2.2), latencia (2.6), periodo (2.5) y ruido (2.10).
3. **Parte 3:** altura de la junta, tabla servo → plato, desnivel en reposo, tensión y modelo
   del servo.
4. **Parte 4:** ensayos B1 del eje X.

### 5.3 Qué pasa después

Con eso se cierran las Etapas A y B y se actualizan los parámetros. C y D se vuelven a correr
con los valores medidos, y E se completa con la tabla modelo ↔ código. Después siguen SIL (F),
PIL (G) y la implementación (H). El firmware de la ESP32 se escribe a partir del código generado
en la Etapa E.
