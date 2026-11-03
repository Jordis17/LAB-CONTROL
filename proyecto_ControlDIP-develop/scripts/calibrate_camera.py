"""Calibracion de perspectiva: pixeles -> milimetros.

CLIQUEN LA ESQUINA EXTERIOR DE CADA MARCA GRABADA, NO SU CENTRO.

Las cuatro esquinas exteriores estan a 5 mm de cada borde del plato de
300 mm, asi que forman un cuadrado perfecto de 290 mm. Los centros no
sirven: el patron de alineacion mide 20 mm y los otros tres 28 mm, de modo
que sus centros no forman un cuadrado y la homografia sale torcida y con la
escala equivocada (el error seria del orden del 14 %).
"""

import os
import sys

import cv2
import numpy as np

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src import config
from src.camera.capture import abrir_camara
from src.processing.calibrator import PlateCalibrator

puntos = []


def mouse_callback(event, x, y, flags, param):
    if event == cv2.EVENT_LBUTTONDOWN and len(puntos) < 4:
        puntos.append((x, y))
        print(f"Punto {len(puntos)}: ({x}, {y})")


def main():
    print(__doc__)
    cap = abrir_camara()
    if cap is None:
        return 1

    print("--- FASE 1: PREVISUALIZACION ---")
    print("Acomode la planta y la camara. 's' para capturar, 'q' para salir.")
    frame_cal = None
    while True:
        ok, frame = cap.read()
        if not ok:
            print("Error leyendo la camara.")
            break
        cv2.putText(frame, "'s' = capturar   'q' = salir", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.imshow("Video en vivo", frame)
        k = cv2.waitKey(1) & 0xFF
        if k == ord('s'):
            frame_cal = frame.copy()
            break
        if k == ord('q'):
            cap.release(); cv2.destroyAllWindows(); return 0
    cap.release()
    cv2.destroyWindow("Video en vivo")
    if frame_cal is None:
        return 1

    print("\n--- FASE 2: SELECCION DE PUNTOS ---")
    print("Clique la ESQUINA EXTERIOR de cada marca, en sentido horario,")
    print("empezando por la marca que quede arriba a la izquierda en la imagen.")
    print("La marca pequena (patron de alineacion) va entre el servo X (+X) y -Y.")
    print("'r' reinicia, 'c' confirma, 'q' sale.")

    clone = frame_cal.copy()
    cv2.namedWindow("Calibracion de puntos")
    cv2.setMouseCallback("Calibracion de puntos", mouse_callback)

    while True:
        img = clone.copy()
        for i, pt in enumerate(puntos):
            cv2.circle(img, pt, 5, (0, 255, 0), -1)
            cv2.putText(img, str(i + 1), (pt[0] + 10, pt[1] - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
            if i > 0:
                cv2.line(img, puntos[i - 1], puntos[i], (255, 0, 0), 2)
        if len(puntos) == 4:
            cv2.line(img, puntos[3], puntos[0], (255, 0, 0), 2)
        cv2.putText(img, "ESQUINA EXTERIOR de cada marca, horario",
                    (10, 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
        cv2.imshow("Calibracion de puntos", img)

        k = cv2.waitKey(1) & 0xFF
        if k == ord('r'):
            puntos.clear(); print("Puntos reiniciados.")
        elif k == ord('c') and len(puntos) == 4:
            break
        elif k == ord('q'):
            cv2.destroyAllWindows(); return 0
    cv2.destroyAllWindows()

    cal = PlateCalibrator(plate_size_mm=config.PLATE_SIZE_MM)
    cal.calculate_homography(puntos, frame_shape=frame_cal.shape)

    # Comprobacion: los 4 lados del cuadrilatero deberian parecerse entre si.
    pts = np.array(puntos, dtype=np.float32)
    lados = [float(np.linalg.norm(pts[i] - pts[(i + 1) % 4])) for i in range(4)]
    desvio = (max(lados) - min(lados)) / (sum(lados) / 4.0) * 100.0
    print(f"\nLados en pixeles: " + ", ".join(f"{l:.0f}" for l in lados))
    print(f"Diferencia entre el lado mayor y el menor: {desvio:.1f} %")
    if desvio > 25.0:
        print("AVISO: el cuadrilatero esta muy deformado. O la camara esta muy")
        print("inclinada, o se clico el punto equivocado en alguna marca.")

    print(f"Escala: {cal.px_per_mm:.3f} px/mm  ->  "
          f"la bola de {config.BALL_DIAMETER_MM:g} mm mide "
          f"{config.BALL_DIAMETER_MM * cal.px_per_mm:.0f} px de diametro")
    if cal.px_per_mm * config.BALL_DIAMETER_MM < 20:
        print("AVISO: la bola se ve muy pequena. Baje la camara o suba la")
        print("resolucion, o el centroide va a ser impreciso.")

    cal.save()
    print("\nRecuerde verificar el signo de Y: empuje la bola a mano hacia el")
    print("servo Y con main_vision.py corriendo. Si la lectura baja en vez de")
    print("subir, ponga INVERT_Y = True en src/config.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
