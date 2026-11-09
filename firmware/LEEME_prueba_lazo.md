# Prueba funcional del lazo cerrado

`bop_prueba_lazo/bop_prueba_lazo.ino` es un **firmware de prueba escrito a mano**. Sirve para
verificar que el sistema completo funciona antes de terminar las Etapas E a G. Lo decidió el
equipo el 2026-11-04 por tiempo.

- La ley de control es la misma de `etapaC/funciones/bop_ley_control.m`, la que se evaluó en el
  MIL. Se comprobó en una compilación en PC contra Octave: diferencia máxima de 6e-7° en θ y en
  el integrador, en 300 pasos, 69 de ellos saturados.
- La conversión de ángulo de plato a comando del servo usa la tabla medida el 2026-11-04 (v2),
  invertida por tramos lineales. El MIL usa una interpolación suave (pchip); la diferencia es
  pequeña.
- En la Etapa H se reemplaza la ley por el código generado de `Controller_BoP.slx`.

**No es la implementación final** ni reemplaza la verificación SIL/PIL (CLAUDE.md, sección 5).

## 1. Antes de empezar (PC Linux)

1. **Kalman:** el controlador se diseñó con `PROCESS_ACCEL_STD = 500` (Etapa C). En
   `proyecto_ControlDIP-develop/src/config.py` cambien `PROCESS_ACCEL_STD = 1500.0` a `500.0`.
   Con 1500 el plato tiembla más. Anoten qué valor usaron.
2. **Signo de los ejes de la visión.** Corran:

   ```bash
   python scripts/main_vision.py --no-serial
   ```

   - Empujen la bola a mano **hacia el servo X**: la lectura **X debe subir**.
   - Empujen la bola **hacia el servo Y**: la lectura **Y debe subir**.
   - Si Y baja: `INVERT_Y = True` en `config.py`.
   - Si X baja: en el firmware cambien `SIGNO_VIS` a `{-1.0f, +1.0f}`.

   **Este paso es obligatorio.** Con un signo equivocado, el controlador empuja la bola hacia
   el borde en vez de traerla al centro.
3. Comprueben que la ESP32 aparece como puerto serie:

   ```bash
   ls /dev/ttyUSB*
   ```

   Si no es `/dev/ttyUSB0`, cambien `SERIAL_PORT` en `config.py`.

## 2. Cargar el firmware

1. Arduino IDE → abrir `firmware/bop_prueba_lazo/bop_prueba_lazo.ino`. La carpeta tiene que
   llamarse igual que el archivo.
2. Placa **"ESP32 Dev Module"** del paquete de Espressif, y el puerto de la ESP32.
3. Subir. **Después, cerrar el Monitor Serie**: el puerto lo va a usar `main_vision.py`.

Al arrancar, la ESP32 queda **desarmada**: el plato se pone horizontal (el neutro sale de la
tabla) y el LED azul queda apagado.

## 3. Prueba

**Seguridad:** fuente de los servos con interruptor a mano. Encender primero la ESP32 (USB) y
después la fuente. Nadie con la cara cerca del plato.

1. Con la bola en el plato, corran:

   ```bash
   sudo chrt -r 50 ./venv/bin/python scripts/main_vision.py
   ```

   Sin `--no-serial`. Revisen que la consola diga `serial:si`.
2. Con la ESP32 desarmada, el plato debe quedarse horizontal. El LED parpadea rápido mientras
   no llegan tramas (watchdog) y se apaga cuando empiezan a llegar.
3. Pongan la bola **cerca del centro** y **presionen BOOT**: el LED queda encendido y el
   controlador actúa.
   - **Bien:** la bola se queda cerca del centro y vuelve si la mueven con la mano.
   - **Mal:** la bola acelera hacia un borde. **Presionen BOOT** (desarma y deja el plato
     horizontal) o apaguen la fuente. Casi siempre es un signo de los ejes (paso 1.2).
4. Si funciona, prueben en este orden:
   - **a.** soltar la bola quieta a unos 100 mm del centro, en X y después en Y;
   - **b.** un empujón suave con el dedo;
   - **c.** dejar la bola quieta en el centro 10 s, para ver el temblor y el error final.
5. Para terminar: Ctrl-C en `main_vision.py`. La PC manda "sin bola" y el plato queda
   horizontal. Después apaguen la fuente de los servos.

## 4. Qué guardar y mandar

- Los CSV de `proyecto_ControlDIP-develop/logs/` de cada prueba. **Anoten cuál es cuál**: 4a X,
  4a Y, 4b y 4c.
- Si pueden, un **video** de cada prueba.
- Qué valor de `PROCESS_ACCEL_STD` usaron, los `SIGNO_VIS` y si tuvieron que cambiar
  `INVERT_Y`.
- Cualquier cosa rara: oscilación, ruido de los servos, bola que se va, LED parpadeando.

Con los CSV se calculan las mismas métricas del MIL (ts, Mp, ess) y se comparan.

## 5. Si algo no anda

| Síntoma | Qué revisar |
|---|---|
| El LED sigue parpadeando rápido con `main_vision.py` corriendo | No llegan tramas: puerto equivocado, Monitor Serie abierto o la consola dice `serial:NO` |
| La bola se va a un borde apenas se arma | Signo de un eje (sección 1, paso 2) |
| La bola oscila cada vez más | Retardo real mayor al supuesto; anoten y manden el CSV. Prueben bajar `KP` y `KD` un 30 % en el firmware y anótenlo |
| El plato tiembla mucho en reposo | Ruido de la cámara: `PROCESS_ACCEL_STD` en 500, luz, calibración de color |
| La bola queda quieta lejos del centro | Esperen unos segundos: el integrador lo corrige. Si no se mueve, manden el CSV |

---

## Versión 2 (`bop_prueba_lazo_v2/`, 2026-11-05)

**Qué se vio en la primera prueba** (video del equipo):
- La bola se estabiliza en el centro: el lazo básico funciona.
- Mientras se sostiene la bola con la mano lejos del centro, el plato se inclina cada vez
  más. Con la bola quieta, el integrador la toma por un desnivel y se carga hasta el límite.
- Cerca del borde, la bola queda un rato quieta y después el plato da un **brinco** y la bola
  sale despedida. La explicación más probable es que la bola **sale del campo de la cámara**
  (con la GW600 a 450 mm hay ~0,5 mm de margen). La visión la pierde y manda `estado = 0`,
  la ESP32 pone el plato horizontal **de golpe** y borra el integrador, y al reaparecer la
  bola el controlador arranca con un error grande.

**Cambios del firmware v2** (protecciones de prueba, **todavía no evaluadas en el MIL**):

| Cambio | Valor | Para qué |
|---|---|---|
| Límite de velocidad del ángulo pedido | 3° por cuadro (90°/s) | Sin saltos bruscos cuando la bola se pierde o reaparece |
| El integrador solo actúa cerca de la referencia | \|error\| < 40 mm | No se carga con la bola sostenida o contra el borde |
| Tope del integrador | ±3° | Ídem |
| Filtro de saltos de posición | > 60 mm en un cuadro se ignora; tras 3 seguidos se acepta | Falsas detecciones (mano, reflejos) |
| Sin bola o sin tramas | Vuelve a horizontal con rampa | Sin golpes |

**Además del firmware, revisen el montaje:**
1. **Que el plato completo salga en la imagen aunque esté inclinado.** Con `prueba_servos.ino`,
   inclinen el plato a mano con `X 20`, `X -20`, `Y 20` e `Y -20`. Con
   `python scripts/calibrate_camera.py` (fase 1, solo vista) comprueben que el borde y la
   zona donde puede estar la bola siguen dentro de la imagen. Si no, **suban la cámara a
   ~500 mm**, actualicen `CAMERA_HEIGHT_MM` en `config.py` y recalibren.
2. **Que la base no se mueva.** Si la estructura salta cuando los servos se mueven rápido,
   la posición del plato respecto de la cámara cambia y la calibración deja de valer. Fijen la
   base y el pórtico a la misma tabla (con tornillos o prensas).
3. **Que los ejes no estén cruzados.** Como hubo que girar el plato, comprueben con
   `main_vision.py --no-serial` que al empujar la bola **solo hacia el servo X** cambie **solo**
   la lectura X, y que con el servo Y cambie solo la Y. Si al empujar hacia el servo X cambia la
   Y, los ejes están intercambiados.

**Qué mandar:** los CSV de `logs/` de las corridas donde pasó el brinco. La columna
`detectada` muestra si la bola se perdió justo antes, que es lo que confirma o descarta la
explicación del campo de la cámara.

## Pruebas de movimiento circular (2026-11-09)

Son pruebas funcionales. No están en el MIL ni en el código generado.

### `prueba_circulo_abierto/` — solo motores, sin cámara

- El plato mantiene una inclinación fija A, pero la dirección de esa inclinación gira con
  periodo T: θx = A·cos(2πt/T) y θy = A·sin(2πt/T). Usa la tabla servo → plato medida.
- Comandos por el Monitor Serie (115200 baud):

  | Comando | Qué hace |
  |---|---|
  | `S` | Arranca o detiene |
  | `A 3` | Amplitud en grados de plato |
  | `T 2.5` | Periodo de una vuelta en segundos |
  | `R` | Invierte el sentido de giro |
  | `C` | Deja el plato horizontal |

- Una bola describe idealmente un círculo de radio R = c·g·A/ω². Por ejemplo, A = 3,1° con
  T = 2,5 s da R ≈ 60 mm. El sketch imprime el radio esperado.
- **En lazo abierto la bola termina yéndose.** La órbita es solo marginalmente estable y un
  desnivel de 0,2° ya la empuja a unos 24 mm/s².
- La amplitud sube con una rampa de coseno de 10 vueltas. En simulación, con el modelo lineal y
  la bola soltada en el centro, el centro de la órbita queda corrido unos 10 mm; con una rampa
  lineal quedaba corrido 60 mm.
- Sirve para ver los dos servos y la tabla trabajando juntos.

### `bop_prueba_circulo_lazo/` — la bola sigue una circunferencia (lazo cerrado)

- Es una copia del v2 con la referencia r(t) = R·(cos ωt, sin ωt). Por defecto R = 60 mm y
  T = 4 s; el radio crece en rampa durante 3 s.
- Con la referencia en movimiento, el derivativo actúa sobre (v̂ − v_ref) y se suma la
  prealimentación θ_ff = −a_ref/(c·g), que sale del modelo de la Etapa A.
- Con la referencia quieta, la ley es igual a la del v2.
- El botón BOOT cicla los modos:

  | Modo | LED |
  |---|---|
  | Desarmado | Apagado |
  | Centro | Encendido |
  | Círculo | Parpadeo lento |

- Se usa igual que el v2, con `main_vision.py` mandando las tramas.
- **Simulación previa** (Claude, modelo lineal con 75 ms de retardo, Ts = 1/30 s, límite de
  velocidad del plato, sin ruido): después del transitorio, la bola recorre un círculo de
  64,7 mm con un error de seguimiento de unos 12 mm, que es casi todo atraso por el retardo.
  - Sin la prealimentación, el error sube a 24 mm.
  - Sin la prealimentación y sin v_ref, sube a 57 mm.
- **No es una medición.** En el prototipo influyen c (todavía nominal), el desnivel, el ruido y
  el retardo real.

**Telemetría (2026-11-09).** `bop_prueba_circulo_lazo` contesta cada trama con 49 bytes: modo,
banderas, inclinación aplicada y salida de la ley por eje, integradores, referencia y un eco de
la x recibida. `main_vision.py` la guarda en las columnas `tel_*` del log. El formato está al
principio del `.ino`. La usa `etapaB/B3_identificar_lazo_cerrado_BoP.m`. Los firmware v1 y v2 no
mandan telemetría y siguen funcionando igual: las columnas quedan vacías.

**Lectura serie (2026-11-09).** Con la lectura byte a byte, la ESP32 atendía una trama cada 40 ms
y el lazo trabajaba con 0,6 s de atraso (`estado_proyecto.md`). `bop_prueba_circulo_lazo` ahora
lee en bloque y usa solo la trama más nueva. **Los firmware v1 y v2 siguen con la lectura vieja.**
