# Etapa C — Diseño del controlador

## 1. Cómo correrlo

```matlab
cd etapaC
C1_disenar_controlador_BoP     % ~1 minuto; usa etapaA/ y etapaD/funciones
```

No requiere toolboxes. Genera `resultados/C1_controlador.mat` (variables `Ctrl` y `Rq`), que es
la entrada de la Etapa D y la referencia para la Etapa E. Hay que devolver la carpeta
`etapaC/resultados/` completa.

## 2. Requisitos (`C0_requisitos_BoP.m`)

No hay enunciado del curso. Los requisitos los propuso la IA y los aceptó el equipo
(2026-11-03), así que son **decisiones de ingeniería, no requisitos del curso**.

| Id | Requisito | Ensayo |
|---|---|---|
| R1 | ts ≤ 3 s | Bola quieta a 100 mm en un eje, referencia 0 |
| R2 | Mp ≤ 20 % | Ídem |
| R3 | ess ≤ 3 mm | Ídem |
| R4 | \|x\| ≤ 127 mm siempre (marco del plato) | Todos |
| Diseño | PM ≥ 40°, GM ≥ 6 dB | Lazo lineal discreto |

**Definiciones únicas** (CLAUDE.md, sección 9). Se calculan sobre la posición filtrada por el
Kalman (x̂) en los instantes de cuadro, que es lo que registra `main_vision.py`. Así la misma
definición sirve para la simulación y para el experimento.

- x0 = promedio de x̂ en los 0,3 s antes de habilitar el controlador.
- tr = tiempo entre el 10 % y el 90 % del cambio.
- ts = último instante con \|x̂ − r\| mayor que el 5 % del cambio.
- Mp = máximo sobrepaso en el sentido del cambio, en porcentaje del cambio.
- ess = \|media(x̂ − r)\| en el último segundo.

## 3. Por qué esta estructura

Datos de la Etapa A: por eje, la planta es un **doble integrador** con transmisión directa y
ceros en ±j22 rad/s, con unos 75 ms de retardo (estimado) y Ts = 33 ms.

- **SIMC no aplica:** la planta no es FOPDT estable (CLAUDE.md, sección 3.3).
- **Un PI no estabiliza un doble integrador.** Hace falta acción derivativa. Se toma la
  velocidad **v̂ del Kalman** del pipeline, que ya la calcula, en vez de derivar la posición:
  así no se agrega otro filtro ni más atraso.
- **Hace falta acción integral** para corregir sesgos: desnivel del plato, neutro del servo,
  bola desbalanceada. Un PD deja un error de desnivel/Kp ≈ 29 mm por cada grado.
- **El PID clásico no sirve en esta planta.** Al arrancar con la bola lejos de la referencia, el
  integral se carga durante todo el recorrido y da un sobreimpulso de ~38 % (sección 8 de C1).
  Se probaron varias alternativas (sección 6 de este documento) y quedó la **integración
  condicional**: el integrador solo trabaja después de 4 cuadros seguidos con la bola casi
  quieta (\|v̂\| < 25 mm/s). Es cuando el error que queda es un sesgo y no un transitorio.

## 4. Método de sintonización

**Kp y Kd por asignación de polos.** El modelo de diseño es −c·g / (s²·(te·s + 1)), donde el
retardo del lazo se representa como un atraso equivalente:

```
te = retardo + Ts/2 + 2/ωn_servo = 0,075 + 0,0167 + 0,040 = 0,1317 s
```

El polinomio característico te·s³ + s² + c·g·Kd·s + c·g·Kp se iguala a
te·(s + a·ω)(s² + 2ζω·s + ω²), con ζ = 0,7 y a = 1. El coeficiente de s² fija
ω = 1/(te·(a + 2ζ)): **el retardo limita la velocidad del lazo**, no es un parámetro libre.

**Integral:** Ti = 1,5 s. El error que entra al integrador se recorta a ±30 mm.

**Saturación:** θ_lim = 12°. El mecanismo alcanza ±13,4° (A1); se deja margen por la
asimetría y las holguras.

**Kalman:** la velocidad del filtro entra al lazo, así que su sintonía es parte del diseño. Con
`PROCESS_ACCEL_STD = 1500` (el valor actual de `config.py`), la velocidad sale tan ruidosa que
el plato tiembla 0,67° (std) en reposo. Con **500** baja a 0,31°, a cambio de unos 4° de margen
de fase. → **Pendiente: cambiar `PROCESS_ACCEL_STD` a 500 en `config.py`** y repetir la tabla
cuando se mida el ruido real.

## 5. Resultados preliminares (Octave 8.4; ver `verificacion_octave/C1_consola.txt`)

| Magnitud | Valor |
|---|---|
| Kp | 0,03412 °/mm (5,95e-4 rad/mm) |
| Kd | 0,02588 °/(mm/s) (4,52e-4 rad/(mm/s)) |
| Ki | 0,02275 °/(mm·s) (3,97e-4 rad/(mm·s)); por muestra Ki·Ts = 7,58e-4 °/mm |
| C(s) parte lineal | (4,52e-4 s² + 5,95e-4 s + 3,97e-4)/s [rad/mm] |
| Kalman (σa = 500, σm = 1) | K = [0,647; 9,90 s⁻¹] |
| ωc | 3,30 rad/s (0,52 Hz) |
| PM | 40,9° |
| GM superior / inferior | +11,8 dB / −12,6 dB (planta condicionalmente estable) |
| Margen de retardo | 216 ms adicionales |
| PM con retardo de 120 ms | 32,3° (no cumple el criterio de 40°) |

Ley discreta por eje, en cada cuadro:

```
eps    = x̂ − r
u      = Kp·eps + I + Kd·v̂
θ_cmd  = sat(u, ±12°)
nq     = (|v̂| < 25 mm/s) ? nq + 1 : 0
I      ← I + Ki·Ts·sat(eps, ±30 mm)   si nq ≥ 4 y no (saturado y sign(eps) = sign(u))
```

## 6. Alternativas descartadas (exploración en Octave, en esta sesión)

| Variante | Problema |
|---|---|
| PID completo por asignación de polos (4 polos) | Mp de 30 a 43 % |
| PD + integral del error recortado (sin condición) | Corrección del desnivel muy lenta (6 a 22 mm de error a los 10 s) o sobreimpulso |
| Integral solo con \|v̂\| < 15 mm/s (1 cuadro) | Se carga durante el arranque del ensayo: Mp ~5–6 %, justo en el borde de la banda de 5 %, así que ts salta entre 1,3 y 3,2 s |
| Integrar ε + Td·v̂ | Sin sobreimpulso, pero el desnivel tarda 8,6 s en corregirse |
| Exigir 0,3 s quieta con 15 mm/s | El ruido de v̂ rompe la cuenta: el integrador casi nunca actúa |
| Más amortiguamiento (ζ = 0,8–0,9) o a = 1,5–2 | Más sobreimpulso, no menos: la bola llega más lento y el integral se carga más |
