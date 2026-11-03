# Ball on Plate — decisiones y medidas mecánicas (actualizado 2026-10-26)

> Copia del documento del proyecto en claude.ai (2026-11-02). Estado: prototipo totalmente
> ensamblado. Los valores PROVISIONAL eran del diseño; medir sobre el montaje real.

## Decisiones tomadas
- Plato 300 × 300 mm, acrílico de 3 mm. CORTADO (2026-10-23) en acrílico color VINO translúcido y brillante (el servicio no tenía negro). Marcas grabadas quedan gris claro (contraste moderado). Riesgo principal para la cámara: reflejos → luz difusa e indirecta imprescindible. Se le pegará una capa opaca en la cara inferior para eliminar la translucidez (color y acabado por decidir con prueba fotográfica; ver Pendientes).
- Bola (actualizado 2026-10-25): impresa en 3D, Ø40 mm, verde lima/neón MATE (tono opuesto al vino), **90 % de relleno**, en dos mitades pegadas con pasadores de filamento 1,75 mm y lijada (archivo bola_mitades_x2.stl). **Masa medida 34 g** (la estimación previa a 100 % de relleno era 41,5 g). Densidad efectiva ≈ 1,015 g/cm³ contra 1,24 del PLA macizo, o sea ~82 % de llenado efectivo; los huecos quedan hacia el centro (relleno interior + cavidad del machihembrado), lo que sube algo el momento de inercia respecto a una esfera maciza. Coeficiente de rodadura estimado entre 0,685 y 0,714 (macizo = 5/7 = 0,714): usar 5/7 como punto de partida y **medir el valor real** en el experimento de identificación. La masa no afecta la aceleración de rodadura (se cancela); sí reduce el torque pedido a los servos. Alternativa considerada: pintar una ping pong de verde mate.
- Borde: 12 mm sobre la superficie (tiras 2× 300×12 y 2× 294×12, pegadas encima del plato). Rango útil del centro de la bola: ±127 mm (254 × 254 mm), no ±150.
- Marcas de calibración: grabado al 100 % en la cara superior del plato. Tres patrones de esquina tipo QR (7 módulos de 4 mm = 28 mm) en las esquinas (−X,+Y), (+X,+Y), (−X,−Y) y un patrón de alineación QR (5 módulos = 20 mm) en (+X,−Y), que indica la orientación. Borde exterior de cada marca a 5 mm del borde perimetral; centro del plato sin grabado. Al ensamblar, la esquina con el patrón pequeño debe quedar entre el servo X (+X) y −Y. Nota para visión: los CENTROS de las marcas no forman un cuadrado (el patrón de alineación es de 20 mm y los otros de 28); las ESQUINAS EXTERIORES sí, y forman un cuadrado de 290 × 290 mm.
- Cajetín grabado en la base (frente, lado −Y): 150 × 38 mm, logo Ball on Plate + "LABORATORIO DE CONTROL AUTOMÁTICO / PROYECTO FINAL / Abner López, Jordi Segura, Anthony Villalta, Yonaikel Tencio", tipografía Architects Daughter (SIL OFL).
- Columna: junta universal **3/8″** (60 mm) arriba + extensión 6″ abajo; largo nominal 200,4 mm. Macho de la junta: 12 mm de largo. Extremo grueso (moleteado, hembra) de la extensión: Ø16 mm MEDIDO. OJO: en componentes.xlsx hay anotado un cardán de 1/2″ de Novex — NO sirve, las piezas impresas están dimensionadas para 3/8″.
- Arriba: bloque impreso con cuadrado hembra (profundidad 13 mm, brida 50×50, 4×M3 a 40×40). Lado del cuadrado PROVISIONAL 9,7 mm hasta elegir probeta (9,6/9,7/9,8/9,9).
- Placa de refuerzo en cruz (176 × 176, brazos de 50 mm), 2 capas: inferior con agujeros M3 Ø3,3; superior con alojamientos hexagonales para tuercas M3 (5,6 entre caras), pegada bajo el plato.
- Abajo (v2, 2026-10-26; la v1 con solo macho falló): base de columna impresa con COPA + ABRAZADERA que aprieta el extremo Ø16 de la extensión (agujero Ø16,3, pared 3,5, 18 mm de alto, ranura de 1,6 mm, 1 × M3 con tuerca en alojamiento exterior) + macho cuadrado 3/8″ de 10 mm GIRADO 45° en el fondo (respecto a los agujeros de la brida). Brida 60 × 60 × 5 con 4 × M3 a 46 × 46. La extensión sigue asentando a 5 mm sobre la base (alturas del ensamble sin cambio). Lado del macho PROVISIONAL 9,4 mm. También existe versión solo abrazadera (sin macho). Archivos: base_columna_v2_con_macho.stl / base_columna_v2_solo_abrazadera.stl.
- Varillas de empuje: impresas Ø8 × 120 mm, agujero Ø3 × 6 mm en cada extremo (probetas 2,6/2,8/3,0/3,2).
- Lado servo: ball link negro (tornillo 3 mm; MEDIDO ≈ 17 mm del centro de la bola al extremo del vástago) en brazo de acrílico (r = 24 mm, ranura 7–17 mm, centro Ø2,4).
- Lado plato: rótula (con tapa) y soporte impresos (Printables 603172 / 661542) al 60 %; pivote con perno M3 × 30.
- Geometría: d = 70 mm (centro → pivote de rótula, sobre +X y +Y), r = 24 mm → ≈ ±14° de plato con ±45° de servo (~0,34° de plato por grado de servo cerca del centro).
- Soportes de servo, acrílico 3 mm, por servo: placa del servo 40 × 46 (M2 × 10 + tuerca por las pestañas, agujeros Ø2,4 a 28 mm; 4 ranuras M3 verticales ±4 mm) + placa vertical 54 × 58 encastrada y pegada + 2 escuadras. Eje del servo nominal a 33,4 mm sobre la base (ajustable 29,4–37,4).
- Base: acrílico 340 × 340, 4 × M3 a 46 × 46 (columna), 4 × M3 en (±160, ±160) para patas, ranuras de encastre para los soportes de servo.
- Corte láser (servicio): PDF 800 × 500 horizontal; corte = rojo #FF0000 de 0,025 mm; marcado = azul #0000FF; grabado = rellenos negro #000000.
- Soporte de cámara: pórtico de dos patas en tubo PVC, independiente de la base, con pies en T. Debe quedar atornillado a una tabla común con la base: la homografía se guarda en archivo y cualquier movimiento relativo la invalida.

## Cotas del ensamble (desde la cara superior de la base)
- Cara inferior del plato 215,4 · pivote de la junta ≈ 169,4 (aprox.) · pivote de rótulas 195,6 · eje de los servos 33,4 · distancia entre bolas de la cadena 162,2.
- Cámara (concepto): lente a 668,4 desde la base, es decir ~450 mm sobre el plato. Con bola de Ø40, el centro de la bola está 20 mm sobre el plano calibrado → la posición medida sale escalada por 450/430 = 1,047 (≈6 mm de error en el borde). Corregir multiplicando por 0,956.
- Visor 3D: artifact "Ensamble Ball on Plate". Guía de ensamblaje: doc "Guía de ensamblaje Ball on Plate".

## Soporte y rótula impresos al 60 %
| Medida | 60 % |
|---|---|
| Huella del soporte | 30,0 × 25,2 |
| Patrón de agujeros de montaje (radial × eje del pivote) | 14,4 × 19,2 |
| Ø agujero de montaje (repasar a 3,2 para M3) | 2,4 |
| Altura total del soporte | 19,8 |
| Altura del eje del pivote sobre la superficie | 13,8 |
| Ø agujero de la bola | 3,6 |
| Centro de bola → extremo del vástago | 25,2 |

## Tornillería
- Bloque superior: M3 × 10 (no más largo), tuercas M3 en la capa superior del refuerzo.
- Soportes de rótula: M3 × 25, tuercas M3 en la capa superior del refuerzo; pivote de rótula: M3 × 30 + tuerca (×2).
- Base de la columna: 4 × M3 a 46 × 46; abrazadera: 1 × M3 × 16 + tuerca.
- Servos: 4 × M2 × 10 + tuerca; placa del servo a placa vertical: 8 × M3 × 10 + tuerca.
- Patas: 4 × M3.

## Pendientes / riesgos
- Puente de acrílico de ~1,2 mm entre agujero M2 y ventana en la placa del servo: apretar con cuidado.
- Profundidad de la hembra inferior de la extensión (> 10 mm).
- MG90D: rango real de giro. Si resulta menor a ±45°, la pieza a rehacer es el brazo de acrílico (más largo = más carrera por grado de servo).
- Reflejos del acrílico vino brillante y posible translucidez: validar detección de marcas y bola con la iluminación real.
- Capa opaca inferior: decidir color (negra mate favorece el contraste de las marcas grabadas pero convierte la superficie en espejo; blanca mate reduce reflejos pero apaga las marcas). Probar con hoja blanca y hoja negra bajo el plato ANTES de pegar. El cemento de acrílico no pega sobre vinil: enmascarar la huella de la cruz de refuerzo, pegar la cruz sobre acrílico limpio y dar el mismo acabado opaco a la cara inferior de la cruz, para que el fondo quede uniforme.
- Bola impresa: verificar redondez y centrado de masa (dos mitades pegadas + cavidad central). Prueba: soltarla en una rampa suave y comprobar que rueda recto y sin bamboleo. Un centro de masa descentrado aparece como perturbación periódica en el control.
- Coeficiente de rodadura real de la bola: medir con el experimento de identificación (parábola de posición a ángulo fijo conocido).
