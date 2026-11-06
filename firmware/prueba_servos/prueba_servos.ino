// prueba_servos.ino — mover cada servo a un angulo fijo (solo para mediciones)
// Monitor Serie a 115200 baudios, "Ambos NL & CR". Comandos:
//   X 10    -> servo X a +10 grados respecto del neutro
//   Y -5    -> servo Y a -5 grados
//   C       -> ambos al neutro
#include <ESP32Servo.h>

const int PIN_X = 18;          // cambiar si se usa otro pin
const int PIN_Y = 19;
const int US_NEUTRO = 1500;    // pulso del neutro [us]
const float US_POR_GRADO = 1000.0 / 90.0;   // hoja de datos: 1 ms a 2 ms ~ 90 grados
const float LIM = 45.0;        // tope fisico del servo [grados]

Servo sx, sy;

void mover(Servo &s, float g, const char *nombre) {
  if (g > LIM) g = LIM;
  if (g < -LIM) g = -LIM;
  int us = US_NEUTRO + (int)(g * US_POR_GRADO);
  s.writeMicroseconds(us);
  Serial.printf("%s = %+.1f grados (%d us)\n", nombre, g, us);
}

void setup() {
  Serial.begin(115200);
  sx.setPeriodHertz(50);  sy.setPeriodHertz(50);
  sx.attach(PIN_X, 500, 2500);  sy.attach(PIN_Y, 500, 2500);
  mover(sx, 0, "X");  mover(sy, 0, "Y");
}

void loop() {
  if (!Serial.available()) return;
  String l = Serial.readStringUntil('\n');  l.trim();
  if (l.length() == 0) return;
  char eje = toupper(l.charAt(0));
  float g = l.substring(1).toFloat();
  if (eje == 'X') mover(sx, g, "X");
  else if (eje == 'Y') mover(sy, g, "Y");
  else if (eje == 'C') { mover(sx, 0, "X"); mover(sy, 0, "Y"); }
}
