"""Calibracion del umbral HSV de la bola.

El umbral solo vale para la exposicion y la iluminacion con que se calibro,
asi que aqui se guarda la exposicion junto con el umbral y el detector avisa
si despues no coincide.
"""

import json
import os
import sys
import time

import cv2
import numpy as np

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src import config
from src.camera.capture import abrir_camara
from src.processing.calibrator import PlateCalibrator


def nada(x):
    pass


def main():
    print("Calibrador de color HSV")
    cap = abrir_camara()
    if cap is None:
        return 1

    cal = PlateCalibrator.load()
    roi = cal.roi if cal else None
    if roi:
        print(f"Usando el ROI de la calibracion: {roi}")
    else:
        print("Sin calibracion previa: se trabaja sobre el frame completo.")

    cv2.namedWindow("Ajuste HSV")
    cv2.namedWindow("Mascara")
    for nombre, ini, mx in (("H_MIN", 35, 179), ("H_MAX", 85, 179),
                            ("S_MIN", 100, 255), ("S_MAX", 255, 255),
                            ("V_MIN", 100, 255), ("V_MAX", 255, 255)):
        cv2.createTrackbar(nombre, "Ajuste HSV", ini, mx, nada)

    kernel = np.ones((config.MORPH_KERNEL, config.MORPH_KERNEL), np.uint8)

    print("\n1. Ponga la bola sobre el plato con la iluminacion definitiva.")
    print("2. Ajuste hasta que en 'Mascara' la bola sea BLANCA y todo lo demas NEGRO.")
    print("3. Mueva la bola por todo el plato y confirme que sigue blanca en")
    print("   las esquinas, que es donde peor llega la luz.")
    print("4. 'g' guarda, 'q' sale sin guardar.\n")

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if roi:
            x, y, w, h = roi
            x2, y2 = min(x + w, frame.shape[1]), min(y + h, frame.shape[0])
            img = frame[y:y2, x:x2]
        else:
            img = frame

        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        g = lambda n: cv2.getTrackbarPos(n, "Ajuste HSV")
        lo = np.array([g("H_MIN"), g("S_MIN"), g("V_MIN")])
        hi = np.array([g("H_MAX"), g("S_MAX"), g("V_MAX")])

        mask = cv2.inRange(hsv, lo, hi)
        # Mismas operaciones que detector.py, si no el ajuste no representa
        # lo que vera el lazo real.
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

        cnts, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        vista = cv2.bitwise_and(img, img, mask=mask)
        if cnts:
            c = max(cnts, key=cv2.contourArea)
            area = cv2.contourArea(c)
            per = cv2.arcLength(c, True)
            circ = 4 * np.pi * area / (per * per) if per > 0 else 0.0
            cv2.putText(vista, f"manchas:{len(cnts)} area:{area:.0f} circ:{circ:.2f}",
                        (8, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)
            if len(cnts) > 1:
                cv2.putText(vista, "hay mas de una mancha: ajuste mas",
                            (8, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

        cv2.imshow("Ajuste HSV", vista)
        cv2.imshow("Mascara", mask)

        k = cv2.waitKey(1) & 0xFF
        if k == ord('q'):
            break
        if k == ord('g'):
            data = {
                "hsv_lower": [int(v) for v in lo],
                "hsv_upper": [int(v) for v in hi],
                "exposure_abs": config.EXPOSURE_ABS,
                "white_balance_k": config.WHITE_BALANCE_K,
                "fourcc": config.FOURCC,
                "fecha": time.strftime("%Y-%m-%d %H:%M:%S"),
            }
            with open(config.HSV_FILE, "w") as f:
                json.dump(data, f, indent=2)
            print(f"\nGuardado en {config.HSV_FILE}: {data}")
            break

    cap.release()
    cv2.destroyAllWindows()
    return 0


if __name__ == "__main__":
    sys.exit(main())
