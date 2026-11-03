# Estado del proyecto — Ball on Plate (EL5409, II Sem 2026)

> Archivo vivo (CLAUDE.md, sección 6). Se actualiza al cerrar cada etapa.
> Última actualización: **2026-11-03**, sesión 1 (puesta al día, plan y scripts de la Etapa A).

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
| A — Modelo de la planta | **En curso.** Scripts escritos y probados en Octave 8.4 (preliminar). **Falta correrlos en MATLAB** y medir en el prototipo los datos de `etapaA/LEEME_etapaA.md` sección 5. |
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
| Ruido de medición σ | 1 mm en `config.py` es un marcador | PENDIENTE medir (`medir_ruido.py`) | `config.py` |
| Signo de Y (`INVERT_Y`) | — | PENDIENTE verificar | `config.py` |
| Fricción de rodadura, holguras, desnivel del plato en reposo | — | PENDIENTE medir | CLAUDE.md 0.1 |
| Requisitos (ts, Mp, ess, perturbaciones, seguimiento) | — | **PENDIENTE** (enunciado o equipo) | CLAUDE.md 0 |
| Placa ESP32 exacta | — | PENDIENTE | CLAUDE.md 0 |

## 4. Decisiones pendientes

| Decisión | Afecta a | Notas |
|---|---|---|
| Uso de la velocidad del Kalman (vx, vy) en el controlador o derivada propia | C, D, E | No bloquea la Etapa A. |
| Requisitos de desempeño | C, D | Bloquean la Etapa C, no la A. |
| Ruta PIL si el paquete de soporte no habilita PIL para ESP32 | G | Comprobar con una prueba PIL mínima antes de la Etapa G. |

**Decisiones tomadas**

| Decisión | Justificación | Fecha |
|---|---|---|
| Sin enunciado oficial por ahora. El objetivo del equipo es que el sistema funcione y documentarlo después. Los requisitos los fija el equipo cuando haga falta (Etapa C). | Indicación del equipo | 2026-11-03 |
| La salida del controlador es la **inclinación del plato** (θx, θy); la cinemática inversa va en un bloque aparte. | Propuesta de la IA; el equipo aprobó el plan con un "ok". El modelo de la planta queda casi lineal en θ y la no linealidad del mecanismo se aísla y se verifica sola. **Confirmarlo explícitamente** antes de la Etapa C. | 2026-11-03 |
| Etapa A sin toolboxes: modelo lineal y discretización escritos a mano (`bop_discretizar`). | Todavía no se conoce la instalación de MATLAB; si está Control System Toolbox, A2 compara con `c2d`. | 2026-11-03 |
| Umbral de validez del modelo lineal: error de trayectoria < 5 % de max\|x\| (decisión de ingeniería). | Ningún documento lo fija. | 2026-11-03 |
| Sin prototipo disponible por ahora: la Etapa A usa la geometría del **diseño** (artefacto "Ensamble Ball on Plate" + `docs/`) y 4,8 V para los servos. | Indicación del equipo. Las mediciones reemplazan estos valores cuando haya prototipo. | 2026-11-03 |

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

## 6. Archivos generados

| Ruta | Qué es |
|---|---|
| `etapaA/LEEME_etapaA.md` | Modelo, hipótesis, ecuaciones, método de comparación, resultados preliminares, cómo correrlo |
| `etapaA/A0_parametros_BoP.m` | Única fuente de parámetros, con unidades y estado |
| `etapaA/A1_modelo_no_lineal_BoP.m` | Geometría del neutro, cinemática servo–plato, acople del mecanismo, verificación de la dinámica, error de la cámara |
| `etapaA/A2_linealizar_BoP.m` | Modelo lineal, jacobiano, discretización, comparación lineal vs no lineal y barrido de amplitud |
| `etapaA/funciones/` | Dinámica, medición, cinemáticas, perfil de prueba, discretización, métricas y CSV |
| `etapaA/resultados/` | **Todavía no existe en el repo.** Lo genera MATLAB al correr A1 y A2. |

El contenido del zip `Proyecto_FINAL_LAB_Control_para_ClaudeCode.zip` se copió a la raíz del repo sin cambios (sesión 1).

## 7. Orden de columnas de los CSV

En `etapaA/orden_csv.md`.

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
