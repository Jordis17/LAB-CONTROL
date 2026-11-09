// prueba_circulo_abierto.ino  -  PRUEBA DE MOTORES: bamboleo circular del plato (LAZO ABIERTO)
//
// El plato se inclina siempre la misma cantidad A, pero la direccion de la
// inclinacion gira con periodo T:
//      th_x = A cos(2 pi t / T)      th_y = A sin(2 pi t / T)
// Una bola sobre el plato tiende a seguir una circunferencia de radio
//      R = c g A / w^2      (c = 5/7, g = 9810 mm/s^2, w = 2 pi / T, A en rad)
// Ejemplos para R ~ 60 mm:  T = 3 s -> A ~ 2,2 deg;  T = 2,5 s -> A ~ 3,1 deg;  T = 2 s -> A ~ 4,8 deg.
//
// OJO, lazo abierto: no hay camara ni correccion. La orbita es solo
// marginalmente estable: cualquier diferencia en la condicion inicial se
// convierte en una deriva lenta y la bola termina en el borde. Para reducir
// la deriva, la amplitud sube con una rampa suave (coseno) durante RAMPA_CICLOS
// vueltas: en simulacion (modelo lineal, bola soltada quieta en el centro)
// el centro de la orbita queda corrido ~10 mm con 10 vueltas, contra ~60 mm
// con una rampa lineal. Ademas, un desnivel del plato de 0,2 deg ya acelera
// la bola ~24 mm/s^2 hacia un lado: en lazo abierto la bola SIEMPRE termina
// yendose; esto es para ver los motores, no para controlar la bola. Sirve para
// ver que los dos servos y la tabla servo->plato funcionan juntos, no para
// controlar la bola (eso es el lazo cerrado, bop_prueba_circulo_lazo).
//
// Monitor Serie a 115200, "Ambos NL & CR". Comandos:
//   S        arrancar / detener (al detener, la amplitud baja en rampa y el plato queda horizontal)
//   A 3      amplitud de la inclinacion del plato en grados (0 a 11)
//   T 2.5    periodo de una vuelta en segundos (1 a 10)
//   R        cambia el sentido de giro
//   C        para de inmediato y deja el plato horizontal
// Necesita la libreria ESP32Servo. Placa: "ESP32 Dev Module".

#include <ESP32Servo.h>
#include <math.h>

const int PIN_X = 19;  // (2026-11-09) el servo del lado +X esta en GPIO19 y el del +Y en GPIO18 (estaban cruzados)
const int PIN_Y = 18;
const float RAMPA_CICLOS = 10.0f;  // vueltas que tarda la amplitud en llegar a A (rampa de coseno)
const float A_MAX = 11.0f;         // deg: el plato llega a +-11,3 deg en los dos ejes (tabla medida)

// Relacion servo -> plato MEDIDA (v3, 2026-11-09).
// Convencion: th > 0 levanta el lado del servo. Un comando positivo BAJA el lado.
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

Servo servo[2];
float A = 3.0f;          // deg
float T = 2.5f;          // s
float sentido = 1.0f;
bool  girando = false;
float amp = 0.0f;        // amplitud actual
float u_rampa = 0.0f;    // avance de la rampa: 0 (parado) a 1 (amplitud completa)
float fase = 0.0f;       // rad
uint32_t t_prev = 0, t_info = 0;

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

void radioEsperado() {
  float w = 2.0f * PI / T;
  float R = (5.0f / 7.0f) * 9810.0f * (A * PI / 180.0f) / (w * w);
  Serial.printf("A = %.1f deg, T = %.2f s -> radio esperado de la bola ~ %.0f mm (el util es +-127 mm)\n", A, T, R);
}

void setup() {
  Serial.begin(115200);
  for (int e = 0; e < 2; e++) {
    servo[e].setPeriodHertz(50);
    servo[e].attach(e == 0 ? PIN_X : PIN_Y, 500, 2500);
    moverPlato(e, 0.0f);
  }
  Serial.println("prueba_circulo_abierto: S arranca/detiene, A <deg>, T <s>, R sentido, C horizontal");
  radioEsperado();
  t_prev = millis();
}

void leerComandos() {
  if (!Serial.available()) return;
  String l = Serial.readStringUntil('\n');  l.trim();
  if (l.length() == 0) return;
  char c = toupper(l.charAt(0));
  float v = l.substring(1).toFloat();
  if (c == 'S') { girando = !girando; Serial.println(girando ? "Arranca" : "Deteniendo (rampa)"); }
  else if (c == 'A') { A = constrain(v, 0.0f, A_MAX); radioEsperado(); }
  else if (c == 'T') { T = constrain(v, 1.0f, 10.0f); radioEsperado(); }
  else if (c == 'R') { sentido = -sentido; Serial.println("Sentido invertido"); }
  else if (c == 'C') { girando = false; amp = 0; u_rampa = 0; moverPlato(0, 0); moverPlato(1, 0); Serial.println("Plato horizontal"); }
}

void loop() {
  leerComandos();
  uint32_t ahora = millis();
  if (ahora - t_prev < 20) return;                 // 50 Hz, igual que el PWM de los servos
  float dt = (ahora - t_prev) / 1000.0f;
  t_prev = ahora;

  float du = dt / (RAMPA_CICLOS * T);
  if (girando) u_rampa = fminf(1.0f, u_rampa + du);
  else u_rampa = fmaxf(0.0f, u_rampa - du);
  amp = A * (0.5f - 0.5f * cosf(PI * u_rampa));   // rampa de coseno

  if (amp > 0.0f) {
    fase += sentido * 2.0f * PI * dt / T;
    if (fase > 2.0f * PI) fase -= 2.0f * PI;
    if (fase < 0.0f) fase += 2.0f * PI;
    moverPlato(0, amp * cosf(fase));
    moverPlato(1, amp * sinf(fase));
  } else {
    fase = 0.0f;
    moverPlato(0, 0.0f);
    moverPlato(1, 0.0f);
  }

  if (ahora - t_info > 1000) {
    t_info = ahora;
    if (amp > 0.0f) Serial.printf("amplitud %.2f / %.1f deg, fase %.0f deg\n", amp, A, fase * 180.0f / PI);
  }
}
