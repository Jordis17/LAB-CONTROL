# CLAUDE.md — Proyecto final: diseño, verificación e implementación del controlador

> Guardar este archivo en la raíz de la carpeta del proyecto para Claude Code.
> El mismo texto sirve pegado en Configuración del proyecto → Instrucciones, en claude.ai.

---

# 0. Datos de la planta

**Esta sección la llenó el equipo con lo que ya está decidido o construido (actualizada el
2026-11-02).** Los campos marcados **PENDIENTE** todavía no tienen un valor real. Mientras un
campo necesario para una etapa siga PENDIENTE, la IA debe pedirlo, o proponer la prueba que lo
determina, antes de avanzar. **No debe rellenarlo por inferencia.** Los valores marcados
**PROVISIONAL** salen del diseño, no de una medición, y hay que confirmarlos antes de usarlos
como definitivos.

| Campo | Valor |
|---|---|
| Planta / sistema | **Ball on Plate de 2 grados de libertad.** Una bola rueda sobre un plato cuadrado de acrílico. El plato se inclina en dos ejes (X, Y) sobre un pivote central (junta universal de 3/8″) y lo mueven dos servos mediante varillas de empuje. El sensor es una cámara cenital. Proyecto final del Laboratorio de Control Automático (ITCR, II Sem 2026). Equipo: Abner López, Jordi Segura, Anthony Villalta, Yonaikel Tencio. |
| Variable(s) controlada(s) y unidades | Posición del centro de la bola sobre el plato, **x e y en mm**. El origen está en el centro del plato. El rango útil es **±127 mm** por eje, no ±150, porque el borde de 3 mm y el radio de la bola (20 mm) reducen el área disponible. |
| Variable(s) manipulada(s) y unidades | Inclinación del plato **θx y θy en grados**. Cada una se produce con el ángulo de un servo (en grados) a través de la cinemática inversa del mecanismo. **PENDIENTE decidir** si la salida del controlador es el ángulo del plato (con la cinemática inversa en un bloque aparte) o directamente el ángulo del servo. Esto define la interfaz del modelo del controlador en la Etapa E. |
| Sensor y cómo se mide | Cámara web USB cenital sobre un pórtico: **Redragon Fobos GW600** (corregido por el equipo el 2026-11-03; antes decía Hitman GW800). **Especificaciones** (fichas de tiendas, no hay hoja de datos oficial de Redragon): 720p, máximo 1296 × 732 (algunas fichas dicen 1280 × 720) a **30 fps como máximo**, **FOV diagonal de 68,6°** (una ficha dice 110°, que parece un error), **foco fijo de 50 cm a infinito**, USB 2.0. La ficha no dice qué formatos ofrece (MJPG/YUYV), si tiene modo de 640×480 ni cómo lo obtiene (recorte o escalado), ni si deja fijar la exposición. **Consecuencias para el proyecto** (cálculo, no medición): (1) no hay modo de más de 30 fps, así que Ts ≥ 33,3 ms es un piso del hardware (igual que con la cámara anterior); (2) a 450 mm, con el sensor completo en 16:9, el campo es de unos **535 × 301 mm**: en el eje vertical de la imagen queda **medio milímetro de margen** sobre el plato de 300 mm. Si el modo de 640×480 es un recorte central del sensor de 1280×720, el campo baja a unos 268 × 201 mm y **el plato no entra**. Para tener unos 20 mm de margen por lado haría falta subir la cámara a unos 500 mm (334 mm de campo vertical); eso cambia `CAMERA_HEIGHT_MM` y la corrección de paralaje. **Verificar primero** que las cuatro marcas y todo el borde salen en la imagen con la resolución configurada. (3) El plato a 450 mm queda un poco más cerca que el foco mínimo de 50 cm: revisar la nitidez, aunque al centroide le afecta poco un desenfoque leve. (4) Resolución esperada de unos 0,63 mm/px en el eje vertical a 480 px, si la imagen es el sensor completo escalado. (5) Hay que comprobar que la cámara deja fijar la exposición y el balance de blancos por v4l2 (`v4l2_config.py` lo verifica). Si no lo permite, la calibración de color no es estable. Montaje: Altura del lente sobre la **cara superior del plato** (plato en horizontal): **450 mm (CONFIRMADO por el equipo)**. Es la referencia de `CAMERA_HEIGHT_MM` en `config.py` y de la corrección de paralaje. Resolución de 640×480, MJPG, exposición fija de 5 ms, balance de blancos fijo de 4600 K. Corre en una PC con Linux y Python/OpenCV (repo `proyecto_ControlDIP-develop`). Cadena: captura → homografía de píxeles a mm sobre el cuadrado de 290 mm que forman las esquinas exteriores de las marcas grabadas → segmentación HSV de la bola (verde lima mate sobre acrílico vino) con filtro por área y circularidad → corrección de paralaje (×0,956) → **filtro de Kalman** de velocidad constante con dt variable → estado **(x, y, vx, vy)** en mm y mm/s. Se envía a la ESP32 por serial a 921600 baud en una trama binaria de 20 bytes (ver README del repo). Ruido de medición: **PENDIENTE medir** con `scripts/medir_ruido.py`. El valor de `config.py` (1 mm) es un marcador, no una medición. Signo del eje Y: **PENDIENTE verificar** (`INVERT_Y`). |
| Actuador y sus límites físicos | **2 servos Tower Pro MG90D** (digitales, engranaje metálico), uno por eje. En `componentes.xlsx` aparece el MG90S; confirmar el modelo instalado. **Hoja de datos** (Adafruit, producto 1143): torque 2,1 kg·cm a 4,8 V / 2,4 kg·cm a 6 V; velocidad **0,10 s/60° a 4,8 V** / 0,08 s/60° a 6 V; alimentación de 4,8 a 6 V; **carrera de unos 90° en total (±45°)**; pulso ≈1,5 ms en el centro, ≈1 ms / ≈2 ms en los extremos nominales, con pulsos de 0,75 a 2,25 ms para recorrido completo. Banda muerta: la hoja no la especifica. **Consecuencia:** el ±45° del diseño coincide con el límite físico del servo, así que la saturación del actuador es real y entra en el modelo desde MIL. **Relación servo–plato (calculada con la geometría del diseño):** brazo r = 24 mm, d = 70 mm, ±45° de servo ≈ **±14° de plato**, ≈0,34° de plato por grado de servo cerca del centro, no lineal hacia los extremos. Se usa como valor nominal en la Etapa A y se **verifica en el prototipo** midiendo el ángulo del plato para algunos comandos del servo, por la holgura de rótulas y ball links. |
| Periodo de muestreo `Ts` y de dónde sale | Lo fija el **frame rate de la cámara**, no es una elección libre. Nominal: 30 fps (configurado en `config.py`) → **Ts ≈ 33,3 ms**. Usar ese valor en el diseño hasta tener la medición. Cámara Redragon GW800: la hoja de datos da **30 fps como máximo**, que es un **piso de Ts ≥ 33,3 ms**. No da el periodo real con la exposición fija y la carga de procesamiento, ni su jitter: eso se mide. **PENDIENTE medir** el periodo real y su jitter con `scripts/run_benchmark.py --period` (criterio: 95 % de los periodos dentro de ±5 ms) y decidir entre MJPG y YUYV. |
| Retardo esperado de la cadena de medición | **PENDIENTE medir** con `scripts/run_benchmark.py --latency`. Criterio de viabilidad fijado por el equipo: latencia media de extremo a extremo **< 60 ms**. Componentes del retardo: exposición, transferencia USB, procesamiento, transmisión serial y periodo de cálculo en la ESP32, más la respuesta del servo. Todo esto es tiempo muerto en el lazo y hay que modelarlo. **Estimación a priori (no medida), para empezar la Etapa A:** exposición de 5 ms + entre 1 y 2 periodos de cámara por buffer y procesamiento (33 a 67 ms) + serial menor a 1 ms + 1 periodo de cálculo y PWM del servo (20 ms) → **del orden de 60 a 90 ms**, más la dinámica del servo: un cambio de 10° de servo tarda unos 17 ms a 4,8 V según la hoja de datos. La medición con `--latency` reemplaza esta estimación. |
| Hardware objetivo de la implementación | **ESP32**: recibe el estado por serial y ejecuta el controlador, la cinemática inversa y la generación de PWM de los servos. La visión y el Kalman corren en la PC Linux con prioridad de tiempo real (`chrt`). Modelo exacto de la placa ESP32: **PENDIENTE**. Firmware de la ESP32: **todavía no existe**. Debe incluir un watchdog que lleve los servos a neutro si no llegan tramas en unos 200 ms, y llevar el plato a horizontal cuando `estado = 0`. |
| Hardware objetivo para PIL (si es distinto) | El mismo: **ESP32**. Según MathWorks, el *Simulink Support Package for Arduino Hardware* programa placas ESP32 **desde R2022a**, y PIL requiere además **Embedded Coder**. La página no aclara si PIL está habilitado para ESP32: **PENDIENTE comprobar** en la computadora con MATLAB (versión ≥ R2022a, paquete instalado, ESP32 en la lista de *hardware boards* con PIL) con una prueba PIL mínima antes de la Etapa G. Si no lo soporta, hay que definir otra ruta y justificarla antes de la Etapa G. |
| Requisito de tiempo de establecimiento | **PENDIENTE.** Lo define el documento del curso o el equipo. |
| Requisito de sobreimpulso | **PENDIENTE.** Lo define el documento del curso o el equipo. |
| Otros requisitos (error estacionario, esfuerzo, seguridad) | **PENDIENTE** (error estacionario, rechazo de perturbaciones, seguimiento de trayectorias). Restricciones físicas conocidas: la bola nunca debe salir de ±127 mm; inclinación limitada a unos ±14° (PROVISIONAL); la ESP32 debe llevar el plato a horizontal ante pérdida de bola o de comunicación. |
| Documento oficial del curso que rige el trabajo | Curso: **EL5409 – Laboratorio de Control Automático** (Prof. Juan Luis Guerrero Fernández, II Sem 2026). Enunciado del proyecto final: **PENDIENTE**. El equipo debe adjuntarlo (`Intrucciones.txt` está vacío). Como referencia de método y de formato están la guía del Proyecto 1 y el instructivo del informe en `referencia_proyecto1/04_matlab_simulink/guias/`, pero **no son el documento del proyecto final**. Lo que diga esa guía no es un requisito aquí salvo que el enunciado nuevo lo repita. |

## 0.1 Parámetros físicos conocidos

| Parámetro | Valor | Estado |
|---|---|---|
| Plato | 300 × 300 mm, acrílico de 3 mm, color vino translúcido; borde de 12 mm de alto | Construido |
| Bola | Impresa en 3D en PLA verde lima mate, Ø 40 mm, 90 % de relleno, **masa medida 34 g** | Medido |
| Coeficiente de inercia de rodadura | 5/7 (esfera maciza) como punto de partida; por la distribución del relleno se estima entre 0,685 y 0,714 | **PENDIENTE identificar** con un experimento |
| Pivote central | Junta universal de 3/8″ (60 mm) sobre una extensión de 6″; largo nominal de la columna 200,4 mm | Diseñado |
| Brazo del servo | r = 24 mm | PROVISIONAL |
| Distancia del centro del plato a la rótula | d = 70 mm, sobre +X y +Y | Diseñado |
| Varillas de empuje | Ø 8 × 120 mm, impresas | Diseñado |
| Eje del servo sobre la base | 33,4 mm nominal (ajustable de 29,4 a 37,4) | Ajustable |
| Fricción de rodadura, holgura del mecanismo, desalineación del plato en reposo | — | **PENDIENTE medir** |

## 0.2 Estado del proyecto al iniciar

**Entorno de trabajo.** MATLAB y Simulink están instalados en **una computadora del equipo**.
Claude Code puede correr en esa computadora o en la nube. Al iniciar la primera sesión, la IA
comprueba con `matlab -batch "ver"` si MATLAB responde desde su terminal, anota el resultado en
`estado_proyecto.md` y trabaja según el caso:

- **MATLAB disponible** (Claude Code en la computadora con MATLAB): la IA escribe, ejecuta y
  revisa los scripts y modelos directamente. Anota la versión y los toolboxes (Simulink,
  Embedded Coder, Control System Toolbox, System Identification Toolbox, paquete de soporte
  para ESP32/Arduino).
- **MATLAB no disponible** (Claude Code en la nube): la IA **no** finge haber ejecutado nada.
  Escribe los `.m` y construye los `.slx` **mediante scripts** (`build_*.m` con `new_system`,
  `add_block`, `add_line`, `set_param`), porque un `.slx` no se puede revisar sin MATLAB. Dice
  exactamente qué correr en la computadora con MATLAB y en qué orden. Cada script debe imprimir
  en consola lo necesario para el análisis y guardar sus resultados en `.mat` y `.csv` con
  nombres fijos. El equipo corre los scripts, sube a la carpeta la salida de consola y los
  archivos generados, y la IA los analiza. Con esta modalidad, conviene agrupar el trabajo en
  pocos scripts por etapa para reducir las vueltas.

Las mediciones de la cámara (scripts de `proyecto_ControlDIP-develop`) corren en la PC con
Linux; sus CSV se copian a esta carpeta.

**Mapa de la carpeta** (leer al iniciar cada sesión):

| Ruta | Qué es |
|---|---|
| `CLAUDE.md` | Este archivo: reglas de trabajo y datos de la planta. |
| `estado_proyecto.md` | Estado vivo del proyecto (Sección 6). Si no existe, crearlo en la primera sesión. |
| `docs/mecanica-decisiones-y-medidas.md` | Detalle mecánico completo: geometría, cotas del ensamble, tornillería, pendientes y riesgos. |
| `proyecto_ControlDIP-develop/` | Pipeline de visión, Kalman y serial en Python (versión vigente). |
| `proyecto_ControlDIP-ORIGINAL-backup/` | Versión anterior del pipeline. Solo de referencia, no se modifica. |
| `referencia_proyecto1/` | Proyecto 1 (TCLab) completo. Solo referencia de método y formato (ver 3.4). |
| `componentes.xlsx` | Lista inicial de compras. Algunas entradas están desactualizadas (servo MG90S, cardán de 1/2″). |


- **Mecánica:** prototipo **totalmente ensamblado** (confirmado el 2026-11-02). Ya se pueden
  medir sobre el montaje real las magnitudes que siguen marcadas como PROVISIONAL o PENDIENTE:
  brazo efectivo del servo, verificación de la relación entre ángulo de servo y ángulo de plato,
  holguras y desnivel del plato en reposo.
- **Visión y comunicación:** el pipeline en Python está escrito y tiene pruebas unitarias
  (`proyecto_ControlDIP-develop`). Aún **no** se han ejecutado las caracterizaciones de
  periodo, latencia y ruido sobre el montaje real, así que no hay CSV en `logs/`.
  `proyecto_ControlDIP-ORIGINAL-backup` es una versión anterior y es solo de referencia.
- **Controlador, cinemática inversa y firmware de la ESP32:** no existen todavía. El trabajo
  con la IA empieza en la **Etapa A** (modelo de la planta).
- **Advertencias para la Etapa A** (ver 3.3): la planta **no** es como la del Proyecto 1.
  Bola sobre plato inclinado: lo esperable es una planta de tipo integrador o doble
  integrador, no estable en lazo abierto. Hay dos ejes acoplados en el caso general que
  normalmente se tratan como dos SISO desacoplados bajo ciertas hipótesis, y esas hipótesis
  hay que verificarlas. Un escalón en lazo abierto no es viable. SIMC no aplica. Hay que
  demostrar todo esto en la Etapa A, no asumirlo.
- **Decisión de arquitectura PENDIENTE:** el Kalman ya entrega la velocidad (vx, vy). Hay que
  decidir si el controlador la usa directamente (por ejemplo, como término derivativo o en
  una realimentación de estados) o si deriva la posición por su cuenta. Esto afecta la
  interfaz del controlador, el retardo efectivo y la comparación MIL frente a planta real.

---

# 1. Objetivo

Diseñar un controlador para la planta de la Sección 0 y someterlo al mismo flujo de
**Model-Based Design** que se aplicó en el Proyecto 1, porque el profesor lo pidió
explícitamente:

```
modelado → identificación → diseño → MIL → generación de código → SIL → PIL → implementación física
```

El objetivo no es solo que el controlador funcione en simulación, sino recorrer el flujo
completo conservando trazabilidad entre requisitos, modelo, diseño, pruebas, datos y
resultados.

---

# 2. Rol de la IA

Desarrolla el controlador junto con el equipo y trabaja directamente en MATLAB y Simulink
durante todo el proyecto. Debe:

1. desarrollar el modelo de la planta, el diseño del controlador y su implementación;
2. escribir los scripts de MATLAB (`.m`) y construir o modificar los modelos de Simulink
   (`.slx`), por ejemplo por script con `new_system`, `add_block`, `add_line` y `set_param`;
3. ejecutar MATLAB y Simulink cuando estén disponibles en la máquina (por ejemplo con
   `matlab -batch "script"`), leer la salida y los archivos generados (`.mat`, `.csv`,
   gráficas, código generado) y analizarlos;
4. explicar qué pide cada etapa, qué conceptos hacen falta y por qué se hace cada cosa, para
   que el equipo entienda y pueda defender el trabajo;
5. decir exactamente qué datos hay que obtener y conservar, sobre todo los que solo se pueden
   medir en el prototipo físico;
6. revisar los resultados: coherencia matemática y física, unidades, signos, magnitudes,
   comportamiento de las gráficas, cumplimiento de requisitos;
7. detectar discrepancias y analizar sus causas;
8. justificar técnicamente cada decisión;
9. mantener el registro ordenado de resultados;
10. ayudar después con el informe.

Si MATLAB no se puede ejecutar desde la sesión (no está instalado en la máquina, falta la
licencia o un toolbox, o el paso necesita una interfaz gráfica o hardware conectado), la IA
deja listo el script o el modelo, dice exactamente qué correr y analiza la salida que le
entregue el equipo. Los experimentos sobre la planta real los hace el equipo con el
prototipo; la IA prepara los scripts de adquisición y analiza los datos.

---

# 3. Reglas fundamentales

## 3.1 No inventar

**Nunca inventar resultados experimentales, valores de MATLAB, parámetros identificados,
métricas de desempeño, resultados SIL/PIL ni datos de la planta.**

Si una etapa necesita un resultado que la IA no puede obtener ejecutándolo ella misma (por
ejemplo, una medición en el prototipo), se detiene y lo pide de forma específica: qué script, qué variable, qué valor, qué mensaje de consola.

Ejemplo de cómo pedirlo:

> Para seguir necesito los parámetros que entregó la identificación y la gráfica de
> validación. No voy a asumir esos valores.

## 3.2 Seguir el documento oficial del curso

Cuando haya que tomar una decisión: primero qué dice el documento, después cómo aplica, y
solo al final conocimiento adicional de ingeniería para interpretar.

Si existe una alternativa válida que no aparece en el documento, marcarla como:

> **Alternativa de ingeniería:** ...

Si el documento no cubre el punto, decirlo explícitamente:

> **El documento no especifica este punto. A partir de aquí uso conocimiento adicional de
> ingeniería.**

Nunca presentar una inferencia como si fuera un requisito del curso.

## 3.3 No adaptar a la fuerza lo del Proyecto 1

El Proyecto 1 fue una planta térmica SISO, estable en lazo abierto, de primer orden con
tiempo muerto, y se usaron las reglas SIMC. **Nada de eso se traslada automáticamente.**

Antes de reusar un método del Proyecto 1, la IA debe comprobar que las hipótesis se cumplen
en esta planta y decirlo. En particular:

- **SIMC solo aplica a plantas estables de tipo FOPDT.** Si la planta es inestable en lazo
  abierto, integradora, de orden superior o MIMO, hay que elegir otro método y justificarlo.
- **Un PI no estabiliza una planta inestable en lazo abierto.** Si ese es el caso, el diseño
  necesita acción derivativa, estructura en cascada, o realimentación de estados con
  observador.
- **Un ensayo escalón en lazo abierto puede no ser posible** si la planta se va a los límites
  sin control. Entonces la identificación se hace desde la física y se valida en lazo cerrado.
- **El periodo de muestreo puede no ser libre.** Si lo fija un sensor (frame rate de una
  cámara, por ejemplo), eso es un dato, no una elección, y su latencia es tiempo muerto.

Lo que **sí** se reusa sin cambios es la estructura del flujo, los criterios de evidencia, la
disciplina de verificación y el formato del informe.

## 3.4 Referencia del Proyecto 1 (`referencia_proyecto1/`)

La carpeta `referencia_proyecto1/` tiene lo que se hizo en el Proyecto 1 (TCLab): el informe
en LaTeX, los scripts `.m`, los modelos `.slx`, el código generado, los `.mat` y las dos guías
del curso (`04_matlab_simulink/guias/`). El índice está en `referencia_proyecto1/LEEME_PRIMERO.md`.

**Es solo una referencia de cómo se trabajó**, no una lista de tareas para el proyecto final.

- **Lo obligatorio en el proyecto final** son las etapas de la Sección 4, que incluyen MIL, SIL y
  PIL, más lo que pida el documento oficial del proyecto final cuando el equipo lo entregue.
- **No hay que repetir cada actividad del Proyecto 1.** Cosas como el ensayo multinivel, el
  diseño alternativo con Control System Designer, la comparación con System Identification
  Toolbox, los tres casos de saturación o las pruebas A3 del hardware se hacen **solo si
  aplican a esta planta o si el documento del proyecto final las pide**. Antes de proponer una,
  la IA dice por qué aporta algo aquí.
- **Sí conviene reusar:** la organización de archivos y nombres, el formato de los scripts
  (parametrización, salida en consola, guardado de `.mat`), la separación
  `Controller.slx` / bancos `Test_SIL` y `Test_PIL` separados / copia para implementación, los
  scripts de comparación Normal–SIL y Normal–PIL como plantilla, la configuración de generación
  de código como punto de partida (cambiando el hardware a la ESP32), y la estructura y estilo
  del informe.
- **Ningún valor numérico** de esa carpeta aplica (K, τ, θ, ganancias, métricas). No se reusan,
  no se toman como punto de partida y no se ajustan los nuevos para que se parezcan.
- `referencia_proyecto1/` no se modifica. Si se toma un archivo como base, se copia a la
  carpeta de trabajo del proyecto final con otro nombre.

---

# 4. Etapas

Trabajar **una etapa a la vez**, en orden, sin avanzar hasta que la anterior esté verificada.

## Etapa A — Modelo de la planta

- Plantear el modelo físico a partir de primeros principios, con las hipótesis explícitas.
- Identificar qué es no lineal y por qué.
- Linealizar alrededor del punto de operación y escribir la función de transferencia o el
  modelo en espacio de estados, con valores numéricos y unidades.
- Cuantificar el error de la aproximación lineal frente al modelo no lineal, para al menos
  dos amplitudes de perturbación, y delimitar en qué rango es válida.

**Conservar:** ecuaciones, hipótesis, parámetros con unidades, punto de operación, modelo
lineal, error de la aproximación, CSV de las simulaciones.

## Etapa B — Identificación y validación del modelo

- Definir qué experimentos son **físicamente posibles** en esta planta (ver 3.3).
- Registrar para cada ensayo: entrada aplicada, salida, tiempo, condiciones iniciales,
  duración, número de muestras y cualquier observación.
- Identificar el modelo y reportar sus parámetros con unidades.
- **Validar con datos distintos de los usados para identificar.** Reportar métricas (RMSE,
  MAE, sesgo, R², ajuste) y analizar la **estructura temporal del residuo**, no solo su
  magnitud: un residuo con patrón indica qué parte del modelo falla.
- Seleccionar el modelo nominal y justificarlo con los resultados reales. No promediar
  parámetros de modelos distintos.

**Conservar:** datos crudos, modelos, parámetros, métricas, residuos, modelo nominal escrito
explícitamente, archivos `.mat`.

## Etapa C — Diseño del controlador

- Elegir la estructura del controlador y **justificar por qué esa y no otra**, a partir de la
  dinámica de la planta (ver 3.3).
- Elegir el método de sintonización y justificarlo igual.
- Reportar los parámetros con unidades y la función de transferencia del controlador con
  valores numéricos.
- Reportar márgenes de estabilidad: frecuencia de cruce, margen de fase, margen de ganancia.
- Escribir la implementación discreta explícita (ley de actualización del estado y salida) y
  distinguir la ganancia continua del incremento por muestra.
- Si el curso pide un **diseño alternativo** por otro método, debe ser una estrategia
  realmente distinta, no la misma fórmula dentro de otra herramienta. Comparar ambos bajo
  condiciones idénticas.

**Conservar:** parámetros, función de transferencia, márgenes, criterio de diseño, archivo
`.mat` con todo.

## Etapa D — MIL (Model-in-the-Loop)

- Evaluar el controlador contra el modelo de la planta.
- Incluir **las restricciones reales del actuador**. Un controlador evaluado sin saturación no
  dice nada sobre su comportamiento real.
- Evaluar el efecto de la saturación. Si el controlador tiene acción integral, comparar con y
  sin protección del integrador (anti-windup u otra), como en el Proyecto 1. Si no la tiene, ese
  caso no aplica y se dice. Toda comparación se hace bajo la **misma** referencia, planta,
  condición inicial, `Ts`, configuración numérica y tiempo de simulación.
- Reportar: tiempo de subida, tiempo de establecimiento, sobreimpulso, error estacionario,
  valor extremo de la salida, mínimo y máximo de la acción de control, y tiempo en saturación.
- **Verificar explícitamente el cumplimiento de los requisitos.** Que el método de diseño se
  haya aplicado bien no demuestra por sí solo que se cumplan.
- Explicar el mecanismo detrás de cada diferencia observada, no solo describir las curvas.

**Conservar:** modelo, métricas, gráficas, CSV, comparación entre configuraciones.

## Etapa E — Preparación y generación de código

- Separar el controlador de la planta en su propio modelo. **La planta no va adentro.** Esa
  separación es lo que permite generar código solo del algoritmo e instanciarlo en un banco de
  pruebas.
- Dejar el modelo del controlador como **referencia intocable** del resto de la verificación.
  Cualquier variante posterior es una copia con otro nombre.
- Definir la interfaz: qué entra, qué sale, en qué unidades.
- Documentar solo las configuraciones de generación de código que hagan falta para entender la
  implementación.
- Correr los Advisors. Criterio: **cero resultados Fail**; las advertencias se revisan y se
  justifican. **No usar `Fix All` ni modificaciones automáticas solo para que desaparezcan.**
- Comprobar que la preparación no alteró el comportamiento validado en MIL.
- Inspeccionar el código generado y verificar que conserve: interfaz, estado interno,
  parámetros calibrables, saturación, lógica de protección del integrador, tipos de dato, y la
  ausencia de la planta.

**Conservar:** modelo del controlador, código generado, resultados de los Advisors, tabla de
correspondencia modelo ↔ código.

## Etapa F — SIL

- Banco de pruebas con dos ramas, Normal y SIL, dentro de una misma simulación, compartiendo
  referencia, planta, condiciones iniciales, `Ts` y tiempo de simulación.
- Cada rama con su propia copia de la planta, porque las acciones de control se calculan
  independientemente.
- Comparar **muestra a muestra**. Reportar máximo absoluto de la diferencia, RMSE e igualdad
  exacta, para cada señal.
- Usar las diferencias (`señal_SIL − señal_Normal`) como evidencia gráfica.
- **Que el código compile no demuestra nada.** El criterio es la equivalencia numérica.
- Concluir qué verifica SIL y qué no.

## Etapa G — PIL

- Misma estructura de dos ramas, Normal y PIL, en un banco **separado** del de SIL.
- No mantener simultáneamente una instancia SIL y una PIL del mismo modelo.
- Documentar con precisión **qué se ejecuta en el procesador físico y qué sigue simulado**.
- Conservar la estructura algorítmica y los parámetros sin cambios respecto de lo validado.
- Reportar las mismas métricas de diferencia que en SIL.
- Concluir qué evidencia adicional aporta PIL sobre SIL, y por qué un PASS todavía no es una
  validación sobre la planta real.

## Etapa H — Implementación física

- Copia del controlador para implementación; el original se conserva.
- Ajustar solo la representación numérica que exija el hardware, sin tocar el algoritmo.
- Documentar la cadena completa: adquisición → conversión → filtrado → controlador →
  limitación → actuación.
- Lista de comprobación de seguridad antes de energizar.
- Registrar las señales del experimento.
- Comparar con MIL y **analizar las diferencias sin ocultarlas ni corregirlas
  artificialmente**: incertidumbre del modelo, dinámica no modelada, perturbaciones, ruido,
  cuantización, limitaciones del actuador, variaciones ambientales, efectos de implementación.

---

# 5. Interpretación de PASS / FAIL

Un PASS significa únicamente que se cumplió **ese** criterio de verificación.

- PASS en SIL → el código generado es consistente con el modelo bajo las condiciones evaluadas.
- PASS en PIL → el código puede ejecutarse en el procesador objetivo conservando el comportamiento.
- Ninguno de los dos sustituye la validación experimental sobre la planta real.

Si una comparación da FAIL, **no se cierra la etapa** hasta identificar la causa.

---

# 6. Trazabilidad y archivo de estado

Mantener en el proyecto un archivo `estado_proyecto.md`, actualizado al cerrar cada etapa, con:

- parámetros del modelo y del controlador,
- condiciones experimentales,
- métricas obtenidas,
- decisiones tomadas y su justificación,
- discrepancias detectadas,
- archivos generados y dónde están,
- orden de columnas de cada CSV.

Es lo que permite que una sesión nueva se ponga al día leyendo un archivo, en vez de
reconstruir todo el historial.

## Punto de control al cerrar cada etapa

```
Etapa: ...
Completada: Sí / No
Resultados obtenidos: ...
Archivos generados: ...
Datos pendientes: ...
Problemas detectados: ...
Decisiones tomadas: ...
Qué debe conservarse: ...
Siguiente etapa: ...
```

---

# 7. Manejo de errores y resultados inesperados

**Ante un error de MATLAB o Simulink:** pedir el mensaje completo si no está, identificar
archivo y línea, explicar qué significa, determinar si es configuración, código, hardware o
datos, proponer la corrección mínima, verificar que no contradiga el documento del curso, y
recién entonces volver a ejecutar. **No cambiar varias cosas a la vez.**

**Ante un resultado que no coincide con lo esperado:** no ajustar el resultado para que cuadre
con la teoría. Revisar primero parámetros, unidades, condiciones iniciales, punto de
operación, signos, periodo de muestreo, retardo, saturación, configuración del solver, datos y
nombres de variables. Después analizar causas físicas o matemáticas.

---

# 8. Informe

El informe debe poder responder, con evidencia: cuál era el problema de control, cuál la
planta, qué modelo se usó y cómo se obtuvo, por qué se eligió el nominal, cómo se validó, por
qué esa estructura de controlador, cómo se calcularon sus parámetros, qué desempeño tuvo en
MIL, qué efecto tuvieron la saturación y la protección del integrador, cómo se comportó el
diseño alternativo, cuál se seleccionó y por qué, qué resultó en SIL y en PIL, qué se ejecutó
físicamente en PIL, qué pasó en la implementación, qué diferencias hubo entre modelo y planta
real, si se cumplieron los requisitos, qué limitaciones tuvieron el modelo y la
implementación, y qué evidencia respalda cada conclusión.

**Estilo:** redacción de estudiante universitario de Ingeniería Electrónica. Natural, sin
lenguaje recargado ni frases que suenen automáticas. No exagerar conclusiones. Diferenciar
resultados de interpretaciones. Mantener los nombres de variables y archivos del curso.
Unidades correctas. Coherencia entre texto, tablas y gráficas. Cantidad razonable de cifras
significativas.

**Antes de escribir el informe, revisar si el curso entregó un instructivo de formato** —
extensión, estructura de secciones, dos columnas, anexos permitidos. Eso manda sobre cualquier
estructura que se haya planeado antes.

---

# 9. Lecciones del Proyecto 1 que conviene no repetir

- **Recalcular las métricas desde los datos crudos** antes de ponerlas en el informe, y anotar
  al lado con qué definición se calcularon. En el Proyecto 1, cinco valores anotados a mano no
  reproducían los CSV porque se habían calculado sobre ventanas distintas.
- **Fijar una sola definición** de tiempo de establecimiento, sobreimpulso y error estacionario
  para todo el proyecto, y usarla en simulación y en experimento. Si no, las comparaciones no
  significan nada.
- **Los datos crudos van a CSV en la carpeta del proyecto, no pegados en el chat.**
- **Verificar las hipótesis de una herramienta de identificación antes de creerle el
  resultado.** Un estimador puede converger a un número perfectamente plausible y equivocado
  si se le entregan los datos en la forma incorrecta.
- **Una sesión por etapa.** Al cerrar una etapa, actualizar `estado_proyecto.md` y abrir sesión
  nueva.

---

# 10. Regla principal

> documento del curso → datos reales obtenidos → análisis → decisión → siguiente etapa

Nunca:

> suposición → resultado inventado → conclusión

Cada resultado debe poder relacionarse con una ejecución real, un archivo, una medición, una
simulación o una decisión documentada.
