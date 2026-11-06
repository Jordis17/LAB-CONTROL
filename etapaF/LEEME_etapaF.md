# Etapa F — SIL (Software-in-the-loop)

## Qué verifica

Que el **código C generado** de `Controller_BoP` (Etapa E), compilado y ejecutado en la PC,
calcule lo mismo que el **modelo** en simulación normal, **dentro del lazo cerrado**. El
criterio es la equivalencia numérica muestra a muestra. Que el código compile no demuestra nada
(CLAUDE.md, Etapa F).

**Qué NO verifica:** que el código funcione en la ESP32 (eso es PIL, Etapa G) ni que el
controlador funcione con la planta real (Etapa H).

## El banco `BoP_Test_SIL.slx` (lo construye `F0_build_Test_SIL_BoP.m`)

```
                ┌─> Ctrl_X_Normal (modo Normal) ─> UD ─┐
 r_x, r_y, hab ─┤                                       ├─> Planta_Normal ─> (x_hat, v_hat, x)
                └─> Ctrl_Y_Normal (modo Normal) ─> UD ─┘
                ┌─> Ctrl_X_SIL (modo SIL) ───────> UD ─┐
 (mismas)      ─┤                                       ├─> Planta_SIL ────> (x_hat, v_hat, x)
                └─> Ctrl_Y_SIL (modo SIL) ───────> UD ─┘
```

- **Compartido por las dos ramas:** referencia (0 y a los 4,5 s 50 mm en cada eje),
  habilitación (desde los 0,5 s), condición inicial (bola en 80, −60 mm), Ts = 1/30 s,
  tiempo de 9 s y ruido (la misma secuencia).
- **Propio de cada rama:** su planta (bloque MATLAB Function con
  `funciones/planta_bop_paso.m`) y sus dos instancias del controlador, una por eje. El
  `Controller_BoP` es una *Reusable function*, así que tiene un estado por instancia.
- **Planta del banco:** bola no lineal de dos ejes (Etapa A), servo de 2.º orden sobre el
  ángulo del plato con límites, medición de la cámara con la inclinación, ruido de 1 mm,
  retardo de un cuadro y Kalman igual al del pipeline. Es más simple que la del MIL (no tiene la
  tabla servo–plato ni el PWM), y alcanza para SIL, porque lo que se compara es el controlador
  con **la misma** planta en las dos ramas.
- Un **Unit Delay** entre el controlador y la planta representa el cuadro de cálculo y
  actuación, y rompe el lazo algebraico.
- `Controller_BoP.slx` **no se modifica**: el banco solo lo referencia.

Los parámetros de la planta del banco se escriben solos en `funciones/planta_bop_param.m` a
partir de las Etapas A y C, sin números copiados a mano.

**Prueba previa (Octave, 2026-11-06):** `planta_bop_paso` en lazo cerrado con
`bop_ley_control`, mismo ensayo. La bola llega de (80, −60) a (−2, 1,5) mm a los 4,4 s y a
(50, 51) mm a los 9 s, con inclinaciones de hasta 3°. El modo SIL solo se puede probar en
MATLAB.

## Qué correr (MATLAB, desde `etapaF`)

```matlab
cd etapaF
F0_build_Test_SIL_BoP          % construye BoP_Test_SIL.slx
F1_comparar_Normal_SIL_BoP     % simula (compila el código SIL la primera vez) y compara
```

Debe terminar con `Criterio (...): PASS`. Hay que devolver `etapaF/resultados/` y
`BoP_Test_SIL.slx`.

**Si da error, mándenme el mensaje completo.** Los puntos más probables de falla la primera
vez son tres:
- escribir el código del bloque de la planta (igual que E0);
- el modo SIL de los bloques Model, si el nombre del modo cambió en R2026a;
- la compilación del código SIL (necesita gcc, que ya está configurado).

## Resultados

| Señal | Criterio | Resultado |
|---|---|---|
| th_cmd X/Y, I X/Y | max\|SIL − Normal\| ≤ 1e-12 | pendiente |
| saturado X/Y | 0 diferencias | pendiente |
| x_hat, x (planta) | Se reportan (son consecuencia) | pendiente |
