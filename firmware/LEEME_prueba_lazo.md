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
