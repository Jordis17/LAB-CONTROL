# Etapa D — MIL (Model-in-the-Loop)

## 1. Cómo correrlo

```matlab
cd etapaC, C1_disenar_controlador_BoP   % primero (genera C1_controlador.mat)
cd ../etapaD, D1_MIL_BoP                % ~1 a 3 minutos
```

Hay que devolver la carpeta `etapaD/resultados/`. El orden de columnas de los CSV está en
`orden_csv.md`.

## 2. Qué se simula (`funciones/bop_mil_simular.m`)

```
bola no lineal 2 ejes (Etapa A, RK4, dt = Ts/33)
  → cámara: Xm en t_k = k·Ts (proyección de bop_medicion) + ruido σ = 1 mm
  → llega a la ESP32 en t_k + (retardo − T_pwm/2)
  → Kalman por eje (igual a kalman.py, σa = 500)
  → controlador (bop_controlador_paso)
  → cinemática inversa por eje
  → el servo recibe el objetivo en el siguiente flanco del PWM de 20 ms
  → servo de 2.º orden (ωn = 50 rad/s, SUPUESTO), 600°/s, ±45°
  → cinemática directa → plato (+ desnivel)
```

El controlador se habilita en t = 0,5 s con la bola quieta, que es como arrancaría el ensayo
real. **Simplificaciones:** el acople 3D del mecanismo (< 0,63°) no está modelado, la
exposición es instantánea y la ESP32 calcula en tiempo cero.

Todos los casos comparten la planta, Ts, el retardo, el ruido (con la misma semilla), el
integrador numérico y la duración, salvo lo que cada caso cambia a propósito.

## 3. Resultados con el actuador medido (vigentes; Octave 8.4, `verificacion_octave/D1_consola.txt`)

Desde el 2026-11-04 el MIL usa la **relación servo → plato medida** en el prototipo
(`bop_actuador.m`, tipo `'medido'`): la tabla de `datos_prototipo/mecanica/` interpolada, con
la asimetría y el neutro que nivela el plato. El firmware simulado invierte esa misma tabla.
La saturación del controlador bajó a **θ_lim = 10°**, porque el peor eje alcanza ±11,3°.

| Caso | Resultado |
|---|---|
| D1 requisitos (100 mm → 0) | ts 1,30 s, Mp 4,5 %, ess 0,16 mm, max\|x\| 102,4 mm: **cumple R1–R4** |
| D2 empujón de 420 mm/s + 1° de desnivel | Satura 0,33 s y la bola **llega a 132,7 mm (pasa el borde de 127 mm)**. Con θ_lim = 12° llegaba a 126,3 mm. Con integración condicional, con y sin AW dan igual; con un PID clásico, el AW baja el ess de 3,71 a 3,11 mm |
| D3 desnivel de 1° | max 31,3 mm; vuelve a < 3 mm a los 5,2 s; ess 0,89 mm |
| D4 dos ejes | Igual que antes: ts de 3,0 a 4,0 s en los tramos de 50–60 mm (efecto de la banda relativa del 5 %) |
| D5 robustez | Cumple en todos los casos menos con retardo de 120 ms (ts 3,9 s), ruido de 2 mm (ts 3,9 s) y **firmware sin tabla** (ts 4,9 s, Mp 24,6 %) |
| D5 actuador del diseño | ts 1,37 s, Mp 4,4 %: el controlador no depende del actuador **si el firmware usa la tabla** |
| D6 lineal vs no lineal | D1: 1,6 mm de diferencia máxima; D2: 9,7 mm |

Lecturas:
- **El firmware tiene que usar la tabla medida.** Con una conversión lineal con la pendiente del
  diseño, el lazo ve ~1,5 veces más ganancia de un lado y un desnivel de 1,3–3,5° en el
  neutro, y el sobreimpulso pasa del 4,5 % al 24,6 %.
- **Bajar θ_lim de 12° a 10° reduce el empujón que el controlador puede frenar sin que la bola
  toque el borde.** Con 420 mm/s ya no alcanza. Es una limitación del actuador real, no del
  diseño del controlador.

## 3a. Resultados con el actuador del diseño (histórico, antes de la medición)

### D1 — Requisitos (100 mm → 0)

| | Valor | Requisito |
|---|---|---|
| tr | 0,83 s | — |
| ts | 1,37 s | ≤ 3 s ✔ |
| Mp | 4,4 % | ≤ 20 % ✔ |
| ess | 0,11 mm | ≤ 3 mm ✔ |
| max\|x\| en el plato | 102,7 mm | ≤ 127 mm ✔ |
| θ_cmd | −2,3° a 3,6°, sin saturar | |
| Temblor del plato en reposo | 0,31° (std), por el ruido de 1 mm | |

### D2 — Saturación y anti-windup

Empujón de 420 mm/s desde el centro, con 1° de desnivel.

- **La saturación de 12° solo aparece con perturbaciones que llevan la bola casi al borde.**
  Con 420 mm/s satura 0,23 s y la bola llega a 126,3 mm (124,0 mm con el actuador ideal). Con
  ≤ 380 mm/s no satura.
- **Con la integración condicional, el clamping no cambia nada:** con y sin anti-windup los
  resultados salen idénticos. El motivo es que el integrador no actúa mientras la bola se
  mueve rápido, que es justo cuando el actuador satura.
- **Con un PID clásico, el clamping sí ayuda:** el integrador llega a 1,31° en vez de 1,57°, y
  el ess baja de 3,48 a 3,17 mm. Este caso separa los dos mecanismos.

### D3 — Desnivel de 1°

La bola se desvía hasta 30,5 mm (un PD dejaría 29,3 mm de error permanente). Vuelve a menos de
3 mm a los 5,2 s, y el ess final es de 0,88 mm.

### D4 — Dos ejes

(80, −60) → (0, 0), y a los 4,5 s → (50, 50).

- Los tramos de 50–60 mm dan ts de 3,0 a 4,0 s, **por encima del requisito**, con Mp de 5 a
  15 %. En el tramo 1, el eje Y termina con ess = 3,7 mm al cortar a los 4,5 s: el integrador
  todavía no había terminado de converger. El eje Y solo, con un cambio de 60 mm, da lo mismo: **no es acople entre ejes**.
- La causa es la métrica. Con cambios chicos, la banda del 5 % mide 2,5–3 mm, comparable al
  ruido de x̂ (~0,75 mm std) más un sobreimpulso de ~5 mm en absoluto. R1 está definido sobre
  el ensayo de 100 mm, así que no se cambia a posteriori. Hay que revisarlo cuando se mida el
  ruido real.

### D5 — Robustez (ensayo D1)

| Caso | ts [s] | Mp [%] | ess [mm] | Cumple |
|---|---|---|---|---|
| Nominal | 1,37 | 4,4 | 0,11 | ✔ |
| Retardo 120 ms | 3,90 | 5,5 | 1,93 | ✘ (ts) |
| c = 0,685 | 1,30 | 4,0 | 0,24 | ✔ |
| h_sup = 40 / 60 mm | 1,37 | 4,4 / 4,3 | 0,12 / 0,11 | ✔ |
| Servos a 6 V | 1,37 | 4,4 | 0,11 | ✔ |
| Servo lento (ωn = 30) | 1,20 | 4,7 | 0,02 | ✔ |
| Ruido 0,3 mm | 1,30 | 3,5 | 0,08 | ✔ |
| Ruido 2 mm | 3,90 | 7,0 | 0,97 | ✘ (ts) |

Las dos fallas son por ts: el sobreimpulso queda apenas por encima de la banda de 5 mm, y la
cola tarda en entrar. **Por eso es prioritario medir la latencia y el ruido reales.**

### D6 — Planta lineal vs no lineal en lazo cerrado

En D1 la diferencia máxima es de 1,6 mm. En D2 (empujón) es de 10,7 mm, y la bola de la planta
no lineal llega 7 mm más lejos. Esto confirma lo de la Etapa A: el término centrífugo pesa
cuando el plato se mueve rápido con la bola lejos del centro.

## 4. Pendientes que afectan estas conclusiones

Medir el retardo, el ruido y Ts (`run_benchmark.py`, `medir_ruido.py`), identificar c
(Etapa B) y la dinámica real del servo. Después, volver a correr C1 y D1.

---

## 5. Segunda estrategia: MIL del LQR y comparación con el PID (`D2_MIL_LQR_BoP.m`, 2026-11-25)

Corre el PID (C1) y el LQR (C2) con el mismo simulador, la misma planta, el mismo Ts, retardo,
ruido (misma semilla), integrador numérico y duración. Casos:

- L1: requisitos;
- L2: saturación y anti-windup del LQR, con un empujón de 420 mm/s y 1° de desnivel;
- L3: desnivel;
- L4: dos ejes;
- L5: robustez, incluidos c = 0,2 y retardo de 0,3 s identificados en el prototipo.

**Cómo correrlo (MATLAB):** `cd etapaC`, `C2_disenar_LQR_BoP`; después `cd ../etapaD`,
`D2_MIL_LQR_BoP` (unos minutos en MATLAB; en Octave tardó ~35 min). Devolver
`etapaC/resultados/C2_*` y `etapaD/resultados/D2_*` y `D_caso_LQR_*`.

**Resultados preliminares (Octave 8.4, `verificacion_octave/D2_consola.txt`):**

| Ensayo | PID | LQR |
|---|---|---|
| L1 requisitos: ts / Mp / ess | 1,30 s / 4,5 % / 0,16 mm | 2,03 s / 5,2 % / 0,15 mm (cumplen los dos) |
| L1: inclinación máxima / temblor en reposo | 3,6° / 0,31° | 8,5° / 0,62° |
| L2 empujón (LQR): sin AW / con AW | — | ess 12,7 / 11,6 mm; los dos llegan a 133 mm (pasan el borde) |
| L3 desnivel 1°: max\|x\| / ess / vuelve a < 3 mm | 31,3 mm / 0,89 mm / 5,2 s | 24,0 mm / 1,23 mm / 8,8 s |
| L5 retardo 120 ms: ts | 3,90 s (no cumple) | 1,77 s (cumple) |
| L5 ruido 2 mm: ts | 7,0 s | 6,5 s (ninguno cumple) |
| L5 c = 0,2: Mp | 37 % | 39 % (ninguno cumple) |

**Selección:** el PID sigue a las etapas E–H. Cumple los requisitos con menos de la mitad de la
inclinación y la mitad del temblor del plato (importante con 1–2° de holgura), corrige el
desnivel más rápido y es más simple: 3 ganancias y 2 variables internas, contra 7 y 5 del LQR.
El LQR tolera mejor el retardo: es el candidato natural para un rediseño con el modelo
identificado.
