"""Medicion de la camara: periodo entre frames y latencia de extremo a extremo.

    python scripts/run_benchmark.py --period
    python scripts/run_benchmark.py --latency

Por que dos modos: el benchmark anterior media cuanto tardaba cap.read() en
volver, que NO es la latencia. Una camara puede devolver en 2 ms un frame que
tiene 100 ms de antiguedad. Lo que decide si el lazo es viable es la latencia
de extremo a extremo, y se mide con un evento visual de tiempo conocido.
"""

import argparse
import os
import statistics
import sys
import time

import cv2
import numpy as np

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src import config
from src.camera.capture import abrir_camara


def medir_periodo(cap, n=300):
    print(f"\nMidiendo el periodo entre frames ({n} muestras)...")
    periodos = []
    t_prev = None
    while len(periodos) < n:
        if not cap.grab():
            continue
        t = time.perf_counter()
        cap.retrieve()
        if t_prev is not None:
            periodos.append((t - t_prev) * 1000.0)
        t_prev = t
        if len(periodos) % 50 == 0 and periodos:
            print(f"  {len(periodos)}/{n}")

    periodos.sort()
    med = statistics.mean(periodos)
    print("\n--- Periodo entre frames (ms) ---")
    print(f"  media     {med:7.2f}   ->  {1000.0 / med:5.1f} fps")
    print(f"  mediana   {statistics.median(periodos):7.2f}")
    print(f"  desv.est. {statistics.pstdev(periodos):7.2f}")
    print(f"  minimo    {periodos[0]:7.2f}")
    print(f"  p95       {periodos[int(0.95 * len(periodos))]:7.2f}")
    print(f"  maximo    {periodos[-1]:7.2f}")

    dentro = sum(1 for p in periodos if abs(p - med) <= 5.0) / len(periodos)
    print(f"\n  {dentro * 100:.1f} % de los periodos dentro de +-5 ms de la media")
    print("  Criterio del plan: 95 % dentro de +-5 ms.",
          "CUMPLE" if dentro >= 0.95 else "NO CUMPLE")

    print("\n  Histograma:")
    lo, hi = periodos[0], periodos[-1]
    nb = 20
    ancho = max((hi - lo) / nb, 1e-6)
    for i in range(nb):
        a, b = lo + i * ancho, lo + (i + 1) * ancho
        c = sum(1 for p in periodos if a <= p < b or (i == nb - 1 and p == hi))
        if c:
            print(f"   {a:6.1f}-{b:6.1f} ms | {'#' * min(c, 60)} {c}")


def medir_latencia(cap, n=15):
    """Metodo del destello: se conmuta la pantalla y se cronometra cuanto
    tarda ese cambio en aparecer en un frame de la camara.

    Incluye la latencia del monitor, asi que el numero es una COTA SUPERIOR
    de la latencia de la camara. Para este proyecto eso sirve: si la cota ya
    es buena, la camara es mejor todavia.
    """
    print("\n--- Latencia de extremo a extremo ---")
    print("Apunte la camara a esta ventana, a pantalla completa si puede,")
    print("y no la mueva. Se haran", n, "destellos.\n")

    win = "DESTELLO - apunte la camara aqui"
    cv2.namedWindow(win, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(win, 900, 700)
    negro = np.zeros((700, 900, 3), np.uint8)
    blanco = np.full((700, 900, 3), 255, np.uint8)

    def brillo():
        cap.grab()
        ok, f = cap.retrieve()
        return float(np.mean(f)) if ok else None

    latencias = []
    for k in range(n):
        cv2.imshow(win, negro)
        cv2.waitKey(1)
        time.sleep(0.5)
        for _ in range(5):
            cap.grab(); cap.retrieve()
        b0 = brillo()
        if b0 is None:
            continue

        cv2.imshow(win, blanco)
        cv2.waitKey(1)
        t0 = time.perf_counter()

        t_detect = None
        while time.perf_counter() - t0 < 1.0:
            b = brillo()
            if b is not None and b > b0 + 12.0:
                t_detect = time.perf_counter()
                break
        if t_detect is None:
            print(f"  destello {k + 1}: no se detecto el cambio "
                  f"(brillo base {b0:.0f}); acerque o enfoque la camara")
            continue
        ms = (t_detect - t0) * 1000.0
        latencias.append(ms)
        print(f"  destello {k + 1:2d}: {ms:6.1f} ms")

    cv2.destroyWindow(win)
    if not latencias:
        print("\nNo se pudo medir. Revise que la camara vea la ventana.")
        return

    latencias.sort()
    print("\n  mediana  %6.1f ms" % statistics.median(latencias))
    print("  minimo   %6.1f ms" % latencias[0])
    print("  maximo   %6.1f ms" % latencias[-1])
    print("\n  Este valor incluye la latencia del monitor, asi que es una cota")
    print("  superior. Criterio del plan: media < 60 ms, desviacion < 10 ms.")
    print("  Si sale alto, pruebe: FOURCC YUYV en vez de MJPG, menor")
    print("  resolucion, exposicion mas corta con mas luz.")


def main():
    p = argparse.ArgumentParser(description="Benchmark de la camara")
    p.add_argument("--period", action="store_true", help="periodo entre frames")
    p.add_argument("--latency", action="store_true", help="latencia extremo a extremo")
    p.add_argument("-n", type=int, default=None)
    a = p.parse_args()
    if not a.period and not a.latency:
        a.period = a.latency = True

    cap = abrir_camara()
    if cap is None:
        return 1
    try:
        if a.period:
            medir_periodo(cap, a.n or 300)
        if a.latency:
            medir_latencia(cap, a.n or 15)
    finally:
        cap.release()
        cv2.destroyAllWindows()
    print(f"\nConfiguracion usada: {config.FRAME_WIDTH}x{config.FRAME_HEIGHT}, "
          f"{config.FOURCC}, exposicion {config.EXPOSURE_ABS} "
          f"(= {config.EXPOSURE_ABS / 10:.1f} ms)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
