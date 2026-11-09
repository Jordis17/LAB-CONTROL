// bop_prueba_lazo.ino  -  PRUEBA FUNCIONAL del lazo cerrado Ball on Plate (ESP32)
//
// Version escrita a mano para probar el sistema completo antes de las Etapas E-G.
// La ley de control es la MISMA que etapaC/funciones/bop_ley_control.m (la del MIL);
// en la Etapa H se reemplaza por el codigo generado desde Controller_BoP.slx.
//
// Cadena:  trama serie (vision + Kalman en la PC)  ->  controlador PID con
//          integracion condicional (por eje)  ->  angulo de plato pedido
//          ->  tabla medida plato -> comando de servo  ->  pulso PWM
//
// Seguridad:
//   - Arranca DESARMADO: plato horizontal (neutro de la tabla), LED apagado.
//   - Boton BOOT (GPIO0): arma / desarma. LED azul (GPIO2) encendido = armado.
//   - Watchdog: si no llega una trama valida en 200 ms -> plato horizontal,
//     integradores a cero, LED parpadeando rapido.
//   - estado = 0 en la trama (sin bola) -> plato horizontal e integradores a cero.
//
// Necesita la libreria ESP32Servo. Placa: "ESP32 Dev Module".
// El puerto serie lo usa la PC (main_vision.py): cerrar el Monitor Serie del IDE.

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
const float KP     = 0.034118997f;   // deg/mm
const float KD     = 0.025875847f;   // deg/(mm/s)
const float KI     = 0.022745998f;   // deg/(mm s)
const float TS     = 1.0f / 30.0f;   // s (periodo de diseno)
const float TH_LIM = 10.0f;          // deg, saturacion de la inclinacion pedida
const float E_CLIP = 30.0f;          // mm, recorte del error del integrador
const float V_INT  = 25.0f;          // mm/s, umbral de bola quieta
const int   NQ     = 4;              // cuadros quieta antes de integrar
float REF[2] = {0.0f, 0.0f};         // referencia (mm): centro del plato

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
const float US_NEUTRO = 1500.0f;
const float US_POR_GRADO = 1000.0f / 90.0f;

// ------------------------------------------------------------- Estado ---
Servo servo[2];
float I[2]  = {0, 0};     // integrador (deg)
int   nq[2] = {0, 0};     // cuadros con la bola quieta
bool  armado = false;
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

void platoHorizontal() {
  for (int e = 0; e < 2; e++) { I[e] = 0; nq[e] = 0; moverPlato(e, 0.0f); }
}

// Misma ley que bop_ley_control.m (usar_aw = saturar = true), en grados.
float leyControl(int e, float xh, float vh, float r) {
  float eps = xh - r;
  float u = KP * eps + I[e] + KD * vh;
  float th = u;
  if (th > TH_LIM) th = TH_LIM;
  if (th < -TH_LIM) th = -TH_LIM;
  bool saturado = (th != u);
  bool congelar = saturado && ((eps > 0) - (eps < 0)) == ((u > 0) - (u < 0));
  if (fabsf(vh) < V_INT) nq[e]++; else nq[e] = 0;
  if (!congelar && nq[e] >= (NQ > 1 ? NQ : 1)) {
    float ec = eps;
    if (ec > E_CLIP) ec = E_CLIP;
    if (ec < -E_CLIP) ec = -E_CLIP;
    I[e] += KI * TS * ec;
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
    armado = !armado;
    t_btn = ahora;
    platoHorizontal();   // al cambiar de modo, siempre desde horizontal y sin integral
  }
  btn_prev = btn;

  if (leerTrama()) {
    n_tramas++;
    t_ultima = ahora;
    uint8_t estado = buf[1];
    float v[4];
    memcpy(v, &buf[2], 16);          // x, y, vx, vy (little-endian, igual que la ESP32)
    if (!armado || estado == 0) {
      platoHorizontal();
    } else {
      for (int e = 0; e < 2; e++) {
        float xh = SIGNO_VIS[e] * v[e];
        float vh = SIGNO_VIS[e] * v[2 + e];
        float th = leyControl(e, xh, vh, REF[e]);
        moverPlato(e, th);
      }
    }
  }

  // Watchdog
  bool sin_tramas = (ahora - t_ultima) > WATCHDOG_MS;
  if (sin_tramas) {
    static uint32_t t_wd = 0;
    if (ahora - t_wd > 100) { t_wd = ahora; platoHorizontal(); }
  }

  // LED: armado = encendido; sin tramas = parpadeo rapido; desarmado = apagado
  if (sin_tramas) digitalWrite(PIN_LED, (ahora / 100) % 2);
  else digitalWrite(PIN_LED, armado ? HIGH : LOW);
}
