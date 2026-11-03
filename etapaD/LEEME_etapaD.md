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

## 3. Resultados preliminares (Octave 8.4; ver `verificacion_octave/D1_consola.txt`)

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
