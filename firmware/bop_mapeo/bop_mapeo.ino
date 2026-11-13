// bop_mapeo.ino  -  SOLO EL ENSAYO AUTOMATICO, con una pulsacion de BOOT (2026-11-13)
//
// Copia de bop_prueba_circulo_lazo.ino (mismo controlador, tabla, trim, telemetria y
// protecciones). La unica diferencia es el boton BOOT:
//   DESARMADO (LED apagado)  --BOOT-->  ENSAYO elegido en MODO_BOOT  --BOOT-->  DESARMADO
// MODO_BOOT = 4: mapeo completo (~20,5 min, LED doble destello)
// MODO_BOOT = 3: ensayo automatico corto (90 s, LED destellos cortos)
// Al terminar el ensayo queda en CENTRO (LED fijo); otra pulsacion desarma.
// El controlador se elige con CONJUNTO (1 rediseno, 0 original), igual que en el original.
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
//   -> ENSAYO AUTOMATICO (LED destellos cortos, 90 s, ver "Ensayo automatico")
//   -> MAPEO COMPLETO (LED doble destello, ~20,5 min, ver "Mapeo completo") -> DESARMADO
//   Al terminar el ensayo o el mapeo pasa solo a CENTRO.
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

// --------------------------------------------- Controlador (Etapa C, C1) ---
// Unidades: mm, mm/s, GRADOS de plato. Valores de etapaC (2026-11-04).
// (2026-11-13) Dos juegos de ganancias para comparar en el prototipo (CONJUNTO):
//  0 = ORIGINAL (Etapa C, disenado para c = 0,714 y te = 0,13 s). Con el retardo real
//      (~0,44 s) el analisis lineal da PM 12 deg con c = 0,2 e inestable con c = 0,57.
//  1 = REDISENO con el modelo identificado (B3): asignacion de polos igual que en C1
//      (zeta 0,7, a = 1) con c = 0,3 y te = 0,44 s; PM >= 31 deg y GM >= 5 dB para c en
//      [0,15; 0,57]. Mas lento (simulacion: centra desde 80 mm en 7 a 9 s, sin sobrepaso).
// Retardo total ~0,44 s = camara 0,04 + datos de la ESP32 0,07 + orden->bola 0,33 (B3).
const int CONJUNTO = 1;
const int MODO_BOOT = 4;          // 4 = mapeo completo, 3 = ensayo automatico corto
const float KP_SET[2] = {0.034118997f, 0.007274f};   // deg/mm
const float KD_SET[2] = {0.025875847f, 0.018436f};   // deg/(mm/s)
const float KI_SET[2] = {0.022745998f, 0.001455f};   // deg/(mm s)  (rediseno: Ti = 5 s)
const float KP = KP_SET[CONJUNTO];
const float KD = KD_SET[CONJUNTO];
const float KI = KI_SET[CONJUNTO];
// Compensacion de la zona muerta de la transmision (~1 deg en B3, igual con las dos bolas):
// si el error supera ZONA_MM, se suma sign(u)*COMP_DB a la inclinacion pedida.
const float COMP_DB = 1.0f;   // deg (0 = sin compensacion)
// (2026-11-13) Despegue: en el mapeo sesion_20261113_121542 la bola de ping pong quedo
// quieta 80 s con el plato pedido a ~2 deg y 100 s con 4,2 deg (la camara si veia la bola:
// misma area y circularidad). Si la bola esta quieta lejos de la referencia, se suma una
// inclinacion extra que crece a DESP_RATE hasta DESP_MAX y se quita al moverse.
const float DESP_RATE = 1.0f;   // deg/s
const float DESP_MAX  = 5.0f;   // deg
const float DESP_V    = 5.0f;   // mm/s: por debajo, la bola se considera quieta
float desp[2] = {0, 0};
const float TS     = 1.0f / 30.0f;   // s (periodo de diseno)
const float TH_LIM = 10.0f;          // deg, saturacion de la inclinacion pedida
const float E_CLIP = 30.0f;          // mm, recorte del error del integrador
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
//   fase 2   5-45  escalones de referencia de ESC_MM: +X, -X, +Y, -Y y centro, T_ESC = 8 s c/u
//   (las fases siguientes se corren 20 s respecto de la version con escalones de 4 s; total 90 s)
//   fase 3  25-45  centro + perturbacion pseudoaleatoria de +-DITHER_DEG en cada eje,
//                  cambia cada DITHER_CUADROS cuadros (para identificar: entrada conocida
//                  e independiente del ruido)
//   fase 4  45-57  circulo de 50 mm, 6 s por vuelta (2 vueltas)
//   fase 5  57-65  circulo de 50 mm, 4 s por vuelta (2 vueltas)
//   fase 6  65-70  centro; al terminar pasa solo a modo CENTRO
// La fase va en los bits 4-7 de las banderas de la telemetria.
const float ESC_MM = 40.0f;
const float T_ESC = 8.0f;         // s por escalon (2026-11-13: con 4 s ningun controlador se establecia)
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
const float E_ZONA   = 40.0f;        // mm: solo se integra con |error| menor que esto
const float I_MAX    = 3.0f;         // deg: tope del integrador
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
const float TH_TRIM[2] = {0.45f, 1.2f};   // deg, ejes X e Y
const float US_NEUTRO = 1500.0f;
const float US_POR_GRADO = 1000.0f / 90.0f;

// ------------------------------------------------------------- Estado ---
Servo servo[2];
float I[2]  = {0, 0};     // integrador (deg)
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
  for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; th_out[e] = 0; moverPlato(e, 0.0f); }
}

void haciaHorizontal() {           // con rampa: sin bola, sin tramas, desarmado
  for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; moverConLimite(e, 0.0f); }
  hay_prev = false;
}

// Misma ley que bop_ley_control.m (usar_aw = saturar = true), en grados.
// Zona de tolerancia (solo en modo CENTRO, 2026-11-13, pedido del equipo): con la bola a
// menos de ZONA_MM de la referencia en un eje, el proporcional de ese eje vale 0 y el
// integrador no suma. Fuera de la zona el error se cuenta desde su borde (sin salto).
// Evita que el integrador acumule de a poco hasta despegar la bola de golpe (rozamiento).
// OJO: con zona, el error estacionario puede llegar a ZONA_MM (el requisito R3 es 3 mm).
const float ZONA_MM = 5.0f;
float leyControl(int e, float xh, float vh, float r, float vref, float th_ff, bool zona) {
  float eps = xh - r;
  bool en_zona = false;
  if (zona) {
    if (fabsf(eps) <= ZONA_MM) { eps = 0.0f; en_zona = true; }
    else eps = (eps > 0) ? eps - ZONA_MM : eps + ZONA_MM;
  }
  float u = KP * eps + I[e] + KD * (vh - vref) + th_ff;
  float eps_bruto = xh - r;
  // compensacion de zona muerta SUAVE (2026-11-13): la version con signo saltaba de +1 a
  // -1 deg cuando u cruzaba 0 y el plato vibraba +-1 deg cuadro a cuadro (log 132508).
  if (COMP_DB > 0.0f && fabsf(eps_bruto) > ZONA_MM) {
    float k = u / 0.3f;                            // llega a la compensacion completa con |u| = 0,3 deg
    if (k > 1.0f) k = 1.0f;
    if (k < -1.0f) k = -1.0f;
    u += COMP_DB * k;
  }
  // despegue: bola quieta lejos de la referencia -> inclinacion extra creciente
  if (fabsf(vh) < DESP_V && fabsf(eps_bruto) > 2.0f * ZONA_MM) {
    float sg = (eps_bruto > 0) ? 1.0f : -1.0f;      // el plato sube del lado de la bola
    desp[e] += sg * DESP_RATE * TS;
    if (desp[e] > DESP_MAX) desp[e] = DESP_MAX;
    if (desp[e] < -DESP_MAX) desp[e] = -DESP_MAX;
  } else {
    desp[e] *= 0.7f;                               // se quita en ~0,1 s al moverse
  }
  u += desp[e];
  float th = u;
  if (th > TH_LIM) th = TH_LIM;
  if (th < -TH_LIM) th = -TH_LIM;
  bool saturado = (th != u);
  sat_e[e] = saturado;
  bool congelar = saturado && ((eps > 0) - (eps < 0)) == ((u > 0) - (u < 0));
  if (fabsf(vh) < V_INT) nq[e]++; else nq[e] = 0;
  if (fabsf(eps) >= E_ZONA) I[e] *= (1.0f - TS / TAU_DESCARGA);   // descarga lejos de la referencia
  if (!congelar && !en_zona && nq[e] >= (NQ > 1 ? NQ : 1) && fabsf(eps) < E_ZONA) {
    float ec = eps;
    if (ec > E_CLIP) ec = E_CLIP;
    if (ec < -E_CLIP) ec = -E_CLIP;
    I[e] += KI * TS * ec;
    if (I[e] > I_MAX) I[e] = I_MAX;
    if (I[e] < -I_MAX) I[e] = -I_MAX;
  }
  return th;
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
  b[2] = (sat_e[0] ? 1 : 0) | (sat_e[1] ? 2 : 0) | (ignorado ? 4 : 0) | ((fase & 0x0F) << 4);
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
void refCirculoS(float R, float T, float sentido, float t, float r[2], float vr[2], float ff[2]) {
  float w = sentido * 2.0f * PI / T;
  float Rk = R * fminf(1.0f, t / RAMPA_S);
  float ang = w * t;
  r[0] = Rk * cosf(ang);          r[1] = Rk * sinf(ang);
  vr[0] = -Rk * w * sinf(ang);    vr[1] = Rk * w * cosf(ang);
  for (int e = 0; e < 2; e++) {
    float a_ref = -w * w * r[e];                              // mm/s^2
    ff[e] = -a_ref / (C_ROD * G_MM) * 180.0f / PI;            // deg
  }
}

void refCirculo(float R, float T, float t, float r[2], float vr[2], float ff[2]) {
  refCirculoS(R, T, SENTIDO, t, r, vr, ff);
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
  if (t < 5.0f + 5.0f * T_ESC) {
    fase = 2;
    int k = (int)((t - 5.0f) / T_ESC);       // 0..4
    if (k == 0) r[0] = ESC_MM;
    else if (k == 1) r[0] = -ESC_MM;
    else if (k == 2) r[1] = ESC_MM;
    else if (k == 3) r[1] = -ESC_MM;
    return true;
  }
  float t3 = 5.0f + 5.0f * T_ESC;            // inicio de la fase 3
  if (t < t3 + 20.0f) {
    fase = 3;
    if (n_dither <= 0) {
      for (int e = 0; e < 2; e++) dither[e] = bitPRBS(e) ? DITHER_DEG : -DITHER_DEG;
      n_dither = DITHER_CUADROS;
    }
    n_dither--;
    dth[0] = dither[0];  dth[1] = dither[1];
    return true;
  }
  if (t < t3 + 32.0f) { fase = 4; circulo = true; refCirculo(50.0f, 6.0f, t - (t3 + 20.0f), r, vr, ff); return true; }
  if (t < t3 + 40.0f) { fase = 5; circulo = true; refCirculo(50.0f, 4.0f, t - (t3 + 32.0f), r, vr, ff); return true; }
  if (t < t3 + 45.0f) { fase = 6; return true; }
  fase = 0;
  return false;
}


// ------------------------------------------ Mapeo completo (modo 4) ---
// (2026-11-13, pedido del equipo) Secuencia automatica de ~20,5 min que recorre el plato
// sin tocar los bordes. Segmentos (la fase de la telemetria indica el tipo):
//   fase 7  PUNTO   : referencia a (a, b), con rampa de RAMPA_REF_MM_S
//   fase 8  CIRCULO : radio a, periodo b, sentido c (+1/-1), centrado en (0, 0)
//   fase 9  DITHER  : referencia en (a, b) + perturbacion pseudoaleatoria de +-c deg
//   fase 10 LISSAJOUS (figura de ocho): x = a sin(wt), y = b sin(2wt), periodo c
//   fase 11 PAUSA DE SEGURIDAD: la bola paso de LIM_SEG_MM (100 mm); se la lleva al centro y el
//           ensayo sigue cuando esta a menos de 30 mm y casi quieta (el reloj se detiene).
// Al terminar pasa solo a CENTRO.
const float LIM_SEG_MM = 100.0f;   // simulacion del mapeo (retardo 0,44 s, zona muerta 1 deg, los
                                   // dos controladores, c 0,2 y 0,57): |x| max 91 a 98 mm (borde ~129)
const float RAMPA_REF_MM_S = 50.0f;
struct Seg { uint8_t tipo; float a, b, c, dur; };
const int NSEG_MAX = 140;
Seg segs[NSEG_MAX];
int nseg = 0;
float t_seg = 0.0f;      // s dentro del segmento actual
int iseg = 0;
bool pausa = false;
float t_pausa = 0.0f;     // s en la pausa actual (maximo T_PAUSA_MAX)
const float T_PAUSA_MAX = 30.0f;
float r_map[2] = {0, 0};  // referencia con rampa (PUNTO y DITHER)
uint16_t n_pausas = 0;

void agregar(uint8_t tipo, float a, float b, float c, float dur) {
  if (nseg < NSEG_MAX) { segs[nseg].tipo = tipo; segs[nseg].a = a; segs[nseg].b = b; segs[nseg].c = c; segs[nseg].dur = dur; nseg++; }
}

void armarMapeo() {
  nseg = 0;
  agregar(0, 0, 0, 0, 10);                                   // centro
  // 1) cuadricula 5 x 5 en zigzag (-60 a 60 mm), 20 s por punto
  const float G[5] = {-60, -30, 0, 30, 60};
  for (int iy = 0; iy < 5; iy++)
    for (int k = 0; k < 5; k++) {
      int ix = (iy % 2 == 0) ? k : 4 - k;
      agregar(0, G[ix], G[iy], 0, 20);
    }
  agregar(0, 0, 0, 0, 15);
  // 2) escalones radiales de 60 mm en 8 direcciones (ida 12 s, vuelta 12 s)
  for (int d = 0; d < 8; d++) {
    float ang = d * PI / 4.0f;
    agregar(0, 60.0f * cosf(ang), 60.0f * sinf(ang), 0, 12);
    agregar(0, 0, 0, 0, 12);
  }
  // 3) circulos: radios 20, 35, 50 mm; periodos 8, 6, 4 s; dos sentidos; 3 vueltas cada uno
  const float RR[3] = {20, 35, 50};
  const float TT[3] = {8, 6, 4};
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      if (RR[i] > 40.0f && TT[j] < 5.0f) continue;   // 50 mm a 4 s: la bola sale a ~75 mm (simulacion)
      for (int sgn = 0; sgn < 2; sgn++)
        agregar(1, RR[i], TT[j], sgn == 0 ? 1.0f : -1.0f, 3.0f * TT[j]);
    }
    agregar(0, 0, 0, 0, 5);
  }
  // 4) perturbacion conocida: en el centro con tres amplitudes y en cuatro puntos con 1,5 deg
  agregar(2, 0, 0, 1.0f, 20);
  agregar(2, 0, 0, 1.5f, 20);
  agregar(2, 40, 0, 1.5f, 20);    // (2 y 2,5 deg y los puntos a 50 mm acercaban la bola al
  agregar(2, -40, 0, 1.5f, 20);   //  borde en simulacion)
  agregar(2, 0, 40, 1.5f, 20);
  agregar(2, 0, -40, 1.5f, 20);
  agregar(0, 0, 0, 0, 10);
  // 5) figura de ocho 50 x 35 mm, periodos 10 y 7 s, 3 ciclos cada una
  agregar(3, 50, 35, 10, 30);
  agregar(0, 0, 0, 0, 8);
  agregar(3, 50, 35, 7, 21);
  agregar(0, 0, 0, 0, 10);                                   // final en el centro
}

// Referencia del mapeo en este cuadro. Devuelve false al terminar la secuencia.
bool refMapeo(float xb, float yb, float vxb, float vyb, float r[2], float vr[2], float ff[2],
              float dth[2], bool &circulo) {
  r[0] = r[1] = vr[0] = vr[1] = ff[0] = ff[1] = dth[0] = dth[1] = 0.0f;
  circulo = false;
  // pausa de seguridad
  if (!pausa && (fabsf(xb) > LIM_SEG_MM || fabsf(yb) > LIM_SEG_MM)) { pausa = true; n_pausas++; t_pausa = 0.0f; }
  if (pausa) {
    fase = 11;
    t_pausa += TS;
    if ((hypotf(xb, yb) < 30.0f && hypotf(vxb, vyb) < 20.0f) || t_pausa > T_PAUSA_MAX) {
      pausa = false; r_map[0] = xb; r_map[1] = yb;           // sigue (por llegar o por tiempo)
    }
    return true;                                             // referencia (0, 0); el reloj no avanza
  }
  if (iseg >= nseg) { fase = 0; return false; }
  Seg &S = segs[iseg];
  float t = t_seg;
  if (S.tipo == 0 || S.tipo == 2) {                          // PUNTO / DITHER: referencia con rampa
    fase = (S.tipo == 0) ? 7 : 9;
    float obj[2] = {S.a, S.b};
    for (int e = 0; e < 2; e++) {
      float d = obj[e] - r_map[e], paso = RAMPA_REF_MM_S * TS;
      if (d > paso) d = paso;
      if (d < -paso) d = -paso;
      r_map[e] += d;
      r[e] = r_map[e];
    }
    if (S.tipo == 2) {
      if (n_dither <= 0) {
        for (int e = 0; e < 2; e++) dither[e] = bitPRBS(e) ? S.c : -S.c;
        n_dither = DITHER_CUADROS;
      }
      n_dither--;
      dth[0] = dither[0];  dth[1] = dither[1];
    }
  } else if (S.tipo == 1) {                                  // CIRCULO
    fase = 8;  circulo = true;
    refCirculoS(S.a, S.b, S.c, t, r, vr, ff);
    r_map[0] = r[0];  r_map[1] = r[1];
  } else {                                                   // LISSAJOUS (figura de ocho)
    fase = 10;  circulo = true;
    float w = 2.0f * PI / S.c;
    float k = fminf(1.0f, t / RAMPA_S);
    float Ax = k * S.a, Ay = k * S.b;
    r[0] = Ax * sinf(w * t);               r[1] = Ay * sinf(2.0f * w * t);
    vr[0] = Ax * w * cosf(w * t);          vr[1] = 2.0f * Ay * w * cosf(2.0f * w * t);
    float a_ref[2] = {-w * w * r[0], -4.0f * w * w * r[1]};
    for (int e = 0; e < 2; e++) ff[e] = -a_ref[e] / (C_ROD * G_MM) * 180.0f / PI;
    r_map[0] = r[0];  r_map[1] = r[1];
  }
  t_seg += TS;
  if (t_seg >= S.dur) { t_seg = 0.0f; iseg++; }
  return true;
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
  armarMapeo();
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
    modo = (modo == 0) ? MODO_BOOT : 0;    // una pulsacion arranca el ensayo; otra desarma
    armado = (modo > 0);
    t_circ = 0.0f;
    t_ens = 0.0f;  fase = 0;  n_dither = 0;
    iseg = 0;  t_seg = 0.0f;  pausa = false;  r_map[0] = r_map[1] = 0.0f;
    t_btn = ahora;
    for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; }   // sin integral al cambiar de modo
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
        if (salto) { for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; } }
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
            for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; }
          }
        } else if (modo == 4) {
          if (!refMapeo(SIGNO_VIS[0] * v[0], SIGNO_VIS[1] * v[1], SIGNO_VIS[0] * v[2], SIGNO_VIS[1] * v[3],
                        r, vr, ff, dth, circulo)) {
            modo = 1;                      // termino el mapeo: queda en CENTRO
            for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; }
          }
        } else {
          fase = 0;
        }
        for (int e = 0; e < 2; e++) {
          float xh = SIGNO_VIS[e] * v[e];
          float vh = SIGNO_VIS[e] * v[2 + e];
          if (circulo) xh += vh * TAU_PRED;       // donde estara la bola cuando actue el plato
          float th = leyControl(e, xh, vh, r[e], vr[e], ff[e], modo == 1);
          th_ley[e] = th;
          r_tel[e] = r[e];
          float th_tot = th + dth[e];             // perturbacion del ensayo (0 fuera de la fase 3)
          if (th_tot > TH_LIM) th_tot = TH_LIM;
          if (th_tot < -TH_LIM) th_tot = -TH_LIM;
          moverConLimite(e, th_tot);
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

  // LED: centro = encendido; circulo = parpadeo lento; sin tramas = parpadeo rapido; desarmado = apagado
  if (sin_tramas) digitalWrite(PIN_LED, (ahora / 100) % 2);
  else if (modo == 2) digitalWrite(PIN_LED, (ahora / 500) % 2);
  else if (modo == 3) digitalWrite(PIN_LED, ((ahora / 150) % 4) == 0);   // destellos cortos
  else if (modo == 4) digitalWrite(PIN_LED, (ahora % 1000) < 100 || ((ahora % 1000) >= 200 && (ahora % 1000) < 300)); // doble destello
  else digitalWrite(PIN_LED, armado ? HIGH : LOW);
}
