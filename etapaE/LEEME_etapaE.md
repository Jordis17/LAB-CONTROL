# Etapa E — Preparación y generación de código

## 1. Qué se hace y por qué

- **Se separa el controlador de la planta.** `Controller_BoP.slx` contiene solo el algoritmo
  de un eje. La planta no va adentro. Eso permite generar código del algoritmo solo e
  instanciarlo en los bancos SIL y PIL (Etapas F y G) y en la ESP32. Los dos ejes usan el mismo
  modelo: el código sale como *Reusable function* y el firmware lo llama dos veces, cada una
  con su propio estado.
- **El modelo es la referencia intocable** de las Etapas E a G. `E0` se niega a sobrescribirlo
  si ya existe. La copia para la implementación (Etapa H) llevará otro nombre.
- **Una sola fuente del algoritmo.** El bloque MATLAB Function `ley_control` contiene
  `ley_control_BoP_bloque.m` seguido de `etapaC/funciones/bop_ley_control.m`, que es la misma
  función que usa el MIL. E0 copia el texto dentro del bloque, así que el modelo no depende de
  archivos externos.

## 2. Interfaz (un eje, una llamada por cuadro de cámara, Ts = 1/30 s)

| | Señal | Unidad | Tipo | Notas |
|---|---|---|---|---|
| Entrada 1 | `r_mm` | mm | double | Referencia |
| Entrada 2 | `x_hat_mm` | mm | double | Posición del Kalman (trama serial) |
| Entrada 3 | `v_hat_mm_s` | mm/s | double | Velocidad del Kalman (trama serial) |
| Entrada 4 | `habilitado` | — | boolean | `false`: θ = 0 y estado en 0. Se usa al arrancar, con `estado = 0` (sin bola) y cuando salta el watchdog |
| Salida 1 | `th_cmd_rad` | rad | double | Inclinación pedida; va a la cinemática inversa (fuera del modelo) |
| Salida 2 | `I_rad` | rad | double | Integrador, para registro y verificación |
| Salida 3 | `saturado` | — | boolean | Saturación en este paso |

**Parámetros calibrables:** `BoP_Kp`, `BoP_Ki`, `BoP_Kd`, `BoP_Ts`, `BoP_th_lim`,
`BoP_e_clip`, `BoP_v_int` y `BoP_Nq`. Son objetos `Simulink.Parameter` de tipo double con
clase de almacenamiento `ExportedGlobal`, así que en el código quedan como variables globales.
Los crea `init_Controller_BoP.m` a partir de `etapaC/resultados/C1_controlador.mat`.

**Estado interno:** `I` (integrador, en rad) y `nq` (cuadros seguidos con la bola quieta).

**Representación numérica:** el modelo de referencia usa double. La ESP32 tiene FPU de
precisión simple; si en la implementación conviene pasar a single, se hace en la copia de la
Etapa H y se verifica aparte. **No se cambia este modelo.**

## 3. Qué correr en MATLAB (en orden), desde la carpeta `etapaE`

Requisito previo: haber corrido `etapaC/C1_disenar_controlador_BoP` en MATLAB.

```matlab
cd etapaE
E0_build_Controller_BoP          % construye y guarda Controller_BoP.slx
E1_verificar_equivalencia_BoP    % modelo vs MIL, muestra a muestra (debe dar PASS)
```

**Code Generation Advisor** (en la interfaz gráfica; los objetivos ya quedan fijados por E0 en
*Execution efficiency* y *Traceability*):

1. Abrir `Controller_BoP.slx` → pestaña **APPS** → **Embedded Coder**.
2. En la pestaña **C CODE**: **Check Code** (o el menú de verificación) → **Code Generation
   Advisor**. Seleccionar el modelo raíz y correr todas las verificaciones.
3. Criterio: **cero Fail**. Las advertencias se anotan y se justifican. **No usar `Fix All`
   ni aplicar cambios automáticos.** Si aparece un Fail, se manda el texto completo antes de
   tocar nada (CLAUDE.md, sección 7).
4. Guardar el reporte HTML en `etapaE/resultados/advisor/`.

Después:

```matlab
E2_generar_codigo_BoP            % genera el código C y lo inspecciona
```

**Qué devolver:**
- la carpeta `etapaE/resultados/`, con las consolas E0, E1 y E2, los CSV y el reporte del
  Advisor;
- la carpeta `etapaE/codigo_generado/`;
- el archivo `Controller_BoP.slx`.

Con eso se arma la tabla de correspondencia modelo ↔ código.

## 4. Verificación de que la preparación no alteró el MIL (E1)

Con el MIL se simulan cuatro casos:
- D1: requisitos;
- D2: empujón con saturación;
- D3: desnivel, con el integrador activo;
- D4: dos ejes.

De cada uno se toman, cuadro por cuadro, las entradas y salidas del controlador. Las mismas
entradas se pasan por:

- **Parte A:** `ley_control_BoP_bloque.m` fuera de Simulink. Se corrió en Octave 8.4 en esta
  sesión (`verificacion_octave/E1_consola.txt`): **diferencia exacta 0 en th_cmd, I y
  saturado, en los 5 ensayos**. Eso incluye 7 cuadros saturados y los cuadros previos a la
  habilitación.
- **Parte B:** `Controller_BoP.slx` con `sim()`. **Solo se puede correr en MATLAB.**
  Criterio: max\|dif\| ≤ 1e-12 en th_cmd e I, y cero diferencias en `saturado`.

La comparación es en lazo abierto, sin planta. Así se aísla el algoritmo: si las salidas
coinciden muestra a muestra para las mismas entradas, el lazo cerrado también coincide. Los
bancos con planta son los de SIL y PIL (Etapas F y G).

## 5. Qué revisa E2 en el código generado

Comprueba que estén presentes:
- las funciones `_step` e `_initialize`;
- los 8 parámetros como globales;
- el estado en `DW`;
- la entrada booleana y la salida;
- los tipos `real_T` y `boolean_T`.

Y que estén ausentes:
- `sin`, `cos`, `acos` y `atan2`, porque ni la planta ni la cinemática van adentro;
- cualquier resto del modelo de la planta.

También imprime las líneas del `.c` que mencionan parámetros y estado, para armar la tabla de
correspondencia modelo ↔ código. Esa tabla se completa cuando llegue el código.

## 6. Pendientes

- Correr E0, E1 (Parte B), el Advisor y E2 en MATLAB.
- Confirmar la versión de MATLAB y que estén Embedded Coder y Simulink Coder (salida de `ver`).
- **ProdHWDeviceType** queda en "Generic → 32-bit Embedded Processor" porque el modelo exacto
  de la placa ESP32 está PENDIENTE. La placa concreta se fija para PIL (Etapa G).

## 7. Configuración de hardware para SIL (E3, 2026-11-06)

La primera corrida de F1 falló porque el SIL compila el código en la PC (64 bits) y la
configuración de producción era "Generic → 32-bit" con el orden de bytes y el redondeo de la
división entera sin definir. `E3_config_hardware_BoP.m` fija en `Controller_BoP.slx`:
`ProdEndianess = LittleEndian` y `ProdIntDivRoundTo = Zero` (propios de la ESP32; eran las
advertencias 2 y 3 del Advisor) y `PortableWordSizes = on` (para que el mismo código compile en
la PC). **No cambia el algoritmo.** Como el modelo de referencia cambia de versión, después de
E3 se repiten E1 y E2. E0 ya incluye estos valores para futuras reconstrucciones.
