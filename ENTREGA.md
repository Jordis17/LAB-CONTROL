# Entrega final — Ball on Plate (EL5409, II Sem 2026)

Rama `entrega-final`, creada el 2026-11-22. Junta todo lo que había en las dos ramas de trabajo:

- `claude/lucid-ride-8oapta`: plantilla del informe, trim {1,5; 0,4}° y el integrador nuevo.
- `claude/great-bell-pprlzs`: README paso a paso y telemetría en consola, de Anthony.

Lo que falta para cerrar se termina **en esta rama**.

## 1. Qué hay y dónde

| Entregable | Dónde | Estado |
|---|---|---|
| Informe (LaTeX, IEEE dos columnas) | `informe/` (`informe.tex`, `sec/`, `datos_graficas/`, `informe.pdf`) | Plantilla con resultados de A a G; recuadros rojos `PENDIENTE` en lo que falta |
| Guía del informe (fuentes de cada número, datos de cada figura) | `informe/LEEME.md` | Al día |
| Estado del proyecto (decisiones, mediciones, discrepancias) | `estado_proyecto.md` | Al día hasta el 2026-11-18 |
| A — Modelo de la planta | `etapaA/` (scripts, `resultados/` de MATLAB R2026a) | Corrida en MATLAB |
| B — Identificación | `etapaB/` (B1, B2, B3), logs en `datos_prototipo/etapaB/` | B3 con datos reales; falta el modelo nominal definitivo |
| C — Diseño | `etapaC/` | Corrida en MATLAB (modelo del diseño) |
| D — MIL | `etapaD/` | Corrida en MATLAB (actuador medido) |
| E — Código | `etapaE/Controller_BoP.slx`, `codigo_generado/`, `tabla_modelo_codigo.md` | Cerrada (Advisor 0 Fail) |
| F — SIL | `etapaF/BoP_Test_SIL.slx`, `resultados/` | Cerrada (igualdad exacta, 271/271 muestras) |
| G — PIL | `etapaG/` (PIL propio en la ESP32) | Cerrada (igualdad exacta) |
| H — Implementación física | — | **No hecha** con el código generado |
| Firmware de trabajo (el mejor controlador medido) | `firmware/bop_controlador_estable/` | Trim e integrador del 2026-11-18, **sin probar todavía** |
| Pipeline de visión | `proyecto_ControlDIP-develop/` (README con los comandos paso a paso) | Funciona; ver la nota de la sección 4 |
| Mediciones del prototipo | `datos_prototipo/` (cámara, mecánica, logs) | — |

## 2. Compilar el informe

```bash
cd informe
latexmk -pdf informe.tex
```

En Overleaf: subir la carpeta `informe/` completa y compilar `informe.tex` con pdfLaTeX. Hoy
tiene 8 páginas. Antes de entregar, en `preambulo.tex` cambiar `\mostrarpendientestrue` por
`\mostrarpendientesfalse` y revisar que no quede ningún recuadro.

## 2b. Cumplimiento del enunciado (`Intrucciones.txt`, 2026-11-25)

| Requisito | Estado |
|---|---|
| Grupo de 4 | Sí |
| Informe escrito | Sí. Faltan los carnés de 2 integrantes |
| Prototipo funcionando | Sigue un círculo de 45 mm; los escalones no se establecen. La versión vigente del firmware (trim e integrador del 18) no se ha probado |
| Dos estrategias de control con MBD | Sí: PID con integración condicional (C1) y LQR con acción integral (C2) |
| Las dos validadas hasta MIL | Sí: D1 y D2, que corre las dos en condiciones idénticas. **Falta correr C2 y D2 en MATLAB** (hoy hay resultados de Octave) |
| Una estrategia hasta la implementación física | PID: código, SIL y PIL con igualdad exacta. En el prototipo corre un firmware escrito a mano con la misma ley |

## 3. Estado del informe (2026-11-22)

El informe quedó completo: 10 páginas, sin recuadros `PENDIENTE` y con todos los números
respaldados por un archivo del repo.

**Decisiones del equipo:**
- La sección VI reporta el firmware escrito a mano, con la misma ley, porque no se usó el código
  generado en la planta.
- No hay logs posteriores al 2026-11-18.
- Se usa el formato del Proyecto 1: IEEE a dos columnas, de 8 a 10 páginas, sin anexos.

**Lo único que falta:**
1. Nombres completos y carnés de Anthony y Yonaikel (`informe/informe.tex`, línea del
   `\author`).
2. Opcional: foto del prototipo, si cabe en la página 10.
3. Opcional: si se prueba el firmware vigente (trim e integrador del 2026-11-18), la sección VI
   dice que no se probó. Habría que actualizarla con ese log.

**Scripts nuevos del informe:**
- `informe/scripts/preparar_datos.py`: métricas de los escalones y del círculo desde los logs, y
  datos de la figura de validación.
- `informe/scripts/margenes_retardo.py`: márgenes con el modelo identificado. Su salida queda en
  `margenes_retardo_salida.txt`.

## 4. Telemetría en consola (commit `946641a` de Anthony, corregida el 2026-11-22)

Las tres líneas de telemetría de `main_vision.py` (error, PID e integrador, salida al motor)
quedaron fuera del bloque `if n % 30 == 0`. Se imprimían en cada cuadro con telemetría,
unas 25 veces por segundo, y eso podía bajar los fps del lazo.

- **Corrección:** se movieron dentro de ese bloque, así que salen una vez por segundo junto con
  la línea de posición.
- **Telemetría guardada:** usan la última telemetría válida (`tel_ultima`). Antes, si el cuadro
  30 no traía respuesta de la ESP32, se mostraba "Esperando telemetría" aunque sí estuviera
  llegando.
- **Respaldo:** la versión original de Anthony quedó en
  `proyecto_ControlDIP-develop/scripts/respaldo/main_vision_anthony_946641a.py`. También se puede
  recuperar con `git show 946641a:proyecto_ControlDIP-develop/scripts/main_vision.py`.
- El CSV no cambió.
