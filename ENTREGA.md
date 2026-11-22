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

## 3. Qué falta para terminar el informe (en orden)

1. **Enunciado y formato.** Confirmar con el profesor la extensión, las secciones y si se
   permiten anexos. El del Proyecto 1 pedía de 8 a 10 páginas, sin anexos. Si el enunciado
   final trae requisitos, reemplazar R1–R4 (sección I).
2. **Prueba con el firmware vigente** (`bop_controlador_estable`, trim e integrador nuevos), en
   modo centro: soltar la bola quieta en 3 o 4 puntos, 15 s en cada uno. Con ese log:
   - confirmar o afinar el trim;
   - completar la tabla de desempeño experimental de la sección VI, con las mismas definiciones
     de ts, Mp y ess.
3. **Decidir qué se reporta como Etapa H.** Hay dos opciones:
   - integrar `etapaE/codigo_generado` en el firmware y repetir los ensayos;
   - si no da el tiempo, declarar en el informe que la implementación física usó el firmware
     escrito a mano con la misma ley (es lo que dice hoy la sección VI) y explicar la diferencia.
4. **Modelo nominal (sección II-D):** escribirlo explícitamente con los parámetros de B3 y
   agregar la figura de validación desde `etapaB/resultados/B3_validacion.csv`.
5. **Figuras que faltan:**
   - captura de `etapaE/Controller_BoP.slx`, exportada desde MATLAB con
     `print('-sController_BoP','-dpdf')` y guardada en `informe/figuras/`;
   - diagrama de la arquitectura PIL;
   - foto del prototipo.
6. **Datos que faltan:**
   - carnés y nombres completos de Anthony y Yonaikel;
   - resumen de las 5 advertencias del Advisor;
   - URL de la referencia de PIL de MathWorks en `referencias.bib`.
7. **Resumen, discusión y conclusiones finales** con lo que salga de los puntos 2 y 3.

Cada número nuevo que entre al informe tiene que salir de un archivo del repo (log, CSV o
consola). No pegar valores a mano sin su fuente (CLAUDE.md, secciones 3.1 y 9).

## 4. Nota sobre la telemetría en consola (commit `946641a`)

Las tres líneas nuevas de `main_vision.py`, con el error, el PID y la salida al motor, quedaron
**fuera** del bloque `if n % 30 == 0`. Se imprimen en cada cuadro que trae telemetría (≈ 25 veces
por segundo), y "Esperando telemetría..." en los demás. Imprimir tanto puede bajar los fps del
lazo. Si la intención era verlas una vez por segundo como el resto, hay que indentarlas dentro
de ese bloque. No se cambió, porque es código del equipo.
