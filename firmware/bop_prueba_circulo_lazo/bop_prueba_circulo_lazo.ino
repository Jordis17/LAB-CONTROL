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
//   DESARMADO (LED apagado) -> CENTRO (LED encendido) -> CIRCULO (LED parpadeo lento) -> DESARMADO
// Al entrar en CIRCULO el radio crece en rampa durante RAMPA_S segundos.
// Lo demas (watchdog, sin bola, filtro de saltos, limite de velocidad) es igual al v2.
//
// Uso: igual que el v2, con main_vision.py mandando las tramas (921600 baud).
//
#include <ESP32Servo.h>
#include <math.h>

// ---------------------------------------------------------------- Pines ---
const int PIN_X   = 18;   // senal servo X
const int PIN_Y   = 19;   // senal servo Y
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
const float KP     = 0.034118997f;   // deg/mm
const float KD     = 0.025875847f;   // deg/(mm/s)
const float KI     = 0.022745998f;   // deg/(mm s)
const float TS     = 1.0f / 30.0f;   // s (periodo de diseno)
const float TH_LIM = 10.0f;          // deg, saturacion de la inclinacion pedida
const float E_CLIP = 30.0f;          // mm, recorte del error del integrador
const float V_INT  = 25.0f;          // mm/s, umbral de bola quieta
const int   NQ     = 4;              // cuadros quieta antes de integrar
float REF[2] = {0.0f, 0.0f};         // referencia (mm): centro del plato

// ------------------------------------------------ Trayectoria circular ---
const float R_CIRC  = 60.0f;   // mm, radio (el util del plato es +-127 mm)
const float T_CIRC  = 4.0f;    // s por vuelta (mas lento = mas facil de seguir)
const float SENTIDO = 1.0f;    // +1 antihorario, -1 horario (en el marco de la vision)
const float RAMPA_S = 3.0f;    // s para que el radio llegue a R_CIRC
const float C_ROD   = 5.0f / 7.0f;    // rodadura nominal (Etapa A; PENDIENTE identificar en B1)
const float G_MM    = 9810.0f;        // mm/s^2
const float TAU_PRED = 0.075f; // s: compensacion del retardo de la camara en modo circulo
                               // (x_pred = x_hat + v_hat * TAU_PRED). 0 = sin compensacion.
                               // Latencia medida ~60 ms + medio cuadro de calculo.
int   modo = 0;                // 0 desarmado, 1 centro, 2 circulo
float t_circ = 0.0f;           // s desde que se entro al modo circulo (cuenta por trama)
// --- v2: protecciones de la prueba funcional
const float SLEW_DEG = 3.0f;         // deg por cuadro (= 90 deg/s a 30 fps)
const float E_ZONA   = 40.0f;        // mm: solo se integra con |error| menor que esto
const float I_MAX    = 3.0f;         // deg: tope del integrador
const float SALTO_MM = 60.0f;        // mm por cuadro (1800 mm/s): mas que esto es una falsa deteccion

// ---------------------- Relacion servo -> plato MEDIDA (2026-11-04, v2) ---
// datos_prototipo/mecanica/servo_plato_v2_convencion_plato.csv
// comando del servo (grados respecto de 1500 us)  ->  inclinacion del plato (deg),
// convencion: th > 0 levanta el lado del servo. Un comando positivo BAJA el lado.
const int NTAB = 9;
const float CMD_TAB[NTAB] = {-40, -30, -20, -10, 0, 10, 20, 30, 40};
const float TH_TAB[2][NTAB] = {
  {22.4f, 18.9f, 12.3f, 6.1f, 1.3f, -3.9f, -6.9f, -9.2f, -12.1f},   // eje X
  {25.9f, 20.8f, 14.9f, 9.2f, 3.5f, -1.5f, -5.8f, -8.5f, -11.3f}    // eje Y
};
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
  float c = comandoDesdePlato(e, th_deg);
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
float leyControl(int e, float xh, float vh, float r, float vref, float th_ff) {
  float eps = xh - r;
  float u = KP * eps + I[e] + KD * (vh - vref) + th_ff;
  float th = u;
  if (th > TH_LIM) th = TH_LIM;
  if (th < -TH_LIM) th = -TH_LIM;
  bool saturado = (th != u);
  bool congelar = saturado && ((eps > 0) - (eps < 0)) == ((u > 0) - (u < 0));
  if (fabsf(vh) < V_INT) nq[e]++; else nq[e] = 0;
  if (!congelar && nq[e] >= (NQ > 1 ? NQ : 1) && fabsf(eps) < E_ZONA) {
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
bool leerTrama() {
  while (Serial.available()) {
    uint8_t b = Serial.read();
    if (nbuf == 0 && b != 0xAA) continue;
    buf[nbuf++] = b;
    if (nbuf == 20) {
      nbuf = 0;
      uint8_t x = 0;
      for (int i = 1; i <= 17; i++) x ^= buf[i];
      if (buf[19] == 0x55 && buf[18] == x) return true;
      n_malas++;
      // resincronizar: buscar otro 0xAA dentro de lo recibido
      for (int i = 1; i < 20; i++) {
        if (buf[i] == 0xAA) {
          int k = 0;
          for (int j = i; j < 20; j++) buf[k++] = buf[j];
          nbuf = k;
          break;
        }
      }
    }
  }
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
  uint32_t ahora = millis();

  // Boton BOOT: arma / desarma (con antirrebote)
  static bool btn_prev = HIGH;
  static uint32_t t_btn = 0;
  bool btn = digitalRead(PIN_BTN);
  if (btn == LOW && btn_prev == HIGH && ahora - t_btn > 300) {
    modo = (modo + 1) % 3;
    armado = (modo > 0);
    t_circ = 0.0f;
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
    if (!armado || estado == 0) {
      haciaHorizontal();
    } else {
      bool salto = hay_prev && (fabsf(v[0] - x_prev[0]) > SALTO_MM || fabsf(v[1] - x_prev[1]) > SALTO_MM);
      if (salto && saltos_seguidos < 3) {
        n_saltos++;                // se ignora el cuadro; el plato queda donde estaba
        saltos_seguidos++;
      } else {
        saltos_seguidos = 0;       // 3 saltos seguidos: la bola de verdad esta en otro lado
        if (salto) { for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; } }
        // Referencia: centro (modo 1) o circulo (modo 2)
        float r[2] = {REF[0], REF[1]}, vr[2] = {0, 0}, ff[2] = {0, 0};
        if (modo == 2) {
          t_circ += TS;
          float w = SENTIDO * 2.0f * PI / T_CIRC;
          float Rk = R_CIRC * fminf(1.0f, t_circ / RAMPA_S);
          float ang = w * t_circ;
          r[0] = Rk * cosf(ang);          r[1] = Rk * sinf(ang);
          vr[0] = -Rk * w * sinf(ang);    vr[1] = Rk * w * cosf(ang);
          for (int e = 0; e < 2; e++) {
            float a_ref = -w * w * r[e];                              // mm/s^2
            ff[e] = -a_ref / (C_ROD * G_MM) * 180.0f / PI;            // deg
          }
        }
        for (int e = 0; e < 2; e++) {
          float xh = SIGNO_VIS[e] * v[e];
          float vh = SIGNO_VIS[e] * v[2 + e];
          if (modo == 2) xh += vh * TAU_PRED;     // donde estara la bola cuando actue el plato
          float th = leyControl(e, xh, vh, r[e], vr[e], ff[e]);
          moverConLimite(e, th);
        }
        x_prev[0] = v[0];  x_prev[1] = v[1];  hay_prev = true;
      }
    }
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
  else digitalWrite(PIN_LED, armado ? HIGH : LOW);
}
