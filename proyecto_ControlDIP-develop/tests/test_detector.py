import unittest

import cv2
import numpy as np

from src import config
from src.processing.calibrator import PlateCalibrator
from src.processing.detector import BallDetector

VERDE = (0, 255, 0)


def calibracion():
    cal = PlateCalibrator(plate_size_mm=290.0)
    cal.calculate_homography([(120, 40), (440, 40), (440, 360), (120, 360)],
                             frame_shape=(480, 640, 3))
    return cal


def frame_con_bola(cx, cy, r=None):
    cal = calibracion()
    if r is None:
        r = int(round((config.BALL_DIAMETER_MM / 2.0) * cal.px_per_mm))
    f = np.zeros((480, 640, 3), np.uint8)
    f[:] = (40, 20, 60)                       # fondo oscuro tipo vino
    cv2.circle(f, (cx, cy), r, VERDE, -1)
    return f


class TestBallDetector(unittest.TestCase):
    def setUp(self):
        self.cal = calibracion()
        self.det = BallDetector(calibrator=self.cal,
                                hsv_config_path="__no_existe__.json")

    def test_centro_del_plato(self):
        f = frame_con_bola(280, 200)          # centro del cuadrado calibrado
        m = self.det.detect(f)
        self.assertIsNotNone(m)
        self.assertAlmostEqual(m[0], 0.0, delta=2.0)
        self.assertAlmostEqual(m[1], 0.0, delta=2.0)

    def test_posicion_desplazada_con_paralaje(self):
        f = frame_con_bola(360, 200)          # +80 px respecto al centro
        m = self.det.detect(f)
        self.assertIsNotNone(m)
        esperado = (80.0 / self.cal.px_per_mm) * config.parallax_scale()
        self.assertAlmostEqual(m[0], esperado, delta=2.0)
        self.assertAlmostEqual(m[1], 0.0, delta=2.0)

    def test_sin_bola_devuelve_none(self):
        f = np.zeros((480, 640, 3), np.uint8)
        f[:] = (40, 20, 60)
        self.assertIsNone(self.det.detect(f))

    def test_mancha_muy_pequena_se_rechaza(self):
        f = frame_con_bola(280, 200, r=4)
        self.assertIsNone(self.det.detect(f))

    def test_forma_no_circular_se_rechaza(self):
        f = np.zeros((480, 640, 3), np.uint8)
        f[:] = (40, 20, 60)
        cv2.rectangle(f, (240, 193), (330, 207), VERDE, -1)
        self.assertIsNone(self.det.detect(f))
        self.assertIn("circularidad", (self.det.last_reject or ""))

    def test_ignora_lo_que_esta_fuera_del_roi(self):
        """Una bola verde en la mesa, fuera del plato, no cuenta."""
        f = np.zeros((480, 640, 3), np.uint8)
        f[:] = (40, 20, 60)
        cv2.circle(f, (30, 440), 22, VERDE, -1)
        self.assertIsNone(self.det.detect(f))

    def test_invert_y(self):
        f = frame_con_bola(280, 280)          # +80 px hacia abajo
        m1 = self.det.detect(f)
        config.INVERT_Y = True
        try:
            det2 = BallDetector(calibrator=self.cal,
                                hsv_config_path="__no_existe__.json")
            m2 = det2.detect(f)
        finally:
            config.INVERT_Y = False
        self.assertAlmostEqual(m1[1], -m2[1], delta=0.01)


if __name__ == '__main__':
    unittest.main()
