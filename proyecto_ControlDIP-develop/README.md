# Ball and Plate 2 DOF - Vision & Comm Pipeline

Vision por computadora, filtrado y comunicacion para una planta Ball and Plate
de 2 grados de libertad. Python (OpenCV/NumPy) sobre Linux, pensado para correr
con prioridad de tiempo real.

Este repositorio **no** contiene el controlador. El PD y la cinematica inversa
de angulo de plato a angulo de servo viven en el firmware de la ESP32, que
recibe la trama binaria descrita mas abajo.

## Arquitectura

| Modulo | Responsabilidad |
|---|---|
| `src/config.py` | **Configuracion unica.** Camara, geometria, umbrales, filtro, serial |
| `src/camera/v4l2_config.py` | Bloquea autoexposicion, balance de blancos y framerate, y lo **verifica** |
| `src/camera/capture.py` | Abre la camara con `BUFFERSIZE=1` y FOURCC explicito |
| `src/processing/calibrator.py` | Homografia de pixeles a mm, ROI y escala px/mm |
| `src/processing/detector.py` | Segmentacion HSV, validacion por area y circularidad, centroide |
| `src/processing/kalman.py` | Filtro de Kalman con `dt` variable y Q/R con significado fisico |
| `src/communication/transmitter.py` | Trama binaria a la ESP32, con reconexion y cierre seguro |
| `src/datalog.py` | CSV por sesion para las graficas del informe |

## Geometria y convenios

- El plato mide 300 x 300 mm, pero la homografia se calibra sobre el cuadrado
  de **290 mm** que forman las **esquinas exteriores** de las cuatro marcas
  grabadas (cada una a 5 mm del borde). Los **centros** de las marcas no
  forman un cuadrado, porque el patron de alineacion mide 20 mm y los otros
  tres 28 mm.
- El origen queda en el centro del plato. El rango util del centro de la bola
  es **+-127 mm**, no +-150: el borde se come 3 mm por lado y el centro de una
  bola de 40 mm no puede acercarse mas de 20 mm a la pared.
- La homografia mapea el **plano del plato**, pero el centro de la bola esta
  20 mm por encima. Con la camara a 450 mm, lo medido sale escalado por 1.047,
  asi que se corrige multiplicando por `config.parallax_scale()` = 0.956.
  Son unos 6 mm en el borde.
- Si el `+Y` de la vision no coincide con el `+Y` mecanico, ese eje queda con
  realimentacion **positiva** y la bola se va al borde. Se verifica empujando
  la bola a mano hacia el servo Y; si la lectura baja en vez de subir, poner
  `INVERT_Y = True` en `src/config.py`.

## Protocolo serial (sin cambios)

Trama de 20 bytes, little-endian:

```
[0xAA] [estado: uchar] [X: float] [Y: float] [Vx: float] [Vy: float] [XOR: uchar] [0x55]
```

`estado = 1` significa estimacion valida (medida, o predicha durante como
mucho `MAX_COAST_FRAMES` ciclos). `estado = 0` significa sin bola: la ESP32
debe llevar el plato a horizontal. **El firmware necesita ademas un watchdog**
que lleve los servos a neutro si no recibe tramas en unos 200 ms.

## Despliegue

```bash
chmod +x setup.sh
sudo ./setup.sh
```

Despues de correrlo hay que cerrar sesion y volver a entrar, para que tomen
efecto los grupos `dialout` y `video`. Con esos grupos **no hace falta `sudo`**
para correr los scripts; `sudo` solo se necesita para `chrt`.

## Orden de puesta en marcha

```bash
source venv/bin/activate

# 1. Caracterizar la camara: periodo entre frames y latencia real.
python scripts/run_benchmark.py --period
python scripts/run_benchmark.py --latency

# 2. Calibrar la perspectiva. CLIQUE LA ESQUINA EXTERIOR DE CADA MARCA.
python scripts/calibrate_camera.py            # -> calibration.npz

# 3. Calibrar el color de la bola, con la iluminacion definitiva.
python scripts/calibrate_color.py             # -> hsv_config.json

# 4. Medir el ruido del centroide con la bola quieta.
python scripts/medir_ruido.py -n 500          # -> MEAS_NOISE_STD_MM

# 5. Lazo completo. Sin ventana para medir de verdad.
sudo chrt -r 50 ./venv/bin/python scripts/main_vision.py --no-display
```

El paso 4 no es opcional: `MEAS_NOISE_STD_MM` es la raiz de R en el filtro de
Kalman. Sin medirlo, R es un numero inventado y el filtro queda mal
sintonizado por ordenes de magnitud.

Opciones de `main_vision.py`: `--no-display`, `--no-serial`, `--require-serial`,
`--no-log`.

## Registro de datos

Cada corrida escribe `logs/sesion_AAAAMMDD_HHMMSS.csv` con tiempo, dt, fps,
posicion cruda, posicion filtrada, velocidades, area, circularidad y si la
trama salio. De ahi salen las graficas del informe.

## Pruebas

```bash
python -m unittest discover -s tests -t .    # o: python -m pytest tests/
```

## Criterios de aceptacion

| Prueba | Criterio | Script |
|---|---|---|
| Latencia de extremo a extremo | media < 60 ms | `run_benchmark.py --latency` |
| Estabilidad del periodo | 95 % dentro de +-5 ms | `run_benchmark.py --period` |
| Ruido de posicion | desviacion < 1 mm | `medir_ruido.py` |
| Calibracion en mm | error < 3 mm contra regla | manual |
| Deteccion | > 99 % de frames, sin falsos positivos | `main_vision.py` |

## Pendiente

- Detectar los patrones grabados automaticamente, en vez de los cuatro clics.
  Las marcas se grabaron justamente para eso, y el patron pequeno da la
  orientacion sin ambiguedad.
- Watchdog en el firmware de la ESP32.
- Controlador PD y cinematica inversa (viven en la ESP32).
