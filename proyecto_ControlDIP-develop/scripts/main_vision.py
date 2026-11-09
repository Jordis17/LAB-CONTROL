"""Lazo de vision: camara -> deteccion -> filtro -> ESP32, con registro CSV.

Uso tipico (el visor cuesta varios ms por frame, apagarlo para medir):
    sudo chrt -r 50 ./venv/bin/python scripts/main_vision.py --no-display
"""

import argparse
import os
import sys
import time

import cv2

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src import config
from src.camera.capture import abrir_camara
from src.communication.transmitter import SerialTransmitter
from src.datalog import DataLogger
from src.processing.calibrator import PlateCalibrator
from src.processing.detector import BallDetector
from src.processing.kalman import BallKalmanFilter


def parse_args():
    p = argparse.ArgumentParser(description="Lazo de vision Ball on Plate")
    p.add_argument("--no-display", action="store_true",
                   help="sin ventana de video (quita varios ms por frame)")
    p.add_argument("--no-serial", action="store_true",
                   help="no abrir el puerto serial")
    p.add_argument("--require-serial", action="store_true",
                   help="abortar si no se puede abrir el puerto")
    p.add_argument("--no-log", action="store_true", help="no escribir CSV")
    return p.parse_args()


def main():
    args = parse_args()
    print("Iniciando sistema de vision y prediccion...")

    cal = PlateCalibrator.load()
    if cal is None:
        print(f"CRITICO: no se encontro {config.CALIBRATION_FILE}. "
              f"Ejecute scripts/calibrate_camera.py primero.")
        return 1
    print(f"Calibracion: plato {cal.plate_size_mm:g} mm, "
          f"{cal.px_per_mm:.3f} px/mm, ROI {cal.roi}")
    print(f"Correccion de paralaje: x{config.parallax_scale():.4f}  "
          f"(camara a {config.CAMERA_HEIGHT_MM:g} mm)")

    detector = BallDetector(calibrator=cal)
    kf = BallKalmanFilter()

    cap = abrir_camara()
    if cap is None:
        return 1

    tx = None if args.no_serial else SerialTransmitter(
        obligatorio=args.require_serial)
    log = None if args.no_log else DataLogger()

    print("\nLazo activo. Ctrl-C para salir"
          + ("" if args.no_display else " (o 'q' en la ventana)") + ".\n")

    t_prev = time.perf_counter()
    perdidos = 0
    n = 0

    try:
        while True:
            # grab() vuelve apenas llega el frame; el timestamp se toma ahi
            # para que dt corresponda a la captura y no al procesamiento.
            if not cap.grab():
                print("Perdida de fotograma.")
                continue
            t = time.perf_counter()
            ok, frame = cap.retrieve()
            if not ok:
                continue

            dt = t - t_prev
            t_prev = t
            if dt <= 0:
                continue
            fps = 1.0 / dt

            # 1. Predecir SIEMPRE, con el dt real de este ciclo.
            #    Antes solo se predecia cuando habia bola, asi que al perderla
            #    el filtro quedaba congelado y al reaparecer generaba una
            #    velocidad enorme que el controlador obedecia.
            kf.predict(dt)

            medida = detector.detect(frame)

            if medida is not None:
                x, y, vx, vy = kf.update(medida[0], medida[1])
                perdidos = 0
                estado = 1
            else:
                perdidos += 1
                x, y, vx, vy = kf.state
                if perdidos > config.MAX_COAST_FRAMES:
                    estado = 0
                    x = y = vx = vy = 0.0
                    kf.reset()
                else:
                    # Coasting corto: la prediccion sigue siendo util.
                    estado = 1

            tel = tx.leer_telemetria() if tx else None
            enviado = tx.send(estado, x, y, vx, vy) if tx else False

            if log is not None:
                log.escribir(
                    t=f"{t:.6f}", dt=f"{dt:.6f}", fps=f"{fps:.2f}",
                    detectada=int(medida is not None),
                    x_raw=f"{medida[0]:.2f}" if medida else "",
                    y_raw=f"{medida[1]:.2f}" if medida else "",
                    x=f"{x:.2f}", y=f"{y:.2f}",
                    vx=f"{vx:.1f}", vy=f"{vy:.1f}",
                    area=f"{detector.last_area:.0f}",
                    circularidad=f"{detector.last_circularity:.3f}",
                    enviado=int(enviado),
                    **({} if tel is None else {
                        "tel_modo": tel["modo"], "tel_banderas": tel["banderas"],
                        "tel_n": tel["n"], "tel_t_ms": tel["t_ms"],
                        "tel_thx": f"{tel['thx']:.4f}", "tel_thy": f"{tel['thy']:.4f}",
                        "tel_leyx": f"{tel['leyx']:.4f}", "tel_leyy": f"{tel['leyy']:.4f}",
                        "tel_Ix": f"{tel['Ix']:.5f}", "tel_Iy": f"{tel['Iy']:.5f}",
                        "tel_rx": f"{tel['rx']:.2f}", "tel_ry": f"{tel['ry']:.2f}",
                        "tel_x_rx": f"{tel['x_rx']:.2f}",
                        "tel_descartadas": tel.get("descartadas", ""),
                        "tel_malas": tel.get("malas", ""),
                        "tel_loop_us": tel.get("loop_us", "")}))

            n += 1
            if n % 30 == 0:
                marca = "OK " if medida is not None else "---"
                print(f"{marca} X:{x:7.1f} Y:{y:7.1f} "
                      f"Vx:{vx:7.1f} Vy:{vy:7.1f} mm/s | "
                      f"{fps:5.1f} fps | serial:{'si' if enviado else 'NO'}"
                      + ("" if medida is not None
                         else f" | {detector.last_reject or ''}"))

            if not args.no_display:
                if medida is not None:
                    cv2.putText(frame, f"X:{x:.1f} Y:{y:.1f} mm", (10, 30),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                    cv2.putText(frame, f"Vx:{vx:.0f} Vy:{vy:.0f} mm/s", (10, 58),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)
                else:
                    cv2.putText(frame, f"SIN BOLA: {detector.last_reject or ''}",
                                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6,
                                (0, 0, 255), 2)
                cv2.putText(frame, f"{fps:.1f} fps", (10, 86),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 2)
                if cal.roi:
                    rx, ry, rw, rh = cal.roi
                    cv2.rectangle(frame, (rx, ry), (rx + rw, ry + rh),
                                  (120, 120, 120), 1)
                cv2.imshow("Main Control Vision", frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

    except KeyboardInterrupt:
        print("\nInterrumpido por el usuario.")
    finally:
        # Salida segura: la ESP32 debe recibir estado 0 y llevar el plato a
        # cero. Si el programa muere sin esto, los servos quedan forzados en
        # la ultima posicion y se calientan.
        if tx is not None:
            tx.close()
        if log is not None:
            log.close()
        cap.release()
        cv2.destroyAllWindows()
        print("Salida limpia.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
