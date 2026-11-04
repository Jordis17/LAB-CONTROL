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

1. Todos los valores son positivos. ¿El instrumento mostraba el **valor absoluto**? ¿Hacia qué
   lado se inclinaba el plato con comandos negativos y con positivos?
2. Instrumento de medida (app del celular u otro) y dónde se apoyó sobre el plato.
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
