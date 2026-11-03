"""Deteccion de la bola por color, con validacion y paso a milimetros."""

import json
import os

import cv2
import numpy as np

from src import config


class BallDetector:
    """Encuentra la bola y devuelve su posicion en mm respecto al centro.

    detect() devuelve (x_mm, y_mm) o None. Devuelve None, y no (0, 0), para
    que una deteccion fallida no pueda confundirse con "la bola esta justo en
    el centro".
    """

    def __init__(self, calibrator=None, hsv_config_path: str = None,
                 homography_matrix=None):
        self.cal = calibrator
        # Compatibilidad: permitir pasar solo la matriz, sin ROI ni escala.
        self.matrix = None
        self.roi = None
        self.px_per_mm = None
        self.plate_size_mm = config.PLATE_SIZE_MM
        if calibrator is not None:
            self.matrix = calibrator.matrix
            self.roi = calibrator.roi
            self.px_per_mm = calibrator.px_per_mm
            self.plate_size_mm = calibrator.plate_size_mm
        elif homography_matrix is not None:
            self.matrix = homography_matrix

        self.scale = config.parallax_scale()
        self._cargar_hsv(hsv_config_path or config.HSV_FILE)

        # Area esperada de la bola en pixeles, si conocemos la escala.
        if self.px_per_mm:
            r_px = (config.BALL_DIAMETER_MM / 2.0) * self.px_per_mm
            area = np.pi * r_px ** 2
            self.area_min = config.BALL_AREA_MIN_FRAC * area
            self.area_max = config.BALL_AREA_MAX_FRAC * area
        else:
            self.area_min, self.area_max = 50.0, 1e9

        self.kernel = np.ones((config.MORPH_KERNEL, config.MORPH_KERNEL), np.uint8)

        # Diagnostico del ultimo frame, util para depurar y para los logs.
        self.last_mask = None
        self.last_area = 0.0
        self.last_circularity = 0.0
        self.last_reject = None

    # --------------------------------------------------------------------- #
    def _cargar_hsv(self, path):
        if os.path.exists(path):
            with open(path, 'r') as f:
                data = json.load(f)
            self.hsv_lower = np.array(data["hsv_lower"])
            self.hsv_upper = np.array(data["hsv_upper"])
            exp = data.get("exposure_abs")
            if exp is not None and exp != config.EXPOSURE_ABS:
                print("\n" + "!" * 68)
                print(f"AVISO: {path} se calibro con exposicion {exp} y ahora")
                print(f"config.EXPOSURE_ABS = {config.EXPOSURE_ABS}.")
                print("El umbral HSV solo vale para la exposicion con que se hizo.")
                print("Vuelva a correr calibrate_color.py.")
                print("!" * 68 + "\n")
            print(f"Configuracion HSV cargada desde {path}")
        else:
            print(f"Advertencia: no se encontro {path}. Usando verde por defecto.")
            self.hsv_lower = np.array([35, 100, 100])
            self.hsv_upper = np.array([85, 255, 255])

    def _mascara(self, img_bgr):
        hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
        h_lo, h_hi = int(self.hsv_lower[0]), int(self.hsv_upper[0])
        if h_lo <= h_hi:
            mask = cv2.inRange(hsv, self.hsv_lower, self.hsv_upper)
        else:
            # El tono da la vuelta por el rojo (0/179): dos rangos.
            a = cv2.inRange(hsv, np.array([h_lo, self.hsv_lower[1], self.hsv_lower[2]]),
                            np.array([179, self.hsv_upper[1], self.hsv_upper[2]]))
            b = cv2.inRange(hsv, np.array([0, self.hsv_lower[1], self.hsv_lower[2]]),
                            np.array([h_hi, self.hsv_upper[1], self.hsv_upper[2]]))
            mask = cv2.bitwise_or(a, b)
        # Apertura quita puntos sueltos; cierre rellena huecos dentro de la bola.
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, self.kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, self.kernel)
        return mask

    # --------------------------------------------------------------------- #
    def detect(self, frame: np.ndarray):
        """Devuelve (x_mm, y_mm) respecto al centro del plato, o None."""
        self.last_reject = None

        # 1. Recorte al area del plato: menos computo y menos distractores.
        ox = oy = 0
        img = frame
        if self.roi is not None:
            x, y, w, h = self.roi
            x2 = min(x + w, frame.shape[1])
            y2 = min(y + h, frame.shape[0])
            if x2 > x and y2 > y:
                img = frame[y:y2, x:x2]
                ox, oy = x, y

        mask = self._mascara(img)
        self.last_mask = mask

        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL,
                                       cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            self.last_reject = "sin contornos"
            return None

        # 2. Probar los candidatos de mayor a menor area y quedarse con el
        #    primero que parezca realmente una bola.
        for c in sorted(contours, key=cv2.contourArea, reverse=True)[:5]:
            area = cv2.contourArea(c)
            if not (self.area_min <= area <= self.area_max):
                self.last_reject = f"area {area:.0f} fuera de [{self.area_min:.0f}, {self.area_max:.0f}]"
                continue
            per = cv2.arcLength(c, True)
            if per <= 0:
                continue
            circ = 4.0 * np.pi * area / (per * per)
            if circ < config.CIRCULARITY_MIN:
                self.last_reject = f"circularidad {circ:.2f} < {config.CIRCULARITY_MIN}"
                continue
            M = cv2.moments(c)
            if M["m00"] <= 0:
                continue

            self.last_area, self.last_circularity = area, circ
            cx = M["m10"] / M["m00"] + ox
            cy = M["m01"] / M["m00"] + oy
            return self._a_milimetros(cx, cy)

        return None

    # --------------------------------------------------------------------- #
    def _a_milimetros(self, cx_px: float, cy_px: float):
        if self.matrix is None:
            # Sin calibracion devolvemos pixeles crudos, solo para depurar.
            return float(cx_px), float(cy_px)

        pt = np.array([[[cx_px, cy_px]]], dtype=np.float32)
        mm = cv2.perspectiveTransform(pt, self.matrix)
        x_mm, y_mm = float(mm[0][0][0]), float(mm[0][0][1])

        # Origen al centro del plato. Se usa el tamano real de la calibracion,
        # no un 150 quemado en el codigo.
        half = self.plate_size_mm / 2.0
        x = x_mm - half
        y = y_mm - half

        # Correccion de paralaje: el centro de la bola no esta en el plano
        # que calibra la homografia, sino 20 mm por encima.
        x *= self.scale
        y *= self.scale

        if config.INVERT_Y:
            y = -y

        # Una deteccion claramente fuera del plato no es la bola.
        lim = config.MAX_RADIUS_MM + config.OUT_OF_PLATE_MARGIN_MM
        if abs(x) > lim or abs(y) > lim:
            self.last_reject = f"fuera del plato ({x:.0f}, {y:.0f}) mm"
            return None

        return x, y
