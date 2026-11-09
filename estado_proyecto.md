# Estado del proyecto — Ball on Plate (EL5409, II Sem 2026)

> Archivo vivo (CLAUDE.md, sección 6). Se actualiza al cerrar cada etapa.
> Última actualización: **2026-11-03**, sesión 1 (Etapas A, C, D y E escritas y probadas en Octave hasta donde se puede sin Simulink; B aplazada).

---

## 1. Entorno de trabajo

| Ítem | Estado |
|---|---|
| Dónde corre Claude Code | Nube (contenedor Linux). Repo `Jordis17/LAB-CONTROL`, rama `claude/great-bell-pprlzs`. |
| `matlab -batch "ver"` | **No disponible** (`matlab: command not found`, 2026-11-03). |
| Modo de trabajo | **"MATLAB no disponible"** (CLAUDE.md 0.2). La IA escribe los `.m` y construye los `.slx` con scripts `build_*.m`; el equipo los corre en la computadora con MATLAB y sube la salida de consola y los archivos generados. Nada se reporta como ejecutado si no hay salida real. |
| Versión de MATLAB y toolboxes | **MATLAB R2026a Update 5 en la PC con Linux** (Ubuntu 22.04), salida en `ver_matlab.txt` (2026-11-06): MATLAB, Simulink, MATLAB Coder, Simulink Coder, Embedded Coder, Control System Toolbox (y otros que no se usan). `mex -setup C` → gcc. **Falta** el Simulink Support Package for Arduino Hardware (para PIL, Etapa G). |
| Python / visión | Pipeline en `proyecto_ControlDIP-develop/` (corre en la PC Linux del montaje). Sin ejecutar sobre el montaje real todavía. |

## 2. Etapas

| Etapa | Estado |
|---|---|
| A — Modelo de la planta | **Corrida en MATLAB R2026a (2026-11-06)**, resultados en `etapaA/resultados/`, iguales a Octave: pendiente 0,3429 °/°, ceros de Xm/Θ en ±j22,372 rad/s, jacobiano con error de 1,7e-13, polos de `c2d` iguales a `bop_discretizar`. Falta reemplazar la geometría de diseño con lo que salga de B (h_sup). |
| B — Identificación y validación | **En curso (2026-11-06).** Actuador ya medido (tabla servo → plato). Scripts B1 (rodadura: c y f, con validación) y B2 (medición con el plato inclinado: h_sup) escritos y probados en Octave con datos sintéticos (no se suben). Faltan los ensayos en el prototipo. Ver `etapaB/LEEME_etapaB.md`. |
| C — Diseño del controlador | **Corrida en MATLAB (2026-11-06)**: Kp 0,03412 °/mm, Kd 0,02588 °/(mm/s), Ki 0,02275 °/(mm·s), θ_lim 10°, PM 40,9°, GM +11,8/−12,6 dB, estable. Provisional hasta tener la Etapa B. |
| D — MIL | **Corrida en MATLAB (2026-11-06)** con el actuador medido: D1 cumple R1–R4 (ts 1,30 s, Mp 4,4 %, ess 0,18 mm, max 102,7 mm). Robustez: no cumple ts con retardo de 120 ms (3,03 s), ruido de 2 mm (4,9 s) ni firmware sin tabla (4,7 s, Mp 23,8 %). Provisional hasta tener la Etapa B. |
| E — Preparación y generación de código | **Completada (2026-11-06, MATLAB R2026a).** `Controller_BoP.slx` separado de la planta (12 entradas al bloque, 3 salidas). E1: igual al MIL bit a bit. Code Generation Advisor: 0 Fail, 5 Warning justificados. E2: código generado e inspección PASS; tabla modelo ↔ código en `etapaE/tabla_modelo_codigo.md`; el código C compilado con gcc reproduce el MIL (diferencia ≤ 4e-11 rad, por el redondeo de los CSV). |
| F — SIL | **Completada (2026-11-06, MATLAB R2026a).** Banco `BoP_Test_SIL.slx` (ramas Normal y SIL, dos ejes, una planta por rama). **PASS: diferencia 0 e igualdad exacta en 271/271 muestras** de th_cmd, I, saturado y de la planta. Para compilar SIL hizo falta E3 (configuración de hardware; modelo v1.2, E1 y E2 repetidos, código idéntico). Limitación: el ensayo no satura (la saturación se verificó en E1). Ver `etapaF/LEEME_etapaF.md`. |
| G — PIL | **Completada (2026-11-06, MATLAB R2026a + ESP32-D0WD-V3).** El paquete de Arduino no habilita PIL para la ESP32 (`IsPilSupported = 0`; G0, G0b, G0c). **Alternativa de ingeniería:** PIL propio. El código de `etapaE/codigo_generado` (idéntico byte a byte) se compila con Xtensa y corre en la ESP32 con un sketch puente serie (G3). **G4** (controlador solo vs MIL, D1 y D2 con 9 cuadros saturados) y **G5** (lazo cerrado de dos ejes, Normal vs PIL, 271 muestras): **PASS con igualdad exacta**. `_step`: 7,5 µs de mediana y 31,3 µs como máximo (0,094 % de Ts). Ver `etapaG/LEEME_etapaG.md`. |
| H — Implementación física | No iniciada |

## 3. Parámetros conocidos (de CLAUDE.md sección 0 y `docs/`)

Ningún valor de esta tabla viene de una identificación. Las columnas de estado son las del equipo.

| Parámetro | Valor | Estado | Fuente |
|---|---|---|---|
| Plato | 300 × 300 mm, acrílico 3 mm, borde 12 mm | Construido | CLAUDE.md 0.1 |
| Rango útil del centro de la bola | ±127 mm por eje | Calculado de la geometría | CLAUDE.md 0 |
| Bola | Ø 40 mm (r = 20 mm), masa 34 g | Medido | CLAUDE.md 0.1 |
| Coeficiente de rodadura c = 1/(1 + J/(m r²)) | 5/7 ≈ 0,714 nominal; estimado 0,685–0,714 | PENDIENTE identificar (Etapa B) | CLAUDE.md 0.1 |
| Brazo del servo r | 24 mm | DISEÑO | CLAUDE.md 0.1, artefacto del ensamble |
| Lado del brazo en neutro | Apunta hacia el centro del plato: eje del servo en x = 94 mm, punta en x = 70 mm (`sigma_brazo = −1`) | DISEÑO | Artefacto "Ensamble Ball on Plate" |
| Distancia centro del plato → rótula d | 70 mm (+X y +Y) | Diseñado | CLAUDE.md 0.1 |
| Relación servo → plato | ±45° servo ≈ ±14° plato; ≈0,34 °/° cerca del centro; no lineal | Calculada; verificar en el prototipo | CLAUDE.md 0 |
| Servo | Tower Pro MG90D (confirmar; `componentes.xlsx` dice MG90S). 0,10 s/60° a 4,8 V; 0,08 s/60° a 6 V; carrera ±45° | Hoja de datos | CLAUDE.md 0 |
| Tensión de alimentación de los servos | 4,8 V usado en el modelo | **SUPUESTO** conservador (define la velocidad: 4,8 V o 6 V) | — |
| Cotas del ensamble (desde la cara superior de la base) | cara inferior del plato 215,4 mm; pivote de la junta ≈169,4 mm (aprox.); pivote de las rótulas 195,6 mm; eje de los servos 33,4 mm; distancia entre las bolas de la cadena 162,2 mm | Diseño | `docs/mecanica-decisiones-y-medidas.md` |
| Altura del centro de la bola sobre el pivote de la junta, h | 69 mm (215,4 + 3 + 20 − 169,4) | DISEÑO; el propio ensamble supone el pivote a media altura de la junta | `docs/`, artefacto del ensamble |
| Periodo de muestreo Ts | 33,3 ms nominal (30 fps, piso del hardware) | PENDIENTE medir (`run_benchmark.py --period`) | CLAUDE.md 0 |
| Latencia de extremo a extremo | estimación a priori de 60 a 90 ms + dinámica del servo | PENDIENTE medir (`run_benchmark.py --latency`) | CLAUDE.md 0 |
| Cámara | **Redragon Fobos GW600** (corregido por el equipo, 2026-11-03): 720p, 30 fps máx., FOV diagonal 68,6°, foco fijo 50 cm–∞ (fichas de tiendas) | Dato del equipo | CLAUDE.md 0 |
| Ruido de medición σ | 1 mm en `config.py` es un marcador | PENDIENTE medir (`medir_ruido.py`) | `config.py` |
| Signo de Y (`INVERT_Y`) | — | PENDIENTE verificar | `config.py` |
| Fricción de rodadura, holguras, desnivel del plato en reposo | — | PENDIENTE medir | CLAUDE.md 0.1 |
| Requisitos | R1 ts ≤ 3 s, R2 Mp ≤ 20 %, R3 ess ≤ 3 mm (ensayo 100 mm → 0); R4 \|x\| ≤ 127 mm; diseño PM ≥ 40°, GM ≥ 6 dB | **DECISIÓN DE INGENIERÍA** (propuestos por la IA, aceptados por el equipo; no hay enunciado) | `etapaC/C0_requisitos_BoP.m` |
| Placa ESP32 | Placa de desarrollo ESP32 de 38 pines con módulo ESP-32 tipo WROOM-32 (FCC ID 2BB77-ESP32-32X), USB–serie **CP2102**, micro-USB, AMS1117 de 3,3 V. En el Arduino IDE: "ESP32 Dev Module" | Identificada por foto (2026-11-04) | Foto del equipo |
| Prueba de servos | Ambos servos responden con `prueba_servos.ino` (GPIO18 y GPIO19, fuente externa). Brazos ajustados a mano para que con el neutro (1500 µs, comando `C`) el plato quede lo más horizontal posible | **Hecho por el equipo (2026-11-04)**. Pendiente: sentido de giro por eje, desnivel residual medido con inclinómetro, tensión de la fuente | Equipo |
| Conexiones ESP32–servos | Servo X en GPIO18 y servo Y en GPIO19 (con 330 Ω), servos con fuente externa de 5–6 V y ≥ 3 A, GND común, ESP32 por USB | DISEÑO | `docs/conexiones_esp32_servos.html` |

## 4. Decisiones pendientes

| Decisión | Afecta a | Notas |
|---|---|---|
| Cambiar `PROCESS_ACCEL_STD` de 1500 a 500 en `proyecto_ControlDIP-develop/src/config.py` | Pipeline, C, D, H | Lo pide el diseño de la Etapa C (con 1500 el plato tiembla 0,67° en reposo). **No se tocó `config.py`**: decide el equipo, idealmente después de medir el ruido. |
| Dinámica real del servo (ωn = 50 rad/s es un supuesto) | C, D | Medir con el prototipo (escalón de comando, registro de la cámara). |
| ~~Ruta PIL si el paquete de soporte no habilita PIL para ESP32~~ | G | **Resuelto (2026-11-06):** no lo habilita; se usó un PIL propio (ver Etapa G). |

**Decisiones tomadas**

| Decisión | Justificación | Fecha |
|---|---|---|
| Sin enunciado oficial por ahora. El objetivo del equipo es que el sistema funcione y documentarlo después. Los requisitos los fija el equipo cuando haga falta (Etapa C). | Indicación del equipo | 2026-11-03 |
| La salida del controlador es la **inclinación del plato** (θx, θy); la cinemática inversa va en un bloque aparte. | Propuesta de la IA; el equipo aprobó el plan con un "ok". El modelo de la planta queda casi lineal en θ y la no linealidad del mecanismo se aísla y se verifica sola. **Confirmarlo explícitamente** antes de la Etapa C. | 2026-11-03 |
| Etapa A sin toolboxes: modelo lineal y discretización escritos a mano (`bop_discretizar`). | Todavía no se conoce la instalación de MATLAB; si está Control System Toolbox, A2 compara con `c2d`. | 2026-11-03 |
| Umbral de validez del modelo lineal: error de trayectoria < 5 % de max\|x\| (decisión de ingeniería). | Ningún documento lo fija. | 2026-11-03 |
| Sin prototipo disponible por ahora: la Etapa A usa la geometría del **diseño** (artefacto "Ensamble Ball on Plate" + `docs/`) y 4,8 V para los servos. | Indicación del equipo. Las mediciones reemplazan estos valores cuando haya prototipo. | 2026-11-03 |
| **Avanzar a C y D sin cerrar A ni hacer B**, con el modelo del diseño. Todo lo de C y D queda como provisional y se rehace después de B. | Indicación del equipo ("sigamos con las que se pueden realizar"). Es una excepción a la regla de una etapa a la vez (CLAUDE.md 4). | 2026-11-03 |
| Requisitos R1–R4 y criterios PM ≥ 40°, GM ≥ 6 dB (ver tabla de parámetros). | Propuestos por la IA, aceptados por el equipo. | 2026-11-03 |
| Etapa E: `Controller_BoP.slx` de **un eje**, código *Reusable function* (el firmware lo instancia dos veces), double, parámetros `Simulink.Parameter` ExportedGlobal, entrada `habilitado` (arranque, sin bola, watchdog), hardware "Generic → 32-bit Embedded Processor" hasta conocer la placa. | Separación del algoritmo y de la planta, como en el Proyecto 1; la placa ESP32 exacta está PENDIENTE. | 2026-11-03 |
| Ley de control en una sola función (`etapaC/funciones/bop_ley_control.m`) que usan el MIL y el bloque del modelo. | Una sola fuente del algoritmo. El cambio en el MIL se verificó en Octave: resultados idénticos bit a bit (diferencia 0 en θ, I y trayectoria) en dos casos. | 2026-11-03 |
| El controlador usa la velocidad del Kalman (v̂) como término derivativo. | Ya la calcula el pipeline y no agrega otro filtro ni más atraso. Interfaz por eje: entra (r, x̂, v̂), sale θ_cmd. | 2026-11-03 |
| Estructura: PD por asignación de polos + integral con **integración condicional** (4 cuadros con \|v̂\| < 25 mm/s), error recortado a ±30 mm, clamping y saturación a ±12°. | El PD no corrige el desnivel y el PID clásico da ~38 % de sobreimpulso (`etapaC/LEEME_etapaC.md`). | 2026-11-03 |

## 5. Discrepancias y observaciones

1. **Enunciado oficial del proyecto final ausente.** `Intrucciones.txt` está vacío (0 bytes). Hasta tenerlo, cualquier requisito que no esté en CLAUDE.md se marca como conocimiento adicional de ingeniería (CLAUDE.md 3.2).
2. **Modelo del servo:** CLAUDE.md dice MG90D; `componentes.xlsx` dice MG90S (180°). Confirmar en la etiqueta del servo instalado: cambia la carrera real y la velocidad.
3. **Junta universal:** `componentes.xlsx` lista un cardán de 1/2″; las piezas son para 3/8″ (ya anotado por el equipo en `docs/`). Sin efecto en el modelo.
4. **README del pipeline** dice que "el PD y la cinemática inversa viven en la ESP32". La estructura del controlador **no está decidida**: se elige y justifica en la Etapa C. La frase del README es una intención previa, no una decisión del proyecto.
5. **Altura del pivote:** el centro de la bola queda unos 69 mm sobre el centro de la junta (cotas de diseño, el pivote está marcado "aprox."). Ese desplazamiento agrega al modelo un término proporcional a la aceleración angular del plato que puede introducir ceros en la función de transferencia. Hay que incluirlo en la Etapa A y cuantificar su peso; por eso conviene medir h en el prototipo.
6. ~~Geometría horizontal del eslabonamiento~~ **Resuelto** con el artefacto del ensamble: eje del servo en 94 mm, brazo hacia el centro. La cinemática de `etapaA/` coincide con la del visor 3D. Con esta geometría, ±45° de servo dan −13,45° y +14,07° de plato.
10. **El artefacto del ensamble describe la bola al 100 % de relleno (~41,5 g).** Está desactualizado: CLAUDE.md y `docs/` dicen 90 % y 34 g medidos. No afecta al modelo, porque la masa se cancela.

7. **La cámara no mide la posición sobre el plato cuando el plato está inclinado.** Con la homografía fija, mide la proyección horizontal: a primer orden Xm = x − h·θ. Con 14° la diferencia llega a unos 14 mm en el borde (A1, sección 5, Octave). Esto cambia los ceros del modelo que se realimenta. Verificarlo en la Etapa B dejando la bola quieta contra el borde con el plato a ángulos conocidos.
8. **El término no lineal dominante es el centrífugo x·θ̇²**, no el seno. El modelo lineal es bueno con velocidades de inclinación bajas y empeora rápido con la velocidad máxima del servo (Octave, preliminar). Esto pesa en la Etapa C: conviene limitar la velocidad de inclinación que pide el controlador.
9. El mecanismo es asimétrico con las cotas de diseño: ±45° de servo dan −13,45° y +14,07° de plato (Octave, preliminar).
11. **Robustez (D5, Octave):** con retardo de 120 ms o ruido de 2 mm, ts pasa de 3 s (3,9 s). En los dos casos el sobreimpulso (~5,5–7 %) queda apenas fuera de la banda de 5 mm. Medir la latencia y el ruido reales es prioritario.
12. **Cambios de 50–60 mm (D4):** ts de 3 a 4 s y Mp de 5 a 15 %, por la banda relativa del 5 % (2,5–3 mm), que es comparable al ruido de x̂. No es acople entre ejes: el eje Y solo da lo mismo. R1 está definido para 100 mm y no se cambió a posteriori.
20. **Primera prueba en lazo cerrado (2026-11-05, video):** la bola se estabiliza en el centro, pero hay brincos fuertes del plato y la bola se cae. Lo más probable: la bola sale del campo de la cámara cerca del borde (margen de FOV ~0,5 mm con la GW600 a 450 mm), la visión manda `estado = 0` y el plato cambia de golpe; y el integrador se carga con la bola sostenida. Firmware v2 con límite de velocidad, zona y tope del integrador y filtro de saltos (`firmware/bop_prueba_lazo_v2/`), todavía no evaluados en el MIL. Pendiente: CSV de `logs/` de los brincos, verificación del campo de la cámara con el plato inclinado, fijación de la base y verificación de que los ejes no estén cruzados.
19. **Prueba funcional del lazo antes de E–G (decisión del equipo, 2026-11-04, por tiempo):** firmware escrito a mano `firmware/bop_prueba_lazo/` con la misma ley que el MIL (verificada en PC contra Octave: diferencia máxima de 6e-7°), tabla medida invertida por tramos lineales, armado con el botón BOOT, watchdog de 200 ms y plato horizontal con `estado = 0`. Procedimiento en `firmware/LEEME_prueba_lazo.md`. No reemplaza las Etapas E–H.
18. **MIL con el actuador medido (2026-11-04, Octave):** θ_lim baja a 10°. D1 cumple R1–R4 (ts 1,30 s, Mp 4,5 %, ess 0,16 mm). El firmware **tiene que** convertir θ → comando con la tabla medida: con una conversión lineal sin tabla, Mp sube al 24,6 % y ts a 4,9 s. Con θ_lim = 10°, un empujón de 420 mm/s ya lleva la bola al borde (132,7 mm). El modelo de actuador está en `etapaD/funciones/bop_actuador.m`; el neutro que nivela el plato según la tabla es +2,4° (X) y +6,8° (Y) de comando.
17. **Sentido de giro confirmado (2026-11-04):** un comando positivo (pulso mayor) **baja** el lado de su servo, en los dos ejes. En convención del plato, θx = lectura X de la app y θy = −lectura Y. Desnivel en el neutro: θx = +1,3° y θy = +3,5°. Tabla en convención del plato: `datos_prototipo/mecanica/servo_plato_v2_convencion_plato.csv`.
16. **Segunda medición servo → plato (v2, con signo, después de corregir los ejes):** pendiente cerca del neutro de 0,50 °/° (X) y 0,54 °/° (Y), ~1,5 veces el diseño. Sigue asimétrica (0,55 contra 0,35 °/° según el lado). Rango simétrico ±12,1° (X) y ±11,3° (Y) con ±40° de comando. Desnivel en el neutro: +1,3° (X) y −3,5° (Y), que se corrige por software (~+33 µs y ~+76 µs según el ajuste). Implicaciones: firmware con cinemática inversa por tabla medida, θ_lim ≈ 10°, y volver a correr C y D con el actuador medido. Pendiente: giro real del brazo con ±40 (separar escala del servo de geometría), modelo de servo en la etiqueta y cuáles fueron las correcciones. Ver `datos_prototipo/mecanica/LEEME.md`.
15. **Relación servo → plato medida (2026-11-04, `datos_prototipo/mecanica/`):** muy asimétrica. Del lado de los comandos negativos se parece al diseño (0,34–0,37 °/°); del lado positivo da la mitad (0,15–0,19 °/°). Con +40° de servo, el plato llega solo a 7,7° (X) y 7,2° (Y). Hipótesis: al nivelar el plato a mano, el brazo quedó ~30° fuera de la horizontal en el neutro. Si se confirma, la inclinación simétrica útil baja a ~±7,5° y la saturación de 12° del controlador queda fuera de alcance. **Pendiente:** confirmar el signo de las lecturas, el ángulo del brazo en neutro y decidir entre corregir el montaje o rehacer la cinemática y bajar θ_lim. En Y queda además un desnivel de ~1,3° en el neutro.
14. **Campo de visión de la cámara GW600 muy justo:** a 450 mm cubre unos 535 × 301 mm (16:9, sensor completo), o sea medio milímetro de margen vertical sobre el plato. Si 640×480 es un recorte central, el plato no entra (≈268 × 201 mm). Hay que verificarlo antes de calibrar. Si no entra, subir la cámara a ~500 mm (cambia `CAMERA_HEIGHT_MM`, `P.H_cam` y la corrección de paralaje). No afecta a Ts ni a las Etapas A–E.
13. **La saturación (12°) solo aparece con perturbaciones que llevan la bola casi al borde** (empujón ≥ 400 mm/s). Con la integración condicional, el anti-windup no cambia nada en esos casos; con un PID clásico sí (D2b).

## 6. Archivos generados

| Ruta | Qué es |
|---|---|
| `etapaA/LEEME_etapaA.md` | Modelo, hipótesis, ecuaciones, método de comparación, resultados preliminares, cómo correrlo |
| `etapaA/A0_parametros_BoP.m` | Única fuente de parámetros, con unidades y estado |
| `etapaA/A1_modelo_no_lineal_BoP.m` | Geometría del neutro, cinemática servo–plato, acople del mecanismo, verificación de la dinámica, error de la cámara |
| `etapaA/A2_linealizar_BoP.m` | Modelo lineal, jacobiano, discretización, comparación lineal vs no lineal y barrido de amplitud |
| `etapaA/funciones/` | Dinámica, medición, cinemáticas, perfil de prueba, discretización, métricas y CSV |
| `etapaA/resultados/` | **Todavía no existe en el repo.** Lo genera MATLAB al correr A1 y A2. |
| `etapaA/verificacion_octave/`, `etapaC/verificacion_octave/`, `etapaD/verificacion_octave/` | Consolas de Octave 8.4 (preliminares) que respaldan los números citados en los LEEME |
| `etapaC/C0_requisitos_BoP.m` | Requisitos y definiciones únicas de las métricas |
| `etapaC/C1_disenar_controlador_BoP.m` | Diseño: Kalman, asignación de polos, integral, márgenes, robustez, comparación de estructuras |
| `etapaC/funciones/` | `bop_controlador_paso` (ley discreta, es la referencia para la Etapa E), `bop_controlador_estado0`, `bop_lazo_lineal`, `kalman_estacionario`, `disenar_pd_asignacion`, `bop_param_con` |
| `etapaD/D1_MIL_BoP.m` | Casos MIL D1 a D6 |
| `etapaD/funciones/` | Simulador MIL (`bop_mil_simular`, `bop_mil_config`), métricas y utilidades |
| `etapaC/funciones/bop_ley_control.m` | **Única fuente** de la ley de control (MIL y modelo) |
| `etapaE/E0_build_Controller_BoP.m`, `init_Controller_BoP.m`, `ley_control_BoP_bloque.m` | Construcción del modelo del controlador, parámetros calibrables y función del bloque |
| `etapaE/E1_verificar_equivalencia_BoP.m` | Modelo vs MIL, muestra a muestra (Parte A sin Simulink, Parte B con `sim`) |
| `etapaE/E2_generar_codigo_BoP.m` | Generación de código e inspección automática |
| `etapaE/Controller_BoP.slx`, `etapaE/codigo_generado/` | Modelo del controlador (v1.2) y su código generado |
| `etapaF/` | Banco SIL `BoP_Test_SIL.slx`, F0 y F1, planta del banco (`funciones/planta_bop_paso.m`), resultados |
| `etapaG/G0_prueba_PIL_minima_BoP.m`, `G0b_…`, `G0c_…` | Intento con el PIL de Simulink y diagnósticos (evidencia de que la ESP32 no tiene PIL en el paquete) |
| `etapaG/pil_esp32/bop_pil_esp32/` | Sketch puente serie y copia del código de la Etapa E que corre en la ESP32 |
| `etapaG/G3_…`, `G4_…`, `G5_…`, `etapaG/funciones/g_pil_*.m` | Preparación y carga, PIL del controlador solo, banco en lazo cerrado y comunicador serie |
| `etapaG/resultados/` | Consolas G0 a G5, CSV de G4 y G5, `G5_resultados.mat`, `G5_diferencias.png` |

El contenido del zip `Proyecto_FINAL_LAB_Control_para_ClaudeCode.zip` se copió a la raíz del repo sin cambios (sesión 1).

## 7. Orden de columnas de los CSV

En `etapaA/orden_csv.md`, `etapaC/orden_csv.md` y `etapaD/orden_csv.md`.

## 8. Punto de control

```
Etapa: A — Modelo de la planta (sesión 1, 2026-11-03)
Completada: No
Resultados obtenidos: modelo no lineal de 2 ejes, modelo lineal por eje (doble integrador con
  ceros que dependen de h_sup), discretización con retardo y comparación lineal vs no lineal.
  Todo corrido solo en Octave 8.4: es PRELIMINAR.
Archivos generados: etapaA/ (ver sección 6)
Datos pendientes: corrida en MATLAB (A1, A2) + `ver`. Las mediciones del prototipo (h_sup, tabla
  de servo vs. plato, tensión) quedan aplazadas: por ahora se usan los valores del diseño.
Problemas detectados: discrepancias 1 a 9 de la sección 5.
Decisiones tomadas: ver sección 4.
Qué debe conservarse: etapaA/ completa, resultados de MATLAB en etapaA/resultados/.
Siguiente paso: analizar la salida de MATLAB, actualizar con las mediciones y cerrar la Etapa A.
```

```
Etapa: C — Diseño del controlador (sesión 1, 2026-11-03)
Completada: No (provisional: sin Etapa B ni corrida en MATLAB)
Resultados obtenidos (Octave): Kp = 0,0341 °/mm, Kd = 0,0259 °/(mm/s), Ki = 0,0228 °/(mm s);
  Kalman σa = 500; wc = 3,30 rad/s, PM = 40,9°, GM +11,8 / −12,6 dB; estable.
Archivos generados: etapaC/ (C0, C1, funciones, verificacion_octave)
Datos pendientes: corrida en MATLAB; retardo, ruido y Ts medidos; c identificado; dinámica del servo.
Problemas detectados: con 120 ms de retardo el PM baja a 32° (no cumple el criterio de 40°).
Decisiones tomadas: ver sección 4.
Qué debe conservarse: etapaC/ completa y resultados/C1_controlador.mat cuando lo genere MATLAB.
Siguiente paso: correr C1 en MATLAB; después la Etapa E (controlador separado en Simulink).
```

```
Etapa: D — MIL (sesión 1, 2026-11-03)
Completada: No (provisional)
Resultados obtenidos (Octave): D1 cumple R1–R4 (ts 1,37 s, Mp 4,4 %, ess 0,11 mm, max|x| 102,7 mm);
  desnivel de 1° corregido en 5,2 s; saturación solo con empujones ≥ 400 mm/s; robustez con fallas
  de ts con retardo de 120 ms y ruido de 2 mm.
Archivos generados: etapaD/ (D1, funciones, verificacion_octave)
Datos pendientes: corrida en MATLAB; los mismos de C.
Problemas detectados: observaciones 11 a 13 de la sección 5.
Qué debe conservarse: etapaD/ completa y resultados/ cuando los genere MATLAB.
Siguiente paso: Etapa E (Controller.slx por script, Advisors, generación de código para ESP32).
```

```
Etapa: E — Preparación y generación de código (sesión 1, 2026-11-03)
Completada: No
Resultados obtenidos: E1 Parte A (función del bloque vs MIL, Octave): diferencia exacta 0 en
  th_cmd, I y saturado en 5 ensayos (D1, D2 con saturación, D3, D4 con dos ejes).
Archivos generados: etapaE/ (E0, E1, E2, init, función del bloque, LEEME, verificacion_octave)
Datos pendientes: correr E0, E1 (Parte B), Code Generation Advisor y E2 en MATLAB; salida de `ver`.
Problemas detectados: ninguno todavía (no hay corrida en MATLAB).
Qué debe conservarse: Controller_BoP.slx (intocable), codigo_generado/, resultados/ y el reporte del Advisor.
Siguiente paso: con el código generado, completar la tabla modelo <-> código; después, Etapa F (banco SIL).
```

```
Etapa: E — Preparación y generación de código (cierre, 2026-11-06)
Completada: Sí
Resultados obtenidos: E1 Parte A y B PASS (diferencia 0 en th_cmd, I y saturado, 5 ensayos);
  Advisor 0 Fail / 5 Warning / 26 Passed; E2 inspección PASS; código C compilado en PC igual
  al MIL hasta 4e-11 rad.
Archivos generados: etapaE/Controller_BoP.slx, etapaE/codigo_generado/, etapaE/resultados/
  (E0, E1, E2 y advisor/), etapaE/tabla_modelo_codigo.md
Datos pendientes: ninguno para E. Para G: placa en la configuración de hardware (endianness y
  redondeo de la división entera) y el support package de Arduino.
Problemas detectados: ninguno que bloquee. Observaciones para H en la tabla modelo ↔ código
  (nq double sin tope; double emulado en la ESP32).
Decisiones tomadas: modelo de un eje con Reusable function; double; parámetros ExportedGlobal.
Qué debe conservarse: Controller_BoP.slx (referencia intocable), codigo_generado/, resultados/.
Siguiente etapa: F — SIL (banco Normal vs SIL con planta en Simulink).
```

```
Etapa: F — SIL (cierre, 2026-11-06)
Completada: Sí
Resultados obtenidos: igualdad exacta Normal vs SIL en 271/271 muestras de las 10 señales
  (th_cmd, I, saturado de cada eje; x_hat, x, y de la planta). Ensayo tipo D4, 9 s.
Archivos generados: etapaF/BoP_Test_SIL.slx, etapaF/resultados/ (F0, F1, CSV, .mat),
  etapaE/E3_config_hardware_BoP.m y Controller_BoP.slx v1.2.
Datos pendientes: ninguno para F.
Problemas detectados: la primera compilación SIL falló por la configuración de hardware de
  producción (resuelto con E3, sin cambiar el algoritmo); la planta del banco necesitó un
  ajuste para la generación de código.
Decisiones tomadas: planta del banco simplificada (actuador directo en ángulo de plato, retardo
  entero), suficiente para comparar el controlador.
Qué debe conservarse: BoP_Test_SIL.slx, resultados/, Controller_BoP.slx v1.2.
Siguiente etapa: G — PIL (banco separado con la ESP32); en paralelo, B con el prototipo.
```

```
Etapa: G — PIL (cierre, 2026-11-06)
Completada: Sí
Resultados obtenidos: G4, controlador solo vs MIL: igualdad exacta en D1 (194 cuadros) y en D2
  (179 cuadros, 9 saturados en las dos). G5, lazo cerrado de dos ejes, Normal vs PIL: igualdad
  exacta en 271/271 muestras de las 10 señales. La rama Normal coincide con F1 (≤ 2,3e-10 relativo).
  _step en la ESP32: 7,5 µs de mediana y 31,3 µs como máximo (0,094 % de Ts), con double emulado.
Archivos generados: etapaG/ (scripts G0 a G5, pil_esp32/, funciones/, resultados/).
Datos pendientes: ninguno para G.
Problemas detectados: el Simulink Support Package for Arduino (R2026a) no habilita PIL para la
  ESP32 (IsPilSupported = 0; su clase PIL falla por dentro aun registrada a mano). El código
  generado con la placa ESP32 no es idéntico al de SIL (una variable temporal extra) y depende
  de rtw_continuous.h, así que no se usó.
Decisiones tomadas: PIL propio (alternativa de ingeniería). Corre en la ESP32 exactamente el
  código verificado en SIL, con un comunicador serie propio y el banco en MATLAB, coherente con
  el banco de Simulink de F.
Qué debe conservarse: etapaG/resultados/, pil_esp32/, Controller_BoP_ESP32.slx (evidencia del
  intento), las consolas G0b y G0c.
Siguiente etapa: B — identificación con el prototipo (pendiente desde el inicio). Después,
  actualizar los parámetros, repetir C y D (y E a G si cambian las ganancias) y pasar a H.
```

## Mediciones de la cámara (2026-11-06, `datos_prototipo/camara/`)

| Dato | Resultado | Nota |
|---|---|---|
| Exposición y balance | Fijos: manual, 5 ms, 4600 K, sin framerate dinámico (`v4l2-ctl --list-ctrls`) | El aviso "no quedó bloqueada" era un error de lectura del pipeline, ya corregido |
| Periodo, YUYV, 1 buffer | 38,1 ms de media (26,2 fps); 14,7 % de cuadros perdidos | Configuración anterior |
| Periodo, MJPG, 1 buffer | 48,9 ms (20,5 fps); 46 % de cuadros perdidos | Se descarta MJPG |
| **Periodo, YUYV, 2 buffers** | **33,25 ms (30,1 fps); desv. 1,9 ms; 0 % perdidos; 100 % dentro de ±5 ms del nominal** | Cumple el criterio. Queda `CAMERA_BUFFERS = 2` |
| Latencia (YUYV, 1 buffer, incluye el monitor) | Mediana de 59,6 / 60,2 / 60,5 ms (3 corridas) | |
| **Latencia (YUYV, 2 buffers, incluye el monitor)** | **Mediana de 57,8 y 60,3 ms** (corridas 2 y 3); mínimo de 26 a 30 ms | El segundo buffer **no agrega latencia**. La corrida 1 se descarta: los primeros 8 destellos no se detectaron o dieron 390 a 630 ms porque la cámara todavía no apuntaba bien; los últimos 7 dan 56 a 62 ms. Con ~60 ms (cota superior) hay margen frente a los 75 ms del diseño |
| Ruido (bola quieta) | Desv. de 0,12 mm en el centro y 0,09 mm en la esquina | El diseño supuso 1 mm (`MEAS_NOISE_STD_MM`) |
| Esquina en Y = 132,4 mm | Fuera del rango físico (máximo 127 mm) | **Revisar la calibración** con 5 puntos medidos con regla antes de B1 y B2 |

## Identificación en lazo cerrado y ruido del Kalman (2026-11-09)

- **Telemetría.** El firmware `bop_prueba_circulo_lazo` devuelve en cada cuadro la inclinación
  aplicada. Columnas nuevas del log de `main_vision.py`, al final y en este orden: `tel_modo,
  tel_banderas, tel_n, tel_t_ms, tel_thx, tel_thy, tel_leyx, tel_leyy, tel_Ix, tel_Iy, tel_rx,
  tel_ry, tel_x_rx`. La fila k guarda la respuesta a la trama k−1, y el eco `tel_x_rx` lo comprueba.
- **B3.** `etapaB/B3_identificar_lazo_cerrado_BoP.m` identifica c efectivo, desnivel y τ con los
  logs `ident` y valida con los `valid`. Se probó con datos sintéticos y falta correrlo con datos
  reales. Ver `etapaB/LEEME_etapaB.md`, sección 6.
- **`MEAS_NOISE_STD_MM` volvió a 1,0** (estaba en 0,11 desde el commit `17beb84`).
  - En simulación, 0,11 hace oscilar el lazo por el paralaje: el plato llega al máximo de
    velocidad cuadro a cuadro y la bola se desvía de 40 a 70 mm.
  - Es la causa más probable del "delay" y de las caídas que se vieron en el prototipo el
    2026-11-09.
  - El controlador se diseñó y verificó con 1,0 (Etapas C a G).

### Análisis del log real `sesion_20261109_120621.csv` (2026-11-09)

Firmware `bop_prueba_circulo_lazo` con telemetría y `MEAS_NOISE_STD_MM = 1.0`. Duración 241 s:
86 s desarmado y 155 s en modo centro. **El modo círculo no se activó.**

1. **Causa del "delay": la ESP32 procesaba 25 tramas por segundo (una cada 40,0 ms exactos)
   y la PC manda 30.** El buffer de recepción se llenaba y el lazo trabajaba con datos de
   **19 cuadros (unos 0,6 s) de atraso**. Lo prueba el eco `tel_x_rx`: coincide con la x de
   15 a 23 filas antes. Además se perdía el 16 % de las tramas.
   - Probablemente pasaba lo mismo con los firmware v1 y v2, que leen igual (byte a byte y una
     trama por vuelta).
   - **Arreglo en `bop_prueba_circulo_lazo`:** lectura en bloque sin espera; se procesa solo la
     trama más nueva y se descartan las viejas.
   - La telemetría pasa al formato 2 (0xBC, 57 bytes), que agrega las tramas descartadas, los
     checksums malos y el tiempo máximo de `loop()`. Columnas `tel_descartadas`, `tel_malas` y
     `tel_loop_us` del log.
2. **Rozamiento de la bola.** En modo centro, la bola se quedó quieta en x = 12 mm durante 11 s
   mientras el integrador llevaba el plato de 0,4° a 3° (I_MAX). Después se soltó de golpe y,
   con 0,6 s de atraso, el lazo entró en una oscilación de ±140 mm con el plato saturado en
   ±10°, con rebotes en el borde y la bola cayéndose.
   - Que aguante 3° sugiere bastante resistencia a la rodadura (bola impresa en 3D, con capas) o
     una marca o raya en el plato. Hay que revisarlo.
3. **Signos de los ejes: correctos.** La regresión de la aceleración medida contra
   −g·sen(θ) da c > 0 en X y en Y. El c negativo que dio B3 al principio salía de ventanas con
   la bola quieta, y ahora B3 exige 15 mm de recorrido por ventana.
4. **B3 con este log:** solo 3 ventanas útiles, datos insuficientes, no se reportan
   parámetros. Hay que repetir el ensayo con el firmware corregido.
5. **Calibración:** la visión reporta hasta ±158 mm, y el máximo físico es 127 mm. Sigue
   pendiente la comprobación con 5 puntos medidos con regla.

### Servos cruzados (2026-11-09)

En el video del modo centro, la bola quedaba pegada al borde Y ≈ +120 mm. El equipo confirmó que
**el servo de GPIO18 es el del eje Y y el de GPIO19 el del eje X**: el firmware tenía los pines al
revés, así que cada eje se corregía moviendo el otro.
- Corregido en todos los firmware (`PIN_X = 19`, `PIN_Y = 18`, filas de la tabla servo → plato
  intercambiadas para que cada una siga a su servo físico).
- Tablas de comandos de `etapaB/LEEME_etapaB.md`, `docs/conexiones_esp32_servos.html` y
  `datos_prototipo/mecanica/LEEME.md` actualizados.
- Probablemente esto también explica el comportamiento errático de las pruebas anteriores.
  Pendiente: probar el modo centro con el firmware corregido.

### Ejes de la cámara cruzados (2026-11-09)

- Corrección: lo de los servos cruzados resultó incorrecto. Con el cambio de pines la bola se
  pegaba a las esquinas de una diagonal.
- Pruebas del equipo: con `X 20` baja el lado derecho y con `Y 20` el de arriba. Al empujar la
  bola **a la derecha sube la Y de la cámara**, y **hacia arriba sube la X**. Los **ejes de la
  cámara están cruzados**, con los signos bien: la calibración se cliqueó empezando por otra
  esquina.
- **Arreglo inmediato:** `SWAP_XY = True` en `src/config.py`; el detector intercambia x e y.
- **Arreglo definitivo:** recalibrar con el orden de clics por servos (instructivo 2.7 y
  `calibrate_camera.py`) y dejar `SWAP_XY = False`.
- Pines: hay que ver si el cambio a GPIO19/18 queda. Con `X 20` baja el lado derecho y con
  `Y 20` el de arriba, en el firmware nuevo (X = GPIO19). Si "derecha" es el lado del servo X,
  los pines nuevos están bien. Por confirmar con la prueba del modo centro.

### Primera identificación en lazo cerrado con datos reales (2026-11-09, B3)

Ejes de la cámara corregidos (`SWAP_XY = True`). Ensayo automático (modo 3) en dos logs:
`sesion_20261109_143311` (ident, completo) y `sesion_20261109_143813` (valid, hasta la fase 4).
Modelo por eje: ẍ = −c·g·sen(θ(t−τ)) + b − f·sign(ẋ).

| | X | Y |
|---|---|---|
| c efectivo (nominal 0,714) | **0,19** | **0,22** |
| Desnivel equivalente | −0,67° | −1,82° |
| f (rozamiento), como inclinación mínima para rodar | 41 mm/s², ≈ 1,2° | 37 mm/s², ≈ 1,0° |
| τ (orden al plato → bola) | 340 ms | 370 ms |

τ común: 370 ms. La curva del error contra τ es plana entre 260 y 410 ms, así que τ es poco
preciso, pero claramente mayor a 200 ms.

**Validación** con el otro log, prediciendo 0,8 s sin reajustar:

| Eje | Modelo identificado: RMSE / FIT | Nominal: RMSE / FIT |
|---|---|---|
| X | 9,1 mm / 69 % | 26,5 mm / 11 % |
| Y | 10,5 mm / 61 % | 48,3 mm / −78 % |

El residuo tiene autocorrelación de 0,93: al modelo todavía le falta algo, probablemente holgura
o la dinámica real del servo.

**Lectura:**
- La bola responde a la inclinación pedida unas **3,5 veces menos** de lo que dice el modelo, y
  con unos **350 ms de retardo**.
- Hipótesis principal: **holgura en rótulas y varillas** o servo sin fuerza suficiente. Con
  órdenes de 1° a 4° el plato se mueve mucho menos de lo pedido y tarde. Falta verificarlo con
  la app y comandos pequeños (ida y vuelta).
- Con esto se explica que "le cueste centrar" y que el círculo salga mal: el controlador se
  diseñó para c = 0,71 y unos 75 ms.
- **Escalones (fase 2):** la bola se queda a 50 a 115 mm de la referencia por varios segundos
  con el plato a −2° a −3°. El integrador no ayuda, porque el firmware solo integra con
  |error| < 40 mm (`E_ZONA`).
- La ESP32 sigue con `loop()` de 40 ms (25 Hz). Ya no hay atraso acumulado (descarta tramas),
  pero la causa de los 40 ms sigue sin identificarse.
- **Parámetros PRELIMINARES:** un solo log de identificación y modelo incompleto. No se pasan a
  A0 todavía.
