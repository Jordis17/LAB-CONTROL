"""Registro CSV de cada sesion, para las graficas del informe."""

import csv
import os
import time

from src import config


class DataLogger:
    """Una fila por ciclo del lazo. Sin esto no hay graficas que mostrar."""

    # Las columnas tel_* son la telemetria de la ESP32 (firmware
    # bop_prueba_circulo_lazo). Cada fila guarda la ULTIMA trama recibida antes
    # de enviar la de esa fila, o sea la respuesta a la trama de la fila
    # ANTERIOR; tel_x_rx (eco de la x recibida) permite comprobar el corrimiento.
    # Vacias si el firmware no manda telemetria.
    CAMPOS = ["t", "dt", "fps", "detectada", "x_raw", "y_raw",
              "x", "y", "vx", "vy", "area", "circularidad", "enviado",
              "tel_modo", "tel_banderas", "tel_n", "tel_t_ms", "tel_thx", "tel_thy",
              "tel_leyx", "tel_leyy", "tel_Ix", "tel_Iy", "tel_rx", "tel_ry", "tel_x_rx",
              "tel_descartadas", "tel_malas", "tel_loop_us"]

    def __init__(self, carpeta: str = None, nombre: str = None):
        carpeta = carpeta or config.LOG_DIR
        os.makedirs(carpeta, exist_ok=True)
        if nombre is None:
            nombre = time.strftime("sesion_%Y%m%d_%H%M%S.csv")
        self.path = os.path.join(carpeta, nombre)
        self._f = open(self.path, "w", newline="")
        self._w = csv.writer(self._f)
        self._w.writerow(self.CAMPOS)
        self.filas = 0
        print(f"Registrando en {self.path}")

    def escribir(self, **kw):
        self._w.writerow([kw.get(c, "") for c in self.CAMPOS])
        self.filas += 1
        if self.filas % 120 == 0:
            self._f.flush()

    def close(self):
        try:
            self._f.flush()
            self._f.close()
        except Exception:
            pass
        print(f"Log cerrado: {self.path} ({self.filas} filas)")

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()
        return False
