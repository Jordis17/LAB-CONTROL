# Verificación del informe del Proyecto 1 contra el instructivo de formato

Ejemplo de cómo se auditó el informe punto por punto contra el instructivo del curso.
Sirve como plantilla del mismo ejercicio en el proyecto final.

## Instrucciones generales

| Requisito | Estado |
|---|---|
| Formato IEEE de dos columnas | Cumple — `\documentclass[conference,a4paper,10pt]{IEEEtran}` |
| Extensión 8 a 10 páginas | Cumple — 9 páginas |
| El límite comprende todo el documento | Cumple — título, autores, resumen, texto, ecuaciones, figuras, tablas, conclusiones y referencias dentro de las 9 |
| No se permiten anexos | Cumple |
| Concentrarse en resultados, interpretación y decisiones | Cumple — no se reproduce el procedimiento de la guía |
| Configuraciones solo cuando sean necesarias | Cumple — se mencionan `ert.tlc`, C99, solver de paso fijo, `Reusable function`, `Inlined` + `ExportedGlobal`, cada una justificada |
| Figuras, tablas y ecuaciones numeradas y referenciadas | Cumple — auditado: 6 figuras, 8 tablas, 11 ecuaciones, todas referenciadas |
| Unidades en toda cantidad física | Cumple — `siunitx` con coma decimal |
| Evitar capturas de pantalla | Cumple — la única es la del modelo del controlador, que el instructivo pide |
| Cifras significativas razonables | Cumple — 3 o 4 (Kp = 7,62 en lugar de 7,620337) |

## Estructura y contenido

| Sección | Lo que pedía el instructivo | Estado |
|---|---|---|
| Resumen | Problema, metodología y resultados principales, con cifras | Cumple |
| I | Planta, problema de control, objetivo, enfoque MBD | Cumple |
| II-A | Modelo no lineal, hipótesis, modelo lineal, comparación y limitaciones | Cumple — Tabla I |
| II-B | Experimentos, señales, comparación de parámetros por datos y por método | Cumple — Tabla II, Fig. 1 |
| II-C | Validación cruzada, métricas, residuos, justificación; cierra con el modelo nominal | Cumple — Tabla III, Fig. 2 |
| III-A | Parámetros y función de transferencia del controlador; diseño alternativo y comparación | Cumple — Ec. (9), Tabla IV |
| III-B | Casos MIL, efecto del actuador y del anti-windup, verificación de especificaciones, selección justificada | Cumple — Tabla V, Fig. 3 |
| IV-A | SUT, interfaz, Ts, implementación discreta, saturación, anti-windup, figura del modelo | Captura pendiente |
| IV-B | Correspondencia modelo ↔ código, preferiblemente en tabla | Cumple — Tabla VI y un fragmento de 4 líneas |
| IV-C | Comparación Normal–SIL, métricas, criterio, diferencias como evidencia gráfica | Cumple — Ec. (11), Fig. 5 |
| V | Arquitectura PIL, qué corre en el procesador y qué sigue simulado, tabla única SIL+PIL | Cumple — Tabla VII |
| VI | Arquitectura final, adquisición y filtrado, Ts, señales, comparación con MIL y causas | Cumple — Fig. 6, Tabla VIII |
| VII | Discusión integradora, no repetitiva | Cumple |
| VIII | Entre cuatro y seis conclusiones técnicas con evidencia | Cumple — 5 |
| Referencias | IEEE, solo fuentes citadas | Cumple — 12, todas citadas, sin `\nocite` |

## Lección que vale para el proyecto final

El informe se había empezado con otro formato (una columna, 15 secciones, 29 páginas) y hubo que
rehacerlo entero cuando apareció el instructivo. **Pedir el instructivo de formato antes de
escribir una sola línea.**

## Métricas recalculadas antes de publicar

Al recalcular desde el CSV de la implementación aparecieron cinco diferencias con lo anotado a mano,
porque se habían calculado sobre ventanas distintas:

| Métrica | Anotado antes | Publicado | Definición usada |
|---|---|---|---|
| Error estacionario | 0,067 °C | 0,04 °C | ref − media de la salida para t ≥ 300 s |
| Actuación en régimen | 40,1 % | 40,3 % | media para t ≥ 300 s |
| Ganancia aparente | 0,842 | 0,84 °C/% | (media salida − salida inicial)/media actuación |
| Máximo del transitorio | 59,556 °C en t = 241 s | 59,80 °C en t = 273 s | máximo para t ≤ ts |
| Instante del mínimo de la actuación | t ≈ 150 s | t = 115 s | argmin sobre el registro |

Moraleja: recalcular desde los datos crudos y anotar con qué definición, antes de que el número
entre al informe.
