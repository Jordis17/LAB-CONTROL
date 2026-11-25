// bop_controlador_pid_lqr.ino  -  LOS DOS CONTROLADORES EN UN SOLO PROGRAMA (2026-11-25)
//
// Junta firmware/bop_controlador_estable (PID, la version de trabajo) y firmware/bop_controlador_lqr
// (LQR con accion integral) sin cambiar ninguna de las dos leyes. Los dos firmwares originales
// quedan como estaban.
//
// Boton BOOT (GPIO0), cada pulsacion pasa al paso siguiente. El LED da tantos destellos
// como el numero del paso y hace una pausa (cuenten los destellos):
//   0 DESARMADO                   LED apagado
//   1 CENTRO con PID              1 destello
//   2 CENTRO con LQR              2 destellos
//   3 CIRCULO con PID             3 destellos   (R_CIRC, T_CIRC; el radio crece en rampa)
//   4 CIRCULO con LQR             4 destellos
//   5 ENSAYO AUTOMATICO con PID   5 destellos
//   6 ENSAYO AUTOMATICO con LQR   6 destellos
//   -> vuelve a DESARMADO. Al terminar un ensayo pasa solo a CENTRO con el mismo controlador.
// Sin tramas (watchdog): LED parpadeo rapido continuo, plato horizontal.
// Al cambiar de paso se borran el integrador y las entradas pasadas.
//
// Telemetria: igual que antes; el bit 3 de "banderas" (tel_banderas) dice que controlador
// estaba activo (0 PID, 1 LQR). main_vision.py lo muestra en la terminal.
//
// Diferencias entre las dos leyes que se conservan tal cual estaban:
//   PID: integra solo con la bola quieta, recorte de 30 mm, descarga lejos con la bola en
//        movimiento, tope 3 deg; en los circulos usa la prediccion x + v*TAU_PRED.
//   LQR: integra siempre (salvo zona y clamping), recorte de 5 mm, tope 5 deg; sin prediccion
//        en los circulos (el predictor esta en la ley).
//
// ------------------------- Historia (de los firmwares de los que sale) -------------------------
// bop_controlador_estable.ino  -  VERSION DE TRABAJO (2026-11-13)
//
// Es el firmware de los logs con mejor desempeno con la bola de ping pong
// (sesion_20261113_105517: circulo centrado en (6, -4) mm, radio medio de 45 mm, sin tocar el borde;
// sesion_20261113_105834: ensayo automatico). Sale del commit 8d0f938 de
// bop_prueba_circulo_lazo.ino, con:
//   - el controlador ORIGINAL de la Etapa C (Kp 0,0341, Kd 0,0259, Ki 0,0227);
//   - la zona de tolerancia de 5 mm en modo centro y el integrador que se descarga lejos de la
//     referencia (la correccion del defecto de x = -57 mm de ese mismo log);
//   - SIN compensacion de zona muerta ni despegue (se agregaron despues y no mejoraron).
// Cambios respecto de ese commit: (1) el integrador suma con la bola quieta en cualquier posicion
// (2026-11-18, ver leyControl); (2) TH_TRIM (nivel del plato visto por la bola). Paso de
// {0,45; 1,2} a {-1,25; -0,25} deg el 2026-11-13 (log 151156) y a {1,5; 0,4} el 2026-11-18
// (log 092357, ver la constante).
// Si el equipo reajusta los brazos, hay que volver a estimar el trim.
// BOOT: DESARMADO -> CENTRO -> CIRCULO -> ENSAYO AUTOMATICO (90 s) -> DESARMADO.
//
// bop_prueba_circulo_lazo.ino  -  PRUEBA FUNCIONAL: la bola sigue una CIRCUNFERENCIA (lazo cerrado)
//
// Copia de bop_prueba_lazo_v2.ino (que no se modifica) con una referencia que
// gira:   r(t) = R (cos wt, sin wt),  w = 2 pi / T.
// La ley es la misma del v2, con dos terminos que solo actuan con la
// referencia en movimiento (prueba funcional, NO esta en el MIL ni en el
// codigo generado):
//   - derivativo sobre (v_hat - v_ref) en lugar de v_hat: sin esto el Kd frena
//     la bola justo cuando tiene que moverse;
//   - prealimentacion de la aceleracion de la referencia: con el modelo de la
//     Etapa A (xdd = -c g th), la inclinacion que produce a_ref es
//     th_ff = -a_ref / (c g). Sin esto la bola recorre un circulo mas chico y
//     atrasado.
//   - (2026-11-09) en modo circulo, prediccion de la posicion para compensar el
//     retardo de la camara: x_pred = x_hat + v_hat * TAU_PRED.
// Con la referencia quieta (modo centro) estos terminos valen 0 y la ley es
// identica a la del v2.
//
// Boton BOOT (GPIO0), cada pulsacion pasa al modo siguiente:
//   DESARMADO (LED apagado) -> CENTRO (LED encendido) -> CIRCULO (LED parpadeo lento)
//   -> ENSAYO AUTOMATICO (LED destellos cortos, 70 s, ver "Ensayo automatico") -> DESARMADO
//   Al terminar el ensayo pasa solo a CENTRO.
// Al entrar en CIRCULO el radio crece en rampa durante RAMPA_S segundos.
// Lo demas (watchdog, sin bola, filtro de saltos, limite de velocidad) es igual al v2.
//
// Uso: igual que el v2, con main_vision.py mandando las tramas (921600 baud).
//
// TELEMETRIA (2026-11-09, para identificar la planta en lazo cerrado): por cada
// trama procesada, la ESP32 contesta por el mismo puerto con 57 bytes que
// main_vision.py guarda en el log (columnas tel_*):
//   [0] 0xBC  [1] modo  [2] banderas (bit0 sat X, bit1 sat Y, bit2 cuadro ignorado por salto,
//            bits 4-7 fase del ensayo automatico)
//   [3..6] n_tramas (uint32)  [7..10] millis (uint32)
//   [11..46] 9 float32: th_out X, th_out Y (deg, plato pedido tras el limite de
//            velocidad = lo que va a la tabla y al servo), th_ley X, th_ley Y
//            (deg, salida de la ley antes del limite), I X, I Y (deg),
//            r X, r Y (mm, referencia), x recibido (mm, eco para alinear con el log)
//   [47..48] tramas viejas descartadas en esta lectura (uint16)
//   [49..50] tramas con checksum malo desde el arranque (uint16)
//   [51..54] duracion maxima de loop() desde la telemetria anterior (us, uint32)
//   [55] xor de los bytes 1..54   [56] 0x66
//   (version anterior: 0xBB, 49 bytes, sin los campos 47..54)
//
#include <ESP32Servo.h>
#include <math.h>

// ---------------------------------------------------------------- Pines ---
const int PIN_X   = 19;   // senal servo X  // (2026-11-09) el servo del lado +X esta en GPIO19 y el del +Y en GPIO18 (estaban cruzados)
const int PIN_Y   = 18;   // senal servo Y
const int PIN_LED = 2;    // LED azul de la placa
const int PIN_BTN = 0;    // boton BOOT (activo en bajo)

// ------------------------------------------------- Comunicacion (trama) ---
// [0xAA][estado u8][x f32][y f32][vx f32][vy f32][XOR u8][0x55], little-endian.
// XOR = xor de los 17 bytes de datos (estado + 4 floats). Ver transmitter.py.
const uint32_t BAUD = 921600;
const uint32_t WATCHDOG_MS = 200;

// Signo de cada eje de la vision respecto del plato (+1 si al empujar la bola
// hacia el servo X la lectura X de main_vision.py SUBE; -1 si baja). Igual en Y.
const float SIGNO_VIS[2] = {+1.0f, +1.0f};

// --------------------------------------------- Controlador PID (Etapa C, C1) ---
// Unidades: mm, mm/s, GRADOS de plato. Valores de etapaC (2026-11-04).
const float KP     = 0.034118997f;   // deg/mm
const float KD     = 0.025875847f;   // deg/(mm/s)
const float KI     = 0.022745998f;   // deg/(mm s)
const float E_CLIP = 30.0f;          // mm, recorte del error del integrador (PID)

// ---------------------------------------- Controlador LQR (Etapa C, C2) ---
// Unidades: mm, mm/s, GRADOS de plato. etapaC/verificacion_octave/C2_consola.txt (2026-11-25):
//   K = [-0.00141694 -0.000821163 0.0852143 0.18154 0.170915 0.160499 -0.000804878]
//   estado [e, v, u[k-4], u[k-3], u[k-2], u[k-1], z], u = -K*s en rad.
// Si la corrida de MATLAB da otros valores, copiarlos aca.
const float KE     = 0.081184f;      // deg/mm          (= -K(1) en grados)
const float KV     = 0.047049f;      // deg/(mm/s)      (= -K(2) en grados)
const float KU1    = 0.160499f;      // adimensional, multiplica a th[k-1]
const float KU2    = 0.170915f;      //                                 th[k-2]
const float KU3    = 0.181540f;      //                                 th[k-3]
const float KU4    = 0.085214f;      //                                 th[k-4]
const float KZ     = 0.046116f;      // deg/(mm s)      (= -K(7) en grados)
const float E_CLIP_LQR = 5.0f;       // mm, recorte del error que entra al integrador
const int   N_PASADAS  = 4;          // d del modelo de diseno
const float TS     = 1.0f / 30.0f;   // s (periodo de diseno)
const float TH_LIM = 10.0f;          // deg, saturacion de la inclinacion pedida
const float V_INT  = 25.0f;          // mm/s, umbral de bola quieta
const int   NQ     = 4;              // cuadros quieta antes de integrar
float REF[2] = {0.0f, 0.0f};         // referencia (mm): centro del plato

// ------------------------------------------------ Trayectoria circular ---
const float R_CIRC  = 45.0f;   // mm. 2026-11-13: 60 mm/4 s tocaba el borde; 40 mm/6 s pide menos de
                               // 1 deg (rozamiento + holgura): avanza a tirones. Punto intermedio.
const float T_CIRC  = 4.0f;    // s por vuelta
const float SENTIDO = 1.0f;    // +1 antihorario, -1 horario (en el marco de la vision)
const float RAMPA_S = 3.0f;    // s para que el radio llegue a R_CIRC
// (2026-11-13) Solo para la prealimentacion del circulo. En el circulo de
// sesion_20261113_093155 (R = 60 mm, T = 4 s) la bola giro con radio 94 mm: el balance
// radial w^2 R_bola = c g sin(th_ff + Kp*(R_bola - R)) da c ~ 0,57 para movimientos
// lentos y grandes (B3, con perturbacion chica y rapida dentro de la holgura, da ~0,2).
const float C_ROD   = 0.57f;          // rodadura para la prealimentacion (nominal 5/7)
const float G_MM    = 9810.0f;        // mm/s^2
const float TAU_PRED = 0.075f; // s: compensacion del retardo de la camara en modo circulo
                               // (x_pred = x_hat + v_hat * TAU_PRED). 0 = sin compensacion.
                               // Latencia medida ~60 ms + medio cuadro de calculo.
int   modo = 0;                // 0 desarmado, 1 centro, 2 circulo, 3 ensayo automatico
// ------------------------------------------- Ensayo automatico (modo 3) ---
// Secuencia fija (s desde que se entra al modo 3), sin intervencion:
//   fase 1   0- 5  centro
//   fase 2   5-25  escalones de referencia de ESC_MM: +X, -X, +Y, -Y (4 s c/u) y centro (4 s)
//   fase 3  25-45  centro + perturbacion pseudoaleatoria de +-DITHER_DEG en cada eje,
//                  cambia cada DITHER_CUADROS cuadros (para identificar: entrada conocida
//                  e independiente del ruido)
//   fase 4  45-57  circulo de 50 mm, 6 s por vuelta (2 vueltas)
//   fase 5  57-65  circulo de 50 mm, 4 s por vuelta (2 vueltas)
//   fase 6  65-70  centro; al terminar pasa solo a modo CENTRO
// La fase va en los bits 4-7 de las banderas de la telemetria.
const float ESC_MM = 40.0f;
const float DITHER_DEG = 1.5f;
const int   DITHER_CUADROS = 9;     // 0,3 s
float t_ens = 0.0f;
int   fase = 0;
uint16_t lfsr[2] = {0xACE1u, 0x1D2Bu};
float dither[2] = {0, 0};
int   n_dither = 0;
bool  sat_e[2]  = {false, false};   // telemetria: saturacion en este cuadro
float th_ley[2] = {0, 0};           // telemetria: salida de la ley (deg)
float r_tel[2]  = {0, 0};           // telemetria: referencia (mm)
bool  ignorado  = false;            // telemetria: cuadro ignorado por salto
float t_circ = 0.0f;           // s desde que se entro al modo circulo (cuenta por trama)
// --- v2: protecciones de la prueba funcional
const float SLEW_DEG = 6.0f;         // deg por cuadro (= 180 deg/s a 30 fps). v2 usa 3; con 6 la bola
                                     // empujada a 500 mm/s se frena a 125 mm en vez de 138 (simulacion 2026-11-09)
const float E_ZONA   = 40.0f;        // mm: lejos de esto, el integrador se descarga con la bola en movimiento (2026-11-18)
const float I_MAX_PID = 3.0f;        // deg: tope del integrador del PID
const float I_MAX_LQR = 5.0f;        // deg: tope del integrador del LQR (2026-11-25: con 3 el integrador
                                     // quedaba pegado en el tope con la bola a 10-35 mm del centro)
bool usar_lqr = false;               // controlador activo (lo fija el paso del boton BOOT)
int  paso = 0;                       // 0 desarmado, 1-2 centro, 3-4 circulo, 5-6 ensayo (impar PID, par LQR)
// (2026-11-13) Fuera de E_ZONA el integrador ya no queda congelado: se descarga con esta
// constante de tiempo. En sesion_20261113_105834 la bola quedo 20 s quieta a x = -57 mm
// porque el integrador seguia en +1,7 deg (acumulado con la bola del otro lado) y anulaba
// al proporcional (-1,77 deg): plato a -0,07 deg, por debajo de la zona muerta del mecanismo.
const float TAU_DESCARGA = 1.5f;     // s
const float SALTO_MM = 60.0f;        // mm por cuadro (1800 mm/s): mas que esto es una falsa deteccion

// ---------------------- Relacion servo -> plato MEDIDA (2026-11-04, v2) ---
// datos_prototipo/mecanica/servo_plato_v2_convencion_plato.csv
// comando del servo (grados respecto de 1500 us)  ->  inclinacion del plato (deg),
// convencion: th > 0 levanta el lado del servo. Un comando positivo BAJA el lado.
const int NTAB = 9;
const float CMD_TAB[NTAB] = {-40, -30, -20, -10, 0, 10, 20, 30, 40};
const float TH_TAB[2][NTAB] = {
  // (2026-11-09, v3) Medida de nuevo despues de reajustar los brazos:
  // datos_prototipo/mecanica/servo_plato_2026-11-09_v3.csv, promedio de ida y vuelta.
  // Nivelan el plato: X ~ +9, Y ~ +6. Holgura ida-vuelta: X 0,3-0,8 deg, Y 0,4-2,4 deg.
  {25.00f, 19.90f, 14.10f, 8.65f, 4.25f, -0.45f, -4.50f, -7.90f, -10.90f},   // eje X (servo en GPIO19)
  {23.60f, 19.30f, 13.20f, 7.20f, 2.80f, -1.80f, -5.35f, -8.20f, -10.30f}    // eje Y (servo en GPIO18)
};
// (2026-11-09) Correccion fija del nivel, medida con la BOLA y no con la app: en los
// ensayos automaticos 164915 y 165209 (tabla v3) la bola quedaba quieta con el plato
// pedido a +2 a +3 deg en los dos ejes, y B3 da una aceleracion constante de +68 a +100
// mm/s^2 (equilibrio en ~+2,5 deg pedidos). La tabla de la app tiene un sesgo de ese orden.
// Se suma a la inclinacion pedida antes de la tabla (la telemetria th_out NO la incluye).
// (2026-11-13) CORREGIDO: +2,5 era excesivo (salia de tramos con la bola quieta por
// rozamiento, no en equilibrio). En el circulo sesion_20261113_090144 la ley tuvo que
// restar en promedio -2,6 (X) y -1,5 (Y): el nivel real esta en ~0 (X) y ~+1 (Y).
// (2026-11-13, sesion_20261113_093155) la ley sumo en promedio +0,94 (X) y +0,23 (Y)
// durante 160 s de circulo: se pasan al trim.
// (2026-11-13, sesion_20261113_094845) con X = 0,9 el centro de la orbita paso de +30 a
// -31 mm: el valor justo en X esta en el medio. En Y el centro casi no cambio con el trim
// (+31 -> +27 mm): ese corrimiento no es de nivel (probable holgura de Y, hasta 2,4 deg).
// (2026-11-18, sesion_20261118_092357, modo centro 70 s) con {-1,25; -0,25} la bola se fue a la
// esquina (+x, +y) y quedo 55 s quieta en (110,4; 57,6) mm. Ahi la ley pedia +3,60 (X) y +1,80 (Y)
// (integrador en 0, porque fuera de E_ZONA se descarga), o sea +2,35 y +1,55 aplicados con el trim.
// La bola llego a ese punto rodando hacia el centro, asi que quedo en el BORDE de la zona muerta:
// nivel = aplicado - zona muerta (B3, log 151156: X 0,86, Y 1,18 deg) = +1,5 (X) y +0,4 (Y).
// Incertidumbre de ~1 deg (la zona muerta vario de 0,9 a 1,9 deg entre ensayos). NO se uso la ley
// media sin restar la zona muerta: ese fue el error del trim +2,5 del 2026-11-09.
const float TH_TRIM[2] = {1.5f, 0.4f};     // deg, ejes X e Y (2026-11-18; antes {-1,25; -0,25})
const float US_NEUTRO = 1500.0f;
const float US_POR_GRADO = 1000.0f / 90.0f;

// ------------------------------------------------------------- Estado ---
Servo servo[2];
float I[2]  = {0, 0};     // aporte del integrador del LQR, KZ*z (deg)
float UB[2][4] = {{0, 0, 0, 0}, {0, 0, 0, 0}};   // th[k-4] ... th[k-1] por eje (deg), UB[e][3] = th[k-1]
void borrarPasadas(int e) { for (int i = 0; i < 4; i++) UB[e][i] = 0.0f; }
void empujarPasada(int e, float th) { for (int i = 0; i < 3; i++) UB[e][i] = UB[e][i+1]; UB[e][3] = th; }
int   nq[2] = {0, 0};     // cuadros con la bola quieta
bool  armado = false;
float th_out[2] = {0, 0};  // angulo de plato que se esta mandando (deg)
float x_prev[2] = {0, 0};
bool  hay_prev = false;
uint32_t n_saltos = 0;
int saltos_seguidos = 0;
uint32_t t_ultima = 0;    // ms de la ultima trama valida
uint32_t n_tramas = 0, n_malas = 0;

// Comando de servo (grados) que produce la inclinacion th (deg), invirtiendo la
// tabla por tramos lineales. La tabla es decreciente en el comando.
float comandoDesdePlato(int e, float th) {
  const float *t = TH_TAB[e];
  if (th >= t[0]) return CMD_TAB[0];
  if (th <= t[NTAB - 1]) return CMD_TAB[NTAB - 1];
  for (int i = 0; i < NTAB - 1; i++) {
    if (th <= t[i] && th >= t[i + 1]) {
      float f = (th - t[i]) / (t[i + 1] - t[i]);
      return CMD_TAB[i] + f * (CMD_TAB[i + 1] - CMD_TAB[i]);
    }
  }
  return 0.0f;
}

void moverPlato(int e, float th_deg) {
  float c = comandoDesdePlato(e, th_deg + TH_TRIM[e]);
  if (c > 40.0f) c = 40.0f;
  if (c < -40.0f) c = -40.0f;
  servo[e].writeMicroseconds((int)lroundf(US_NEUTRO + c * US_POR_GRADO));
}

// Lleva el plato hacia th_obj (deg) con el limite de velocidad SLEW_DEG por llamada.
void moverConLimite(int e, float th_obj) {
  float d = th_obj - th_out[e];
  if (d > SLEW_DEG) d = SLEW_DEG;
  if (d < -SLEW_DEG) d = -SLEW_DEG;
  th_out[e] += d;
  moverPlato(e, th_out[e]);
}

void platoHorizontal() {           // sin rampa: solo al arrancar
  for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; borrarPasadas(e); th_out[e] = 0; moverPlato(e, 0.0f); }
}

void haciaHorizontal() {           // con rampa: sin bola, sin tramas, desarmado
  for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; borrarPasadas(e); moverConLimite(e, 0.0f); }
  hay_prev = false;
}

// Misma ley que bop_ley_control.m (usar_aw = saturar = true), en grados.
// Zona de tolerancia (solo en modo CENTRO, 2026-11-13, pedido del equipo): con la bola a
// menos de ZONA_MM de la referencia en un eje, el proporcional de ese eje vale 0 y el
// integrador no suma. Fuera de la zona el error se cuenta desde su borde (sin salto).
// Evita que el integrador acumule de a poco hasta despegar la bola de golpe (rozamiento).
// OJO: con zona, el error estacionario puede llegar a ZONA_MM (el requisito R3 es 3 mm).
const float ZONA_MM = 5.0f;
// ---- PID (copiada sin cambios de bop_controlador_estable, salvo el nombre del tope) ----
float leyPID(int e, float xh, float vh, float r, float vref, float th_ff, bool zona) {
  float eps = xh - r;
  bool en_zona = false;
  if (zona) {
    if (fabsf(eps) <= ZONA_MM) { eps = 0.0f; en_zona = true; }
    else eps = (eps > 0) ? eps - ZONA_MM : eps + ZONA_MM;
  }
  float u = KP * eps + I[e] + KD * (vh - vref) + th_ff;
  float th = u;
  if (th > TH_LIM) th = TH_LIM;
  if (th < -TH_LIM) th = -TH_LIM;
  bool saturado = (th != u);
  sat_e[e] = saturado;
  bool congelar = saturado && ((eps > 0) - (eps < 0)) == ((u > 0) - (u < 0));
  if (fabsf(vh) < V_INT) nq[e]++; else nq[e] = 0;
  bool quieta = nq[e] >= (NQ > 1 ? NQ : 1);
  // (2026-11-18) INTEGRADOR CON LA BOLA QUIETA EN CUALQUIER POSICION, como en la ley de la Etapa C
  // (bop_ley_control.m): si la bola esta quieta, el error que queda es un sesgo (nivel, neutro) y
  // el integrador lo corrige, este cerca o lejos de la referencia. Antes solo integraba con
  // |error| < E_ZONA y se descargaba fuera, y en sesion_20261118_092357 la bola quedo 55 s quieta
  // en (110, 58) mm con el integrador en 0. Ahora la descarga solo actua con la bola EN MOVIMIENTO
  // lejos de la referencia (lo que se cargo mientras estaba sostenida o trabada no frena el regreso).
  // Con la bola quieta lejos, sube a KI*E_CLIP = 0,68 deg/s hasta despegarla (tope I_MAX_PID).
  if (fabsf(eps) >= E_ZONA && !quieta) I[e] *= (1.0f - TS / TAU_DESCARGA);
  if (!congelar && !en_zona && quieta) {
    float ec = eps;
    if (ec > E_CLIP) ec = E_CLIP;
    if (ec < -E_CLIP) ec = -E_CLIP;
    I[e] += KI * TS * ec;
    if (I[e] > I_MAX_PID) I[e] = I_MAX_PID;
    if (I[e] < -I_MAX_PID) I[e] = -I_MAX_PID;
  }
  return th;
}

// ---- LQR (copiada sin cambios de bop_controlador_lqr, salvo el nombre del tope) ----
float leyLQR(int e, float xh, float vh, float r, float vref, float th_ff, bool zona) {
  float eps = xh - r;
  bool en_zona = false;
  if (zona) {
    if (fabsf(eps) <= ZONA_MM) { eps = 0.0f; en_zona = true; }
    else eps = (eps > 0) ? eps - ZONA_MM : eps + ZONA_MM;
  }
  float pasadas = KU1 * UB[e][3] + KU2 * UB[e][2] + KU3 * UB[e][1] + KU4 * UB[e][0];
  float u = KE * eps + KV * (vh - vref) - pasadas + I[e] + th_ff;
  float th = u;
  if (th > TH_LIM) th = TH_LIM;
  if (th < -TH_LIM) th = -TH_LIM;
  bool saturado = (th != u);
  sat_e[e] = saturado;
  // clamping: no integrar si esta saturado y el integrador empujaria mas hacia la saturacion
  bool congelar = saturado && ((eps > 0) - (eps < 0)) == ((u > 0) - (u < 0));
  if (!congelar && !en_zona) {
    float ec = eps;
    if (ec > E_CLIP_LQR) ec = E_CLIP_LQR;
    if (ec < -E_CLIP_LQR) ec = -E_CLIP_LQR;
    I[e] += KZ * TS * ec;
    if (I[e] > I_MAX_LQR) I[e] = I_MAX_LQR;
    if (I[e] < -I_MAX_LQR) I[e] = -I_MAX_LQR;
  }
  return th;
}

float leyControl(int e, float xh, float vh, float r, float vref, float th_ff, bool zona) {
  return usar_lqr ? leyLQR(e, xh, vh, r, vref, th_ff, zona) : leyPID(e, xh, vh, r, vref, th_ff, zona);
}

// --------------------------------------------------------- Recepcion ---
uint8_t buf[20];
int nbuf = 0;

// Devuelve true cuando hay una trama completa y valida en buf.
// (2026-11-09) Lee TODO lo que llego, en bloque y sin esperar, y se queda con
// la trama valida MAS NUEVA. Antes se leia byte a byte (Serial.read()) y se
// procesaba una sola trama por vuelta: la ESP32 atendia una trama cada 40 ms
// exactos (25 por s) mientras la PC manda 30 por s, el buffer de recepcion se
// llenaba (~20 tramas) y el lazo trabajaba con datos de 0,5 a 0,7 s de atraso
// (log sesion_20261109_120621, eco tel_x_rx). Ahora, si hay atraso, las tramas
// viejas se descartan y se cuentan.
uint8_t buf_nueva[20];
uint16_t descartadas = 0;          // tramas validas viejas descartadas en la ultima lectura
bool leerTrama() {
  static uint8_t rx[512];
  bool hay = false;
  int nuevas = 0;
  descartadas = 0;
  while (true) {
    int k = Serial.available();
    if (k <= 0) break;
    if (k > (int)sizeof(rx)) k = sizeof(rx);
    int leidos = Serial.read(rx, k);          // en bloque, sin esperar
    if (leidos <= 0) break;
    for (int q = 0; q < leidos; q++) {
      uint8_t b = rx[q];
      if (nbuf == 0 && b != 0xAA) continue;
      buf[nbuf++] = b;
      if (nbuf == 20) {
        nbuf = 0;
        uint8_t x = 0;
        for (int i = 1; i <= 17; i++) x ^= buf[i];
        if (buf[19] == 0x55 && buf[18] == x) {
          memcpy(buf_nueva, buf, 20);
          hay = true;
          nuevas++;
          continue;
        }
        n_malas++;
        // resincronizar: buscar otro 0xAA dentro de lo recibido
        for (int i = 1; i < 20; i++) {
          if (buf[i] == 0xAA) {
            int m = 0;
            for (int j = i; j < 20; j++) buf[m++] = buf[j];
            nbuf = m;
            break;
          }
        }
      }
    }
  }
  if (hay) {
    memcpy(buf, buf_nueva, 20);
    descartadas = nuevas - 1;
  }
  return hay;
}

// -------------------------------------------------------- Telemetria ---
uint32_t loop_max_us = 0;          // duracion maxima de loop() desde la ultima telemetria
void enviarTelemetria(float x_rx) {
  uint8_t b[57];
  b[0] = 0xBC;                     // formato 2 (57 bytes); 0xBB era el de 49 bytes
  b[1] = (uint8_t)modo;
  b[2] = (sat_e[0] ? 1 : 0) | (sat_e[1] ? 2 : 0) | (ignorado ? 4 : 0) | (usar_lqr ? 8 : 0) | ((fase & 0x0F) << 4);
  uint32_t ms = millis();
  memcpy(b + 3, &n_tramas, 4);
  memcpy(b + 7, &ms, 4);
  float f[9] = {th_out[0], th_out[1], th_ley[0], th_ley[1], I[0], I[1], r_tel[0], r_tel[1], x_rx};
  memcpy(b + 11, f, 36);
  uint16_t malas16 = (uint16_t)(n_malas & 0xFFFF);
  memcpy(b + 47, &descartadas, 2);
  memcpy(b + 49, &malas16, 2);
  memcpy(b + 51, &loop_max_us, 4);
  loop_max_us = 0;
  uint8_t x = 0;
  for (int i = 1; i <= 54; i++) x ^= b[i];
  b[55] = x;
  b[56] = 0x66;
  Serial.write(b, 57);
}

// Referencia circular de radio R (con rampa de RAMPA_S) y periodo T, en el instante t.
void refCirculo(float R, float T, float t, float r[2], float vr[2], float ff[2]) {
  float w = SENTIDO * 2.0f * PI / T;
  float Rk = R * fminf(1.0f, t / RAMPA_S);
  float ang = w * t;
  r[0] = Rk * cosf(ang);          r[1] = Rk * sinf(ang);
  vr[0] = -Rk * w * sinf(ang);    vr[1] = Rk * w * cosf(ang);
  for (int e = 0; e < 2; e++) {
    float a_ref = -w * w * r[e];                              // mm/s^2
    ff[e] = -a_ref / (C_ROD * G_MM) * 180.0f / PI;            // deg
  }
}

// Bit pseudoaleatorio (LFSR de 16 bits, polinomio x^16+x^14+x^13+x^11+1).
int bitPRBS(int e) {
  uint16_t b = ((lfsr[e] >> 0) ^ (lfsr[e] >> 2) ^ (lfsr[e] >> 3) ^ (lfsr[e] >> 5)) & 1u;
  lfsr[e] = (lfsr[e] >> 1) | (b << 15);
  return b;
}

// Ensayo automatico: referencia y perturbacion en el instante t (s). Devuelve false al terminar.
bool refEnsayo(float t, float r[2], float vr[2], float ff[2], float dth[2], bool &circulo) {
  r[0] = r[1] = vr[0] = vr[1] = ff[0] = ff[1] = dth[0] = dth[1] = 0.0f;
  circulo = false;
  if (t < 5.0f) { fase = 1; return true; }
  if (t < 25.0f) {
    fase = 2;
    int k = (int)((t - 5.0f) / 4.0f);       // 0..4
    if (k == 0) r[0] = ESC_MM;
    else if (k == 1) r[0] = -ESC_MM;
    else if (k == 2) r[1] = ESC_MM;
    else if (k == 3) r[1] = -ESC_MM;
    return true;
  }
  if (t < 45.0f) {
    fase = 3;
    if (n_dither <= 0) {
      for (int e = 0; e < 2; e++) dither[e] = bitPRBS(e) ? DITHER_DEG : -DITHER_DEG;
      n_dither = DITHER_CUADROS;
    }
    n_dither--;
    dth[0] = dither[0];  dth[1] = dither[1];
    return true;
  }
  if (t < 57.0f) { fase = 4; circulo = true; refCirculo(50.0f, 6.0f, t - 45.0f, r, vr, ff); return true; }
  if (t < 65.0f) { fase = 5; circulo = true; refCirculo(50.0f, 4.0f, t - 57.0f, r, vr, ff); return true; }
  if (t < 70.0f) { fase = 6; return true; }
  fase = 0;
  return false;
}

// ------------------------------------------------------------ Setup ---
void setup() {
  Serial.begin(BAUD);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BTN, INPUT_PULLUP);
  digitalWrite(PIN_LED, LOW);
  for (int e = 0; e < 2; e++) {
    servo[e].setPeriodHertz(50);
    servo[e].attach(e == 0 ? PIN_X : PIN_Y, 500, 2500);
  }
  platoHorizontal();
  t_ultima = millis();
}

// ------------------------------------------------------------- Loop ---
void loop() {
  static uint32_t us_prev = micros();
  uint32_t us_ahora = micros();
  if (us_ahora - us_prev > loop_max_us) loop_max_us = us_ahora - us_prev;
  us_prev = us_ahora;
  uint32_t ahora = millis();

  // Boton BOOT: arma / desarma (con antirrebote)
  static bool btn_prev = HIGH;
  static uint32_t t_btn = 0;
  bool btn = digitalRead(PIN_BTN);
  if (btn == LOW && btn_prev == HIGH && ahora - t_btn > 300) {
    paso = (paso + 1) % 7;
    const int MODO_DE_PASO[7] = {0, 1, 1, 2, 2, 3, 3};
    modo = MODO_DE_PASO[paso];
    usar_lqr = (paso > 0) && (paso % 2 == 0);
    armado = (modo > 0);
    t_circ = 0.0f;
    t_ens = 0.0f;  fase = 0;  n_dither = 0;
    t_btn = ahora;
    for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; borrarPasadas(e); }   // sin integral al cambiar de modo
    hay_prev = false;
  }
  btn_prev = btn;

  if (leerTrama()) {
    n_tramas++;
    t_ultima = ahora;
    uint8_t estado = buf[1];
    float v[4];
    memcpy(v, &buf[2], 16);          // x, y, vx, vy (little-endian, igual que la ESP32)
    sat_e[0] = sat_e[1] = false;
    ignorado = false;
    if (!armado || estado == 0) {
      haciaHorizontal();
      th_ley[0] = th_ley[1] = 0.0f;
      r_tel[0] = r_tel[1] = 0.0f;
    } else {
      bool salto = hay_prev && (fabsf(v[0] - x_prev[0]) > SALTO_MM || fabsf(v[1] - x_prev[1]) > SALTO_MM);
      if (salto && saltos_seguidos < 3) {
        n_saltos++;                // se ignora el cuadro; el plato queda donde estaba
        saltos_seguidos++;
        ignorado = true;
      } else {
        saltos_seguidos = 0;       // 3 saltos seguidos: la bola de verdad esta en otro lado
        if (salto) { for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; borrarPasadas(e); } }
        // Referencia: centro (modo 1), circulo (modo 2) o ensayo automatico (modo 3)
        float r[2] = {REF[0], REF[1]}, vr[2] = {0, 0}, ff[2] = {0, 0}, dth[2] = {0, 0};
        bool circulo = false;
        if (modo == 2) {
          t_circ += TS;
          circulo = true;
          refCirculo(R_CIRC, T_CIRC, t_circ, r, vr, ff);
        } else if (modo == 3) {
          t_ens += TS;
          if (!refEnsayo(t_ens, r, vr, ff, dth, circulo)) {
            modo = 1;                      // termino el ensayo: queda en CENTRO
            paso = usar_lqr ? 2 : 1;       // con el mismo controlador (la proxima pulsacion sigue desde ahi)
            for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; borrarPasadas(e); }
          }
        } else {
          fase = 0;
        }
        for (int e = 0; e < 2; e++) {
          float xh = SIGNO_VIS[e] * v[e];
          float vh = SIGNO_VIS[e] * v[2 + e];
          if (circulo && !usar_lqr) xh += vh * TAU_PRED;   // PID: prediccion; el LQR ya la tiene en la ley
          float th = leyControl(e, xh, vh, r[e], vr[e], ff[e], modo == 1);
          th_ley[e] = th;
          r_tel[e] = r[e];
          float th_tot = th + dth[e];             // perturbacion del ensayo (0 fuera de la fase 3)
          if (th_tot > TH_LIM) th_tot = TH_LIM;
          if (th_tot < -TH_LIM) th_tot = -TH_LIM;
          moverConLimite(e, th_tot);
          empujarPasada(e, th_out[e]);            // lo que realmente se mando (tras el limite de velocidad)
        }
        x_prev[0] = v[0];  x_prev[1] = v[1];  hay_prev = true;
      }
    }
    enviarTelemetria(v[0]);
  }

  // Watchdog
  bool sin_tramas = (ahora - t_ultima) > WATCHDOG_MS;
  if (sin_tramas) {
    static uint32_t t_wd = 0;
    if (ahora - t_wd > 33) { t_wd = ahora; haciaHorizontal(); }
  }

  // LED: sin tramas = parpadeo rapido continuo; desarmado = apagado; armado = N destellos (N = paso)
  if (sin_tramas) digitalWrite(PIN_LED, (ahora / 100) % 2);
  else if (!armado) digitalWrite(PIN_LED, LOW);
  else {
    // tantos destellos como el numero del paso (120 ms encendido cada 300 ms) y pausa: ciclo de 2,4 s
    uint32_t t = ahora % 2400;
    digitalWrite(PIN_LED, (t / 300) < (uint32_t)paso && (t % 300) < 120);
  }
}
