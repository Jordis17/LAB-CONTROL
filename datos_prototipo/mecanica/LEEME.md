# Mediciones mecánicas del prototipo

## `servo_plato_2026-11-04.csv`

Tabla que mandó el equipo el 2026-11-04 (captura de una hoja de cálculo).

- `comando_deg`: comando del sketch `prueba_servos.ino` (`X <g>` o `Y <g>`), en grados respecto
  del neutro (1500 µs; 11,1 µs por grado).
- `th_plato_X_deg`: inclinación del plato al mover el servo X. `th_plato_Y_deg`: lo mismo con
  el servo Y.
- Antes de medir, los brazos se ajustaron a mano para que el plato quedara lo más horizontal
  posible en el neutro.

**Datos que faltan para interpretarla** (pedidos al equipo):

1. ~~¿Valor absoluto?~~ **Respondido (2026-11-04):** la app del celular mostraba valores
   **sin signo**. Falta saber hacia qué lado se inclinaba el plato con comandos negativos y con
   positivos.
2. ~~Instrumento~~ **Respondido:** app del celular, apoyado sobre la cara superior del plato.
3. Si se midió también la inclinación en el otro eje (acople), y desde qué lado se llegó a cada
   comando (holgura).
4. Ángulo del **brazo** del servo respecto de la horizontal con el comando `C`.
5. Tensión de la fuente de los servos.

**Primer análisis** (Claude, 2026-11-04). Es una hipótesis, todavía no es una identificación:

- La relación es **fuertemente asimétrica**. Del lado de los comandos negativos, la pendiente
  media es de 0,335 °/° en X y 0,368 °/° en Y, cerca del diseño (0,343). Del lado positivo es
  0,185 °/° en X y 0,148 °/° en Y, casi la mitad.
- Una hipótesis que reproduce la tabla de X (error RMS de 0,27°) es que, al nivelar el plato,
  **el brazo quedó unos 30° fuera de la horizontal en el neutro**. Así el mecanismo trabaja
  lejos de su punto simétrico. En Y el ajuste es peor (0,52°) y deja un desnivel de ~1,3–1,9°.
  Las otras causas posibles son que el servo no mapee el pulso simétricamente, una holgura o un
  roce de un solo lado, o la forma de medir.
- **Si se confirma:** con ±45° de servo el plato alcanza unos −15° y solo **+7,5°**. La
  inclinación simétrica útil baja de ±13,4° (diseño) a **±7,5°**. El controlador satura en
  ±12°, así que habría que bajar esa saturación o corregir el montaje.

## `servo_plato_2026-11-04_v2.csv` (vigente)

Segunda medición, del mismo día, **después de que el equipo hizo correcciones en los ejes**
(falta detallar cuáles). Ya tiene **signo**: app del celular apoyada en el centro de la cara
superior del plato, con los ejes X e Y que muestra la app. Columnas: comando del servo X con el
servo Y en neutro → inclinación X; comando del servo Y con el X en neutro → inclinación Y.

**Análisis** (Claude, 2026-11-04; script en la sesión, modelo de cuatro barras del diseño más
3 parámetros por eje):

| | X | Y |
|---|---|---|
| Pendiente cerca del neutro (comando −10 a +10) | −0,50 °/° | +0,54 °/° (diseño: 0,34) |
| Pendiente media del lado − / lado + | 0,53 / 0,34 °/° | 0,56 / 0,37 °/° |
| Rango con ±40° de comando | −12,1° a +22,4° | −25,9° a +11,3° |
| Rango simétrico respecto de la horizontal | ±12,1° | ±11,3° |
| Desnivel en el neutro (`C`) | +1,3° | −3,5° |
| Ajuste: k (grados de servo por grado de comando), φ0 (brazo en el neutro), RMS | 1,66; 17°; 0,89° | 1,75; 12°; 0,87° |
| Comando que nivela el plato según el ajuste | +2,9° (≈ +33 µs) | +6,9° (≈ +76 µs) |

Lectura:
- El plato se mueve **~1,5 veces más por grado de comando** que en el diseño. Encaja con un
  servo que gira más de 1° por cada 11,1 µs. Por ejemplo, una versión de 180°:
  `componentes.xlsx` dice "MG90S (180º)". También encaja con un brazo efectivo más largo. Para
  separar las dos causas hay que medir **cuánto gira el brazo** con ±40.
- **Sigue siendo asimétrico** (un lado ~0,55 °/°, el otro ~0,35 °/°). El ajuste lo atribuye a
  que el brazo queda unos 12–17° fuera de la horizontal en el neutro. El error de 0,9° sugiere
  que hay algo más: holgura, o la resolución de la app.
- El rango simétrico útil (±11–12°) se parece al del diseño, pero θ_lim = 12° queda en el
  límite del eje Y. Se recomienda θ_lim ≈ 10° y una cinemática inversa por tabla medida.
- El desnivel de −3,5° en Y es grande: un PD solo dejaría unos 100 mm de error. Se corrige por
  software, con el pulso de neutro de cada eje.

## Sentido de giro (confirmado por el equipo, 2026-11-04)

- `X 20` → el lado del **servo X (+X) baja**. `Y 20` → el lado del **servo Y (+Y) baja**.
  Los dos servos responden igual: **un comando positivo baja su lado del plato**.
- En la convención del modelo (θx > 0 levanta el lado +X, θy > 0 levanta el lado +Y):
  **θx = lectura X de la app** y **θy = −(lectura Y de la app)**.
- `servo_plato_v2_convencion_plato.csv` es la tabla v2 en esa convención: comando del servo
  (grados del sketch) → θx y θy del plato. En los dos ejes, los comandos negativos levantan el
  lado con pendiente ~0,55 °/° y los positivos lo bajan con ~0,35 °/°.
- Desnivel en el neutro, en convención del plato: θx = +1,3° y θy = +3,5° (los lados +X y +Y
  quedan altos). Para nivelar hay que bajarlos, o sea, comandos positivos: unos +3° en X y +7°
  en Y según el ajuste (≈ +33 µs y +76 µs).
- **Para el firmware:** comando_servo = −g⁻¹(θ_cmd), donde g es la relación medida. El signo
  negativo viene de que un pulso mayor baja el lado.
