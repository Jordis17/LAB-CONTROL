# Etapa G — PIL (Processor-in-the-loop) en la ESP32

## Qué se verifica

Que el código generado del controlador, **compilado para la ESP32 y ejecutado en su procesador**,
calcule lo mismo que el modelo. En PIL, Simulink le manda a la ESP32 las entradas de cada paso
por el puerto serie, la ESP32 ejecuta `Controller_BoP_step` y devuelve las salidas.

| Qué corre en la ESP32 | Qué sigue simulado en la PC |
|---|---|
| El código C de `Controller_BoP` (ley de control, saturación, integrador), compilado con el compilador Xtensa del paquete de Arduino | La planta (bola, servo, cámara, Kalman), la referencia y la comparación |

**Un PASS en PIL** significa que el código funciona en el procesador objetivo conservando el
comportamiento. **No es** una validación con la planta real: no hay cámara, ni servos, ni la
temporización de 30 fps en tiempo real (CLAUDE.md, sección 5).

## El paquete de Arduino no habilita PIL en la ESP32 (2026-11-06)

Evidencia (`resultados/G0_consola.txt`, `G0b_consola.txt`, `G0c_consola.txt`):

1. La única conexión PIL del paquete, "Arduino Board" (`arduinoregistry/registerpil.m`), se
   declara compatible solo si la placa tiene `boardInfo.IsPilSupported = true`.
2. Due, Mega 2560, Uno, Nano 33 IoT y Teensy 4.1 lo tienen en `true`. La clase de nuestra placa,
   `ESP32WROOMdevkitC_38Board` (variante *ESP32-WROOM-DevKitC(38 pin)*), lo tiene en **0**.
3. Además, con la variante de la ESP32 vacía, `GetBoard` falla con `Index exceeds array bounds`.
   Ese fue el error de las primeras corridas de G0. Ahora G0 elige la variante
   (`funciones/g_variante_esp32.m`).

Esto contesta lo que CLAUDE.md dejaba **PENDIENTE**: con R2026a, el PIL oficial no está
habilitado para la ESP32.

**Alternativa de ingeniería (ruta elegida, porque el equipo no tiene otra placa):**
`pil_esp32/rtwTargetInfo.m` registra una configuración de conexión PIL propia, "ESP32 BoP
(Arduino PIL)". Usa una subclase sin cambios (`pil_esp32/+bop_pil/ConnectivityConfigESP32.m`) de la clase de conexión del paquete
(`codertarget.arduinotarget.pil.ConnectivityConfig`). Hace falta la subclase porque Simulink no deja registrar la misma clase en dos configuraciones, que compila con la toolchain ESP32 del
paquete, graba la placa y se comunica por el puerto serie, y la declara compatible con modelos
cuya placa sea una ESP32. Es el mecanismo documentado por MathWorks para agregar PIL a un
procesador (*Create PIL Target Connectivity Configuration*). No se modifica ningún archivo del
paquete.

Como MathWorks no probó esta combinación, el resultado vale por la comparación, no por la
herramienta. Si la ESP32 devuelve exactamente lo mismo que el modelo en todas las muestras, el
código corrió en su procesador y calculó lo mismo. Si la ruta falla, el plan B es escribir
también el lado de comunicación y carga (rtiostream propio).

## Intento con el PIL de Simulink y por qué no se usa (2026-11-06)

Antes de llegar a la ruta propia se probó el PIL de Simulink con una conexión registrada a mano
(`pil_esp32/rtwTargetInfo.m` y `pil_esp32/+bop_pil/ConnectivityConfigESP32.m`, una subclase sin
cambios de la del paquete). Con eso Simulink sí tomó la conexión y **compiló el controlador
con el compilador Xtensa de la ESP32 sin errores**. Lo que falló fue la clase PIL del paquete
por dentro (código cerrado .p): pide la variable `arduinoheaderPath`, que solo existe para las
placas soportadas, y no lee el puerto (`COM port:` vacío) (`resultados/G0_consola.txt`). Seguir
parchándola sería adivinar, así que se dejó.

Tampoco sirve la ruta del *Target Framework*: ahí la placa ESP32 no tiene procesador,
interfaces de comunicación ni protocolo PIL definidos.

## Ruta PIL propia (G3, G4, G5)

| Qué corre en la ESP32 | Qué sigue en la PC (MATLAB) |
|---|---|
| **Exactamente** el código C de `etapaE/codigo_generado`, el mismo verificado en SIL (G3 comprueba que la copia sea idéntica byte a byte), compilado con la toolchain Xtensa del paquete de Arduino (`arduino-cli`, FQBN `esp32:esp32:esp32`). Dos instancias, una por eje. | La planta (`planta_bop_paso`, la del banco SIL), la referencia, la rama Normal y la comparación |

`pil_esp32/bop_pil_esp32/bop_pil_esp32.ino` **no contiene el algoritmo**. Solo hace de puente
serie: recibe `r`, `x_hat`, `v_hat` y `habilitado` como double IEEE de 8 bytes (sin
redondeo), llama `Controller_BoP_step` y devuelve `th_cmd`, `I`, `saturado` y los ciclos
de CPU que tardó la llamada. El protocolo está descrito al principio del sketch. Es el mismo
esquema del PIL de Simulink (el código en el procesador y lo demás en la PC), con un
comunicador propio.

**Por qué no se usa el código generado con la placa ESP32** (`Controller_BoP_ESP32`, G3 del
2026-11-06): no es idéntico al verificado en SIL, porque cambiar la placa hizo que Embedded Coder
agregara una variable temporal (`tmp_0`), y además depende de encabezados de Simulink
(`rtw_continuous.h`) que no compilan fuera de MATLAB. La Etapa G pide conservar sin cambios lo
validado. Lo que se verifica es que **ese** código, compilado para Xtensa, calcule lo mismo en
la ESP32.

**Prueba previa (Claude, 2026-11-06):** el sketch compilado en la PC con un Arduino simulado
responde bien al protocolo: el paso de prueba (x = 10 mm, r = 0, v = 0) da th = Kp·10 =
0,0059549 rad.

**Banco en lazo cerrado (G5).** Tiene dos ramas, Normal y PIL, cada una con su propia planta.
Comparten la referencia, la habilitación, la condición inicial, Ts, el ruido y la duración. El
ensayo es el mismo del banco SIL. La rama Normal ejecuta en MATLAB la misma ley del bloque
(`bop_ley_control` con la envoltura de `ley_control_BoP_bloque`), que E1 mostró idéntica bit a
bit al modelo.

**Control de coherencia.** La rama Normal de G5 se compara con la rama Normal del banco SIL de
Simulink (`etapaF/resultados/F1_comparacion.csv`). Probado en Octave el 2026-11-06: diferencia
relativa máxima de 2,3e-10 en las 10 señales, que es el límite que impone el CSV de 10 cifras.
O sea que el banco en MATLAB reproduce el de Simulink.

**Diferencia con el banco de Simulink que pide la Etapa G:** el lazo lo maneja un script de
MATLAB y no un modelo con bloques en modo PIL. Se justifica porque el PIL de Simulink no está
disponible para la ESP32 (ver arriba), y lo cubre el control de coherencia.

## Qué correr (MATLAB, ESP32 conectada en /dev/ttyUSB0, puerto libre)

```matlab
cd etapaG
G3_preparar_PIL_ESP32_BoP      % genera el código, lo compara con el de la Etapa E, compila y graba la ESP32
G4_PIL_controlador_ESP32_BoP   % controlador solo: ensayos D1 y D2 (con saturación), ESP32 vs MIL
G5_PIL_lazo_cerrado_ESP32_BoP  % banco en lazo cerrado: ramas Normal y PIL
```

G3 necesita `Controller_BoP_ESP32.slx`, que crea G0 (G0 crea la copia aunque después falle el
PIL de Simulink). Si al grabar se queda en "Connecting…", mantengan apretado **BOOT**.

Criterio de G4 y G5: max\|PIL − Normal\| ≤ 1e-12 en th_cmd e I, y 0 diferencias en saturado.
También se reporta el tiempo de `_step` en la ESP32.

## Resultados

| Prueba | Criterio | Resultado |
|---|---|---|
| G4 D1 y D2 (controlador solo) | ≤ 1e-12; 0 en saturado | pendiente |
| G5 lazo cerrado | ≤ 1e-12; 0 en saturado | pendiente |
