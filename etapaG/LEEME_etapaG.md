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

## Modelo para PIL

`Controller_BoP_ESP32.slx` es una **copia** de `etapaE/Controller_BoP.slx` (que no se toca) en
la que **solo cambia la placa** (*Hardware board* = ESP32), necesaria para compilar con el
compilador de la ESP32. El algoritmo y los parámetros son los mismos (`bop_ley_control`,
`init_Controller_BoP`). La comparación de G0 y G2 contra el original lo confirma.

## Qué correr (MATLAB, con la ESP32 conectada por USB a esta PC)

Antes: cierren todo lo que use el puerto de la ESP32 (`main_vision.py`, `miniterm`, Monitor
Serie del IDE) y revisen que aparezca:

```bash
ls /dev/ttyUSB*
```

```matlab
cd etapaG
G0_prueba_PIL_minima_BoP      % 1) prueba mínima: el controlador solo, en la ESP32
G1_build_Test_PIL_BoP         % 2) construye el banco Normal vs PIL (solo si G0 dio PASS)
G2_comparar_Normal_PIL_BoP    % 3) simula en lazo cerrado y compara
```

- **G0** responde si la ESP32 acepta PIL. Pasa las entradas de dos ensayos del MIL (uno con 9
  cuadros saturados) por el controlador en la ESP32 y compara con el MIL. La primera vez
  compila y graba la ESP32 (tarda unos minutos).
- **G1** construye `BoP_Test_PIL.slx`, igual al banco SIL (misma planta y ensayo) pero con la
  rama PIL. Es un banco separado del de SIL. Si Simulink no admite dos instancias PIL a la vez,
  pongan `ejes_pil = {'X'}` al principio de G1 (el eje Y de esa rama queda en modo Normal).
- **G2** simula y compara muestra a muestra. Criterio: max\|PIL − Normal\| ≤ 1e-12 en th_cmd e I
  y 0 diferencias en saturado.

## Errores probables la primera vez

| Error | Qué hacer |
|---|---|
| G0 no reconoce la placa | Abrir `Controller_BoP_ESP32.slx` → *Modeling* → *Model Settings* → *Hardware Implementation* → *Hardware board* y mandarme los nombres que aparecen |
| `Connectivity configuration "Arduino Board" threw an error … Index exceeds array bounds` y `Target is underspecified` (2026-11-06) | El paquete no detectó solo la ESP32 y la configuración PIL quedó sin puerto. G0 ahora fija `puerto = '/dev/ttyUSB0'` en el modelo (`funciones/g_puerto_arduino.m`) e imprime la configuración del paquete |
| No puede abrir el puerto serie | Cerrar los otros programas que lo usan; el usuario tiene que estar en el grupo `dialout` |
| Falla al grabar la ESP32 | Mantener **BOOT** apretado cuando diga "Connecting…" |
| PIL no soportado para la placa | Mandar el mensaje completo: hay que definir otra ruta antes de seguir (CLAUDE.md, sección 0) |

Si algo falla, mándenme el mensaje completo. No usen botones de **"Fix"**.

## Resultados

| Prueba | Criterio | Resultado |
|---|---|---|
| G0 D1 y D2 (controlador solo) | ≤ 1e-12; 0 en saturado | pendiente |
| G2 lazo cerrado | ≤ 1e-12; 0 en saturado | pendiente |
