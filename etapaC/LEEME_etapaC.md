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

**Saturación:** θ_lim = **10°** (actualizado el 2026-11-04). Con la relación servo → plato
medida, el peor eje (Y) alcanza ±11,3° con ±40° de comando; se deja ~1,3° de margen. Antes
de la medición era 12°, con el ±13,4° del diseño. Kp, Ki, Kd, el Kalman y los márgenes no
cambian, porque el firmware compensa la ganancia del mecanismo con la tabla medida.

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

---

## 7. Segunda estrategia: LQR con acción integral (`C2_disenar_LQR_BoP.m`, 2026-11-25)

El enunciado del proyecto final (`Intrucciones.txt`) pide **dos estrategias de control
distintas, validadas hasta MIL**, y llevar una de ellas hasta la implementación. La primera es
el PID de las secciones anteriores. La segunda es una **realimentación de estados óptima (LQR)
con integrador del error (LQI)**.

### Por qué esta y no otra
- La planta por eje es un doble integrador con retardo. El Kalman del pipeline ya entrega los
  dos estados (x̂, v̂), así que no hacen falta sensores nuevos.
- El retardo se modela con estados: las d inclinaciones ya mandadas, que el controlador conoce.
  Con eso el LQR funciona como un **predictor**: sabe qué inclinaciones todavía no le llegaron a
  la bola. El PID no compensa el retardo de forma explícita.
- La sintonía minimiza un costo cuadrático con pesos Q y R. Es un método distinto de la
  asignación de polos del PID.
- Se descartaron MPC (necesita optimización en línea en la ESP32 y más tiempo de ajuste) y
  sliding mode (la conmutación pelea con la zona muerta del mecanismo).

### Modelo de diseño (`funciones/bop_modelo_lqr.m`)
- Planta: ẍ = −c·g·θ, igual que para el PID, sin los ceros.
- Retardo de entrada: τ_d = retardo + 2/ω_n = 0,115 s, con el atraso del servo.
- Discretización: ZOH exacta con retardo fraccionario a Ts = 33,3 ms, con d = 4 entradas pasadas.
- Estado aumentado (7): `[e, v, u[k−4], u[k−3], u[k−2], u[k−1], z]`, con e = x − r y
  z = ∫e.

### Pesos (regla de Bryson)
- Pesos: Q = diag(1/e_max², 1/v_max², 0, 0, 0, 0, q_z) y R = 1/θ_max².
- **Elegidos:** e_max = 100 mm, v_max = 300 mm/s, θ_max = 5°, q_z = 1e-4, y el error que entra
  al integrador recortado a **±5 mm**.

Cómo se llegó (Octave, 2026-11-25):

| Juego | Margen | MIL, ensayo de requisitos | Desnivel de 1° |
|---|---|---|---|
| q_z = 1e-5, v_max 100, θ_max 3° (primer intento) | PM 52,7° | Mp 19 %, no se establece en 6 s | ess 5,4 mm |
| q_z = 1e-4, v_max 200, recorte 10 mm | PM 42,6° | ts 3,20 s (no cumple R1), Mp 7,7 % | — |
| q_z = 1e-4, v_max 200, recorte 5 mm | PM 42,6° | ts 2,97 s, Mp 6,1 % | ess 1,45 mm |
| q_z = 1e-4, v_max 200, recorte 2–3 mm | PM 42,6° | ts 1,2–2,8 s | ess 7–12 mm (integral demasiado lenta) |
| q_z = 2e-4 o 3e-4, recorte 3–4 mm | PM 38–40° (bajo el criterio) | ts ≈ 0,9 s | ess < 1 mm |
| **q_z = 1e-4, v_max 300, recorte 5 mm (elegido)** | **PM 41,1°** | **ts 2,03 s, Mp 5,2 %, ess 0,15 mm** | **ess 1,23 mm** |

- La sección 2 de C2 recorre la grilla de márgenes.
- La sección 3b compara juegos con una simulación lineal rápida.
- El MIL completo con el juego elegido está en `etapaD/D2_MIL_LQR_BoP.m`.

### Ley discreta (`funciones/bop_ley_lqr.m`)
```
e      = x̂ − r
u      = −( Ke·e + Kv·v̂ + Σ Ku_i·θ_cmd[k−i] + Kz·z )
θ_cmd  = sat(u, ±10°)
z      ← z + Ts·sat(e, ±5 mm)    salvo saturado y el integrador empujando hacia la saturación
```

### Resultados preliminares (Octave 8.4, `verificacion_octave/C2_consola.txt`; falta MATLAB)

| Magnitud | LQR | PID (C1) |
|---|---|---|
| Ganancia de posición | Ke = 0,0812 °/mm | Kp = 0,0341 °/mm |
| Ganancia de velocidad | Kv = 0,0471 °/(mm/s) | Kd = 0,0259 °/(mm/s) |
| Integral | Kz = 0,0461 °/(mm·s), error recortado a ±5 mm | Ki = 0,0227 °/(mm·s), condicional, error recortado a ±30 mm |
| Predictor (u[k−4] … u[k−1]) | 0,085 · 0,182 · 0,171 · 0,160 | — |
| ωc / PM | 3,94 rad/s / 41,1° | 3,30 rad/s / 40,9° |
| GM superior / inferior | +12,4 / −15,2 dB | +11,8 / −12,6 dB |
| Margen de retardo | 182 ms | 216 ms |
| Retardo de 120 ms | PM 30,9° | PM 32,3° |
| Modelo identificado X (c 0,18; 0,27 s) | inestable (PM −3,1°) | inestable (PM −9,5°, integral lineal) |
| Modelo identificado Y (c 0,28; 0,27 s) | PM 6,3° | PM 5,3° |

**Cómo correrlo:** `cd etapaC`, `C2_disenar_LQR_BoP` (después de C1). Genera
`resultados/C2_controlador_LQR.mat`, `C2_grilla.csv`, `C2_bode.csv`, `C2_robustez.csv` y
`C2_consola.txt`.
