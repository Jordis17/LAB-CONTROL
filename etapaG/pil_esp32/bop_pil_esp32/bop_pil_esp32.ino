// PIL de Controller_BoP en la ESP32 (Etapa G, Ball on Plate).
//
// Corre en la ESP32 el codigo C GENERADO por Embedded Coder a partir de
// Controller_BoP_ESP32.slx (copia de etapaE/Controller_BoP.slx con la placa
// ESP32). G3_preparar_PIL_ESP32_BoP.m copia ese codigo en esta carpeta.
// Este archivo NO contiene el algoritmo: solo recibe entradas por el puerto
// serie, llama Controller_BoP_ESP32_step y devuelve las salidas.
//
// Dos instancias (eje X = 0, eje Y = 1), cada una con su estado (Reusable function).
//
// Protocolo (115200 baud, little-endian, double IEEE de 8 bytes):
//   PC -> ESP32  'R' reinicio:  A5 'R' ck                         (ck = 'R')
//   ESP32 -> PC              :  5A 'R' 'B' 'o' 'P' '1' ck         (ck = xor de los 5 bytes desde 'R')
//   PC -> ESP32  'S' paso:      A5 'S' eje r x v hab ck           (26 bytes de datos; ck = xor de 'S' y los datos)
//   ESP32 -> PC              :  5A 'S' th I sat ciclos ck         (8+8+1+4 bytes; ck = xor desde 'S')
//   ESP32 -> PC  error       :  5A 'E' codigo ck
// ciclos: ciclos de CPU (240 MHz) que tardo la llamada a _step.

extern "C" {
#include "Controller_BoP_ESP32.h"
}
#include <string.h>

static RT_MODEL_Controller_BoP_ESP32_T M[2];
static DW_Controller_BoP_ESP32_T DW[2];
static real_T U_r[2], U_x[2], U_v[2], Y_th[2], Y_I[2];
static boolean_T U_h[2], Y_s[2];

static void reiniciar() {
  memset(M, 0, sizeof(M));
  for (int e = 0; e < 2; e++) {
    M[e].dwork = &DW[e];
    Controller_BoP_ESP32_initialize(&M[e], &U_r[e], &U_x[e], &U_v[e], &U_h[e],
                                    &Y_th[e], &Y_I[e], &Y_s[e]);
  }
}

static bool leer(uint8_t *b, size_t n) {
  return Serial.readBytes(b, n) == n;
}

static void enviar(uint8_t *b, size_t n) {   // b[0] = 0x5A; agrega el checksum
  uint8_t ck = 0;
  for (size_t i = 1; i < n; i++) ck ^= b[i];
  Serial.write(b, n);
  Serial.write(ck);
}

static void error_(uint8_t codigo) {
  uint8_t b[3] = {0x5A, 'E', codigo};
  enviar(b, 3);
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(1000);
  reiniciar();
}

void loop() {
  if (Serial.available() <= 0) return;
  if (Serial.read() != 0xA5) return;            // sincronizacion
  uint8_t cmd, ck;
  if (!leer(&cmd, 1)) return;
  if (cmd == 'R') {
    if (!leer(&ck, 1) || ck != 'R') { error_(1); return; }
    reiniciar();
    uint8_t b[6] = {0x5A, 'R', 'B', 'o', 'P', '1'};
    enviar(b, 6);
  } else if (cmd == 'S') {
    uint8_t p[26];
    if (!leer(p, 26) || !leer(&ck, 1)) { error_(2); return; }
    uint8_t c = 'S';
    for (int i = 0; i < 26; i++) c ^= p[i];
    if (c != ck) { error_(3); return; }
    uint8_t e = p[0];
    if (e > 1) { error_(4); return; }
    real_T r, x, v, th, I;
    boolean_T sat;
    memcpy(&r, p + 1, 8);
    memcpy(&x, p + 9, 8);
    memcpy(&v, p + 17, 8);
    boolean_T hab = (p[25] != 0);
    uint32_t c0 = ESP.getCycleCount();
    Controller_BoP_ESP32_step(&M[e], r, x, v, hab, &th, &I, &sat);
    uint32_t dc = ESP.getCycleCount() - c0;
    uint8_t b[23];
    b[0] = 0x5A; b[1] = 'S';
    memcpy(b + 2, &th, 8);
    memcpy(b + 10, &I, 8);
    b[18] = sat ? 1 : 0;
    memcpy(b + 19, &dc, 4);
    enviar(b, 23);
  } else {
    error_(5);
  }
}
