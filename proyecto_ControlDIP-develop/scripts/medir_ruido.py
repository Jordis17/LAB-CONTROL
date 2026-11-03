"""Mide el ruido del centroide con la bola QUIETA.

De aqui sale el valor de config.MEAS_NOISE_STD_MM, que es la raiz de R en el
filtro de Kalman. Sin medirlo, R es un numero inventado y el filtro queda mal
sintonizado por ordenes de magnitud.

    python scripts/medir_ruido.py -n 500
"""

import argparse
import os
import statistics
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src import config
from src.camera.capture import abrir_camara
from src.processing.calibrator import PlateCalibrator
from src.processing.detector import BallDetector


def main():
    p = argparse.ArgumentParser()
    p.add_argument("-n", type=int, default=500)
    a = p.parse_args()

    cal = PlateCalibrator.load()
    if cal is None:
        print(f"Falta {config.CALIBRATION_FILE}. Corra calibrate_camera.py.")
        return 1

    det = BallDetector(calibrator=cal)
    cap = abrir_camara()
    if cap is None:
        return 1

    print(f"\nDeje la bola QUIETA en el centro del plato. "
          f"Tomando {a.n} muestras...\n")
    xs, ys, fallos = [], [], 0
    try:
        while len(xs) < a.n:
            ok, frame = cap.read()
            if not ok:
                continue
            m = det.detect(frame)
            if m is None:
                fallos += 1
                continue
            xs.append(m[0]); ys.append(m[1])
            if len(xs) % 100 == 0:
                print(f"  {len(xs)}/{a.n}")
    finally:
        cap.release()

    if len(xs) < 20:
        print("Muy pocas detecciones. Revise la calibracion de color.")
        return 1

    sx, sy = statistics.pstdev(xs), statistics.pstdev(ys)
    s = max(sx, sy)
    print("\n--- Ruido de posicion con la bola quieta ---")
    print(f"  muestras validas {len(xs)}, fallos {fallos}")
    print(f"  media       X {statistics.mean(xs):8.2f}  Y {statistics.mean(ys):8.2f} mm")
    print(f"  desv. est.  X {sx:8.3f}  Y {sy:8.3f} mm")
    print(f"  pico a pico X {max(xs) - min(xs):8.2f}  Y {max(ys) - min(ys):8.2f} mm")
    print(f"\n  Criterio del plan: desviacion < 1 mm.",
          "CUMPLE" if s < 1.0 else "NO CUMPLE")
    print(f"\n  Ponga en src/config.py:   MEAS_NOISE_STD_MM = {s:.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
