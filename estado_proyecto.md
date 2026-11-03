# Estado del proyecto — Ball on Plate (EL5409, II Sem 2026)

> Archivo vivo (CLAUDE.md, sección 6). Se actualiza al cerrar cada etapa.
> Última actualización: **2026-11-03**, sesión 1 (puesta al día y plan de la Etapa A).

---

## 1. Entorno de trabajo

| Ítem | Estado |
|---|---|
| Dónde corre Claude Code | Nube (contenedor Linux). Repo `Jordis17/LAB-CONTROL`, rama `claude/great-bell-pprlzs`. |
| `matlab -batch "ver"` | **No disponible** (`matlab: command not found`, 2026-11-03). |
| Modo de trabajo | **"MATLAB no disponible"** (CLAUDE.md 0.2). La IA escribe los `.m` y construye los `.slx` con scripts `build_*.m`; el equipo los corre en la computadora con MATLAB y sube la salida de consola y los archivos generados. Nada se reporta como ejecutado si no hay salida real. |
| Versión de MATLAB y toolboxes | **PENDIENTE.** El equipo debe correr `ver` en su computadora y pegar la salida aquí (o subirla a `matlab_salidas/ver.txt`). Interesa: Simulink, Control System Toolbox, System Identification Toolbox, Embedded Coder, Simulink Coder, paquete de soporte Arduino/ESP32. |
| Python / visión | Pipeline en `proyecto_ControlDIP-develop/` (corre en la PC Linux del montaje). Sin ejecutar sobre el montaje real todavía. |

## 2. Etapas

| Etapa | Estado |
|---|---|
| A — Modelo de la planta | **No iniciada.** Plan propuesto en la sesión 1, pendiente de aprobación del equipo. |
| B — Identificación y validación | No iniciada |
| C — Diseño del controlador | No iniciada |
| D — MIL | No iniciada |
| E — Preparación y generación de código | No iniciada |
| F — SIL | No iniciada |
| G — PIL | No iniciada |
| H — Implementación física | No iniciada |

## 3. Parámetros conocidos (de CLAUDE.md sección 0 y `docs/`)

Ningún valor de esta tabla viene de una identificación. Las columnas de estado son las del equipo.

| Parámetro | Valor | Estado | Fuente |
|---|---|---|---|
| Plato | 300 × 300 mm, acrílico 3 mm, borde 12 mm | Construido | CLAUDE.md 0.1 |
| Rango útil del centro de la bola | ±127 mm por eje | Calculado de la geometría | CLAUDE.md 0 |
| Bola | Ø 40 mm (r = 20 mm), masa 34 g | Medido | CLAUDE.md 0.1 |
| Coeficiente de rodadura c = 1/(1 + J/(m r²)) | 5/7 ≈ 0,714 nominal; estimado 0,685–0,714 | PENDIENTE identificar (Etapa B) | CLAUDE.md 0.1 |
| Brazo del servo r | 24 mm | PROVISIONAL | CLAUDE.md 0.1 |
| Distancia centro del plato → rótula d | 70 mm (+X y +Y) | Diseñado | CLAUDE.md 0.1 |
| Relación servo → plato | ±45° servo ≈ ±14° plato; ≈0,34 °/° cerca del centro; no lineal | Calculada; verificar en el prototipo | CLAUDE.md 0 |
| Servo | Tower Pro MG90D (confirmar; `componentes.xlsx` dice MG90S). 0,10 s/60° a 4,8 V; 0,08 s/60° a 6 V; carrera ±45° | Hoja de datos | CLAUDE.md 0 |
| Tensión de alimentación de los servos | — | **PENDIENTE** (define la velocidad: 4,8 V o 6 V) | — |
| Cotas del ensamble (desde la cara superior de la base) | cara inferior del plato 215,4 mm; pivote de la junta ≈169,4 mm (aprox.); pivote de las rótulas 195,6 mm; eje de los servos 33,4 mm; distancia entre las bolas de la cadena 162,2 mm | Diseño | `docs/mecanica-decisiones-y-medidas.md` |
| Altura del centro de la bola sobre el pivote de la junta, h | ≈ 69 mm **derivado de las cotas de diseño** (215,4 + 3 + 20 − 169,4), no medido | **PROVISIONAL** — medir | cálculo a partir de `docs/` |
| Periodo de muestreo Ts | 33,3 ms nominal (30 fps, piso del hardware) | PENDIENTE medir (`run_benchmark.py --period`) | CLAUDE.md 0 |
| Latencia de extremo a extremo | estimación a priori de 60 a 90 ms + dinámica del servo | PENDIENTE medir (`run_benchmark.py --latency`) | CLAUDE.md 0 |
| Ruido de medición σ | 1 mm en `config.py` es un marcador | PENDIENTE medir (`medir_ruido.py`) | `config.py` |
| Signo de Y (`INVERT_Y`) | — | PENDIENTE verificar | `config.py` |
| Fricción de rodadura, holguras, desnivel del plato en reposo | — | PENDIENTE medir | CLAUDE.md 0.1 |
| Requisitos (ts, Mp, ess, perturbaciones, seguimiento) | — | **PENDIENTE** (enunciado o equipo) | CLAUDE.md 0 |
| Placa ESP32 exacta | — | PENDIENTE | CLAUDE.md 0 |

## 4. Decisiones pendientes

| Decisión | Afecta a | Notas |
|---|---|---|
| Salida del controlador: ángulo del plato (con la cinemática inversa en un bloque aparte) o ángulo del servo | Interfaz del modelo de la planta (A), del controlador (C, E) | Propuesta de la IA en el plan de la Etapa A. Decide el equipo. |
| Uso de la velocidad del Kalman (vx, vy) en el controlador o derivada propia | C, D, E | No bloquea la Etapa A. |
| Requisitos de desempeño | C, D | Bloquean la Etapa C, no la A. |
| Ruta PIL si el paquete de soporte no habilita PIL para ESP32 | G | Comprobar con una prueba PIL mínima antes de la Etapa G. |

## 5. Discrepancias y observaciones

1. **Enunciado oficial del proyecto final ausente.** `Intrucciones.txt` está vacío (0 bytes). Hasta tenerlo, cualquier requisito que no esté en CLAUDE.md se marca como conocimiento adicional de ingeniería (CLAUDE.md 3.2).
2. **Modelo del servo:** CLAUDE.md dice MG90D; `componentes.xlsx` dice MG90S (180°). Confirmar en la etiqueta del servo instalado: cambia la carrera real y la velocidad.
3. **Junta universal:** `componentes.xlsx` lista un cardán de 1/2″; las piezas son para 3/8″ (ya anotado por el equipo en `docs/`). Sin efecto en el modelo.
4. **README del pipeline** dice que "el PD y la cinemática inversa viven en la ESP32". La estructura del controlador **no está decidida**: se elige y justifica en la Etapa C. La frase del README es una intención previa, no una decisión del proyecto.
5. **Altura del pivote:** el centro de la bola queda unos 69 mm sobre el centro de la junta (cotas de diseño, el pivote está marcado "aprox."). Ese desplazamiento agrega al modelo un término proporcional a la aceleración angular del plato que puede introducir ceros en la función de transferencia. Hay que incluirlo en la Etapa A y cuantificar su peso; por eso conviene medir h en el prototipo.
6. **Geometría horizontal del eslabonamiento servo–plato:** `docs/` da cotas verticales y la distancia entre las bolas de la cadena (162,2 mm), pero no la posición horizontal del eje del servo respecto de la rótula. La relación ±45° → ±14° sale de la aproximación r·sen φ = d·sen θ (varilla casi vertical). Para la cinemática exacta hace falta esa cota.

## 6. Archivos generados

Ninguno todavía. El contenido del zip `Proyecto_FINAL_LAB_Control_para_ClaudeCode.zip` se copió a la raíz del repo sin cambios (sesión 1).

## 7. Orden de columnas de los CSV

Ninguno todavía.

## 8. Punto de control

```
Etapa: Inicio (sesión 1, 2026-11-03)
Completada: Sí (puesta al día y estado inicial)
Resultados obtenidos: ninguno numérico. MATLAB no disponible en la sesión.
Archivos generados: estado_proyecto.md
Datos pendientes: ver secciones 3 y 4; los de la Etapa A están en el plan de la sesión 1.
Problemas detectados: discrepancias 1 a 6 de la sección 5.
Decisiones tomadas: modo "MATLAB no disponible"; proyecto versionado en el repo Jordis17/LAB-CONTROL.
Qué debe conservarse: este archivo, CLAUDE.md, docs/.
Siguiente etapa: A — Modelo de la planta (pendiente de aprobar el plan).
```
