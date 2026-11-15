# Informe del proyecto final — plantilla en LaTeX

Mismo formato que el informe del Proyecto 1 (`referencia_proyecto1/01_informe/latex/`): IEEEtran
en dos columnas, A4, 10 pt, pdfLaTeX + BibTeX, un archivo por sección, figuras con pgfplots a
partir de CSV y el macro `\pendiente{}` para lo que falta.

## Compilar

```bash
cd informe
latexmk -pdf informe.tex
```

En Overleaf: subir la carpeta `informe/` completa (incluida `datos_graficas/`) y compilar
`informe.tex` con pdfLaTeX.

Antes de entregar: en `preambulo.tex` cambiar `\mostrarpendientestrue` por
`\mostrarpendientesfalse`, y revisar que no quede ningún recuadro rojo ni `\figpendiente`.

## Estructura

| Archivo | Sección | Estado |
|---|---|---|
| `informe.tex` | Título, autores, resumen, palabras clave | Resumen provisional; faltan carnés de Anthony y Yonaikel |
| `sec/01_introduccion.tex` | I. Introducción y requisitos R1–R4 | Completa; falta el enunciado oficial |
| `sec/02_modelado.tex` | II. Modelo físico (A), caracterización de sensor y actuador, identificación (B3), validación | Falta el modelo nominal y la figura de validación |
| `sec/03_control_mil.tex` | III. Estructura, sintonía, márgenes, ley discreta, MIL | Con el diseño original; falta decidir cómo entra el rediseño |
| `sec/04_codigo_sil.tex` | IV. Controller_BoP, inspección del código, SIL | Falta la captura de `Controller_BoP.slx` y el resumen del Advisor |
| `sec/05_pil.tex` | V. PIL propio en la ESP32 | Falta el diagrama de la arquitectura PIL |
| `sec/06_experimental.tex` | VI. Arquitectura y pruebas en el prototipo | Pruebas con el firmware de prueba; falta la Etapa H |
| `sec/07_discusion.tex` | VII. Diferencias modelo–planta | Esqueleto con las diferencias medidas |
| `sec/08_conclusiones.tex` | VIII. Conclusiones | Puntos con evidencia; falta redactar |

## De dónde sale cada número

Ningún valor se escribió sin respaldo. Las fuentes están en el `caption` de cada tabla:

- Etapa A: `etapaA/resultados/A2_consola.txt` (MATLAB R2026a).
- Cámara y mecánica: `datos_prototipo/camara/`, `datos_prototipo/mecanica/`, resumidos en
  `estado_proyecto.md`.
- Identificación B3: `etapaB/resultados/B3_consola.txt` (ensayo 151156) y las secciones de
  `estado_proyecto.md` de los demás ensayos.
- Diseño: `etapaC/resultados/C1_consola.txt`. MIL: `etapaD/resultados/D1_metricas.csv`.
- E, F y G: `etapaE/tabla_modelo_codigo.md`, `etapaF/resultados/F1_metricas.csv`,
  `etapaG/resultados/G4_resultados.csv`, `G5_metricas.csv` y `G5_consola.txt`.
- Rediseño (Discusión): `estado_proyecto.md`, "Rediseño preliminar" (cálculo en Python, todavía
  no repetido en MATLAB; está marcado como pendiente).

## Datos de las figuras (`datos_graficas/`)

Copias sin cambios de los CSV del repo, para que la carpeta compile sola (por ejemplo en
Overleaf). Si se vuelve a correr un script, hay que copiar de nuevo su CSV.

| Archivo | Origen | Figura |
|---|---|---|
| `A2_barrido_amplitud.csv` | `etapaA/resultados/` | Fig. 1 |
| `A2_comparacion_A01_lenta.csv`, `A2_comparacion_A01_rapida.csv` | `etapaA/resultados/` | Sin usar (por si se agrega la comparación en el tiempo) |
| `B3_tau.csv` | `etapaB/resultados/` (ensayo 151156) | Fig. 2 |
| `C1_bode.csv` | `etapaC/resultados/` | Sin usar (por si se agrega el Bode) |
| `D_caso_D1_requisitos.csv`, `D_caso_D2_sat_con_AW.csv` | `etapaD/resultados/` | Fig. 3 |
| `F1_comparacion.csv` | `etapaF/resultados/` | Fig. 5 |
| `G5_comparacion.csv` | `etapaG/resultados/` | Fig. 6 |
| `exp_20261113_105834.csv`, `exp_20261113_105517.csv` | **Reducidos** de `datos_prototipo/etapaB/sesion_*.csv`: t desde el inicio del log, filas con telemetría, columnas `t_s, detectada, x_mm, y_mm, rx_mm (tel_rx), ry_mm (tel_ry), thx_deg (tel_thx), thy_deg (tel_thy), modo (tel_modo)` | Fig. 7 |

## Pendientes principales (en orden)

1. Enunciado oficial del proyecto final (`Intrucciones.txt` está vacío) y su instructivo de
   formato: extensión, secciones y anexos. Eso manda sobre esta estructura (CLAUDE.md, sección 8).
2. Cerrar la Etapa B: ensayos con la mecánica definitiva, modelo nominal escrito explícitamente
   y figura de validación.
3. Rediseño en MATLAB (C1, D1) con el modelo nominal y, si cambian las ganancias, repetir E a G.
4. Etapa H con el código generado en la ESP32 y la tabla de desempeño experimental frente a MIL.
5. Captura de `Controller_BoP.slx`, diagrama PIL, foto del prototipo.
6. Resumen, discusión y conclusiones finales. Revisar la extensión (el informe del Proyecto 1
   tenía un límite de 8 a 10 páginas; hoy la plantilla tiene 8 con los recuadros).
