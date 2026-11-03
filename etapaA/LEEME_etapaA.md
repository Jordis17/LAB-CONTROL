# Etapa A — Modelo de la planta (Ball on Plate)

## 1. Cómo correrlo (computadora con MATLAB)

```matlab
cd etapaA                 % carpeta actual = etapaA
A1_modelo_no_lineal_BoP   % segundos
A2_linealizar_BoP         % del orden de 1 a 2 minutos (simula unas 30 corridas)
```

No requieren ningún toolbox. Si está Control System Toolbox, A2 además imprime los modelos
`tf`, convierte el discreto con `c2d` y compara sus polos con los de `bop_discretizar`.

**Qué devolver:** la carpeta `etapaA/resultados/` completa (`A1_consola.txt`, `A2_consola.txt`,
los `.csv` y los `.mat`) y la salida de `ver`. Las consolas se guardan solas con `diary`.

Todos los parámetros están en `A0_parametros_BoP.m`. Si cambia una medición, se cambia ahí y se
corren de nuevo A1 y A2.

## 2. Modelo físico

### 2.1 Convenciones

- Marco fijo con origen en el **centro de la junta universal** y z hacia arriba.
- θx > 0 levanta el lado +X del plato y θy > 0 levanta el lado +Y. Rotación del plato:
  R = Rx(θy)·Ry(−θx). Es decir, el eje exterior de la cruceta queda fijo a la base sobre X. El
  orden de las rotaciones solo afecta a términos de segundo orden; el lineal no cambia.
- (x, y) es la posición del centro de la bola **en el marco del plato**, que es donde se aplica la
  restricción |x|, |y| ≤ 127 mm. El centro de la bola está a h = h_sup + r_b sobre la junta,
  medido sobre la normal del plato.
- Unidades internas: mm, s, rad.

### 2.2 Hipótesis

1. La bola rueda sin deslizar y no gira respecto del plato alrededor de la normal.
2. La bola es rígida y J = k·m·r_b². Se define c = 1/(1+k), con 5/7 como valor nominal. La masa
   se cancela.
3. Plato rígido, sin holgura en la junta ni en las rótulas.
4. Sin fricción de rodadura. Si los datos de la Etapa B muestran un residuo que la necesita, se
   agrega ahí.
5. El modelo de la bola toma como entrada la inclinación del plato, y el actuador se modela
   aparte (sección 2.5).
6. La cámara está fija al suelo sobre el eje de la junta. La homografía se calibró con el plato
   horizontal y no se mueve con él.

### 2.3 Ecuaciones no lineales (Lagrange, `funciones/bop_aceleracion.m`)

```
ẍ = c·[ −g·sin θx·cos θy + x·θ̇x² + x·θ̇y²·sin²θx + ½·h·θ̇y²·sin 2θx
        − 2·θ̇y·ẏ·sin θx − y·θ̈y·sin θx + (h + k·r_b)·θ̈x ]

ÿ = c·[ −g·sin θy + y·θ̇y² + 2·x·θ̇x·θ̇y·cos θx − (k·r_b + 2h)·θ̇x·θ̇y·sin θx
        + 2·θ̇y·ẋ·sin θx + ((k·r_b + h)·cos θx + x·sin θx)·θ̈y ]
```

La derivación se hizo de forma simbólica: la restricción de rodadura se verifica exactamente y la
transcripción a MATLAB coincide con la expresión simbólica en puntos aleatorios. Con θy = 0 se
reduce a la ecuación conocida de un eje, (1+k)·ẍ = −g·sin θ + x·θ̇² + (h + k·r_b)·θ̈.

**Qué es no lineal y por qué:**

| Término | Origen | Importancia (ver resultados) |
|---|---|---|
| sin θ | La componente de la gravedad sobre el plato | Pequeña: (θ − sin θ)/θ ≈ θ²/6, alrededor de 1 % a 14° |
| x·θ̇² | Fuerza centrífuga por la rotación del plato | **La dominante**; crece con la distancia al centro y con el cuadrado de la velocidad del plato |
| Términos con θ̇x·θ̇y, θ̇y·ẏ, θ̈y·sin θx | Coriolis y acople entre ejes | Solo aparecen si se mueven los dos ejes a la vez |
| Medición de la cámara | Proyección del centro de la bola, con el plato inclinado, sobre el plano de calibración | Hasta unos 14 mm en el borde a 14° |
| Mecanismo servo–plato | Cuatro barras en cada eje y acople 3D a través de la junta | Desviación de la recta de 1,7° en ±45° de servo |
| Saturación y velocidad del servo | ±45° y unos 600°/s a 4,8 V | Límite duro; entra en el MIL |

### 2.4 Medición (`funciones/bop_medicion.m`)

Centro de la bola en el marco fijo: p = R·(x, y, h). La cámara ve el rayo que pasa por p y lo
intersecta con el plano de calibración z = h_sup. Después aplica el factor de paralaje de
`config.py`. Con el plato horizontal da exactamente (x, y). Linealizado queda **Xm = x − h·θx**:
con el plato inclinado, la cámara no mide la coordenada sobre el plato.

### 2.5 Actuador (`bop_cinematica_inversa.m`, `bop_cinematica_directa.m`)

Cada servo mueve un brazo de largo r en su plano vertical. Una varilla de largo L une la punta del
brazo con la rótula, que está a (d, 0, z_rot) en el marco del plato. Con las cotas de diseño se
cumple L = z_rot + H_serv, así que el neutro tiene el plato horizontal, el brazo horizontal y la
varilla vertical. La cinemática inversa tiene forma cerrada, y la directa se resuelve con Newton.

### 2.6 Modelo lineal (`funciones/bop_modelo_lineal.m`)

Se linealiza alrededor de x = y = 0, ẋ = ẏ = 0, θ = 0 y θ̇ = 0. Los ejes quedan desacoplados: el
jacobiano no tiene términos cruzados. Por eje:

```
ẍ = c·(−g·θ + h_ef·θ̈),   h_ef = h + k·r_b

X(s)/Θ(s)  = (c·h_ef·s² − c·g) / s²                   posición sobre el plato
Xm(s)/Θ(s) = (−(1−c)·h_sup·s² − c·g) / s²             posición medida por la cámara
```

En espacio de estados, con ξ = x − c·h_ef·θ (cambio de variable para no derivar la entrada):

```
d/dt [ξ; ξ̇] = [0 1; 0 0]·[ξ; ξ̇] + [0; −c·g]·θ
x  = ξ + c·h_ef·θ
Xm = ξ − (1−c)·h_sup·θ
```

Consecuencias (CLAUDE.md, sección 3.3), que salen del modelo y no de suponerlas:

- **Doble polo en s = 0.** La planta no es estable en lazo abierto. Un escalón de inclinación lleva
  la bola a la pared en aproximadamente √(2·127/(c·g·sin θ)) segundos, que es 1,0 s con 2°. No se
  puede hacer un ensayo escalón en lazo abierto.
- **SIMC no aplica** porque no es FOPDT. **Un PI no la estabiliza**: un doble integrador necesita
  acción derivativa (o realimentación de velocidad) para tener margen de fase.
- **Ceros.** Para x: un par real ±√(g/h_ef), uno de ellos de fase no mínima. Para Xm, que es lo
  que se realimenta: un par imaginario ±j·√(c·g/((1−c)·h_sup)). Los dos dependen de la altura de
  la junta, **h_sup, que es PROVISIONAL**. Si la cara del plato estuviera en el centro de la
  junta (h_sup = 0), Xm/Θ sería un doble integrador puro.
- **Discretización** (`bop_discretizar.m`): ZOH exacta con el retardo fraccionario (Åström),
  verificada contra una simulación continua con un error de 1e-9.

## 3. Cómo se cuantifica el error de la aproximación lineal

La planta no tiene equilibrio estable, así que no se puede comparar con escalones. Se usa un
**triplete** de inclinación (+A durante T, −A durante 2T, +A durante T). En el modelo lineal deja
la bola en reposo en el punto de partida, y T se elige para que la bola llegue al 60 % de x_max.

Cada cambio de ángulo es un coseno alzado de duración tr, en dos variantes:

- **rápida:** el plato a la velocidad máxima del servo (unos 206°/s de plato a 4,8 V);
- **lenta:** tr = 0,8·T.

Se reportan dos tipos de métrica:

1. **Error de trayectoria** (lineal − no lineal; máximo, RMSE, sesgo y porcentaje de max|x|)
   sobre todo el triplete más 0,5 s. Es lo que pide la Etapa A. **Ojo:** en lazo abierto un
   doble integrador acumula cualquier diferencia de aceleración, así que esta métrica exagera lo
   que pasaría en lazo cerrado.
2. **Error de aceleración del modelo**, evaluado instante a instante sobre la trayectoria no
   lineal y separado en seno, centrífugo y resto. Se expresa como inclinación equivalente,
   θ_eq = error/(c·g). No se acumula y es lo que el controlador "ve" como perturbación.

Hay además un caso con los dos ejes moviéndose a la vez, para medir el acople, y un barrido de
amplitud de 0,5° a 13°.

**Decisión de ingeniería (no la fija ningún documento):** el umbral de validez es un error de
trayectoria menor al 5 % de max|x|. Se puede cambiar en `A2_linealizar_BoP.m` (`umbral_rel`).

## 4. Resultados preliminares (Octave 8.4, no MATLAB)

Los scripts se probaron en **GNU Octave 8.4** dentro de la sesión de Claude Code, para revisar
la sintaxis y la coherencia. Los números de abajo salen de esa corrida y **quedan como
preliminares hasta que el equipo corra los scripts en MATLAB**.

- Mecanismo: pendiente de 0,343 °/° en el neutro; ±45° de servo dan −13,73° y +14,75° de plato
  (asimétrico), así que la inclinación simétrica alcanzable es ±13,7°. Si el firmware resuelve
  cada eje por separado, en vez de la cinemática 3D, el error llega a 0,65° en una rejilla de
  ±12°.
- Modelo lineal con los valores nominales: c·g = 7007 mm/(s²·rad) (122,3 mm/s² por grado),
  c·h_ef = 55,0 mm/rad, c·h_ef − h = −14,0 mm/rad. Ceros de X/Θ en ±11,3 rad/s y de Xm/Θ en
  ±j22,4 rad/s. El jacobiano numérico coincide con el analítico (diferencia relativa del orden de 1e-13) y no tiene
  términos cruzados.
- **El término dominante es el centrífugo x·θ̇²**, no el seno. Con transiciones lentas, el error
  de trayectoria crece aproximadamente con A²: 0,1 % (0,5°), 0,5 % (1°), 2,0 % (2°), 4,7 % (3°),
  8,6 % (4°). Con transiciones a la velocidad máxima del servo, el error ya es del 11 % con 1°.
  El seno por sí solo equivale a 0,11° de error de inclinación a 13°.
- Tabla de la inclinación equivalente del término centrífugo: con la bola en el borde y el plato
  a máxima velocidad equivale a unos 9,6°. **Implicación para la Etapa C:** limitar la velocidad
  de inclinación que pide el controlador (filtrar la derivada, no saturar el servo de golpe) hace
  que el modelo lineal sea válido en un rango mucho mayor.

## 5. Datos que cambian estos resultados

| Dato | Qué cambia | Estado |
|---|---|---|
| h_sup (altura de la cara superior del plato sobre el centro de la junta) | Ceros del modelo, error de la cámara | PROVISIONAL, 49 mm de cotas de diseño |
| Tabla de comando del servo vs. ángulo medido del plato | Pendiente y rango del actuador | Pendiente de medir |
| σ (lado del brazo), r_brazo | Asimetría y rango | PROVISIONAL |
| Tensión de los servos | Velocidad máxima del plato y peso del término centrífugo | PENDIENTE |
| c (coeficiente de rodadura) | Ganancia c·g | Se identifica en la Etapa B |
| Ts y retardo | Modelo discreto | Pendiente de medir con `run_benchmark.py` |
