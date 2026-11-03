import unittest

import cv2
import numpy as np

from src import config
from src.processing.calibrator import PlateCalibrator


class TestPlateCalibrator(unittest.TestCase):
    def setUp(self):
        self.src = [(120, 40), (440, 40), (440, 360), (120, 360)]

    def test_matriz_y_esquinas(self):
        cal = PlateCalibrator(plate_size_mm=290.0)
        m = cal.calculate_homography(self.src, frame_shape=(480, 640, 3))
        self.assertEqual(m.shape, (3, 3))

        pt = np.array([[[120, 40]]], dtype=np.float32)
        mm = cv2.perspectiveTransform(pt, m)
        self.assertAlmostEqual(float(mm[0][0][0]), 0.0, places=3)
        self.assertAlmostEqual(float(mm[0][0][1]), 0.0, places=3)

        pt = np.array([[[440, 360]]], dtype=np.float32)
        mm = cv2.perspectiveTransform(pt, m)
        self.assertAlmostEqual(float(mm[0][0][0]), 290.0, places=2)
        self.assertAlmostEqual(float(mm[0][0][1]), 290.0, places=2)

    def test_escala_y_roi(self):
        cal = PlateCalibrator(plate_size_mm=290.0)
        cal.calculate_homography(self.src, frame_shape=(480, 640, 3))
        # 320 px para 290 mm
        self.assertAlmostEqual(cal.px_per_mm, 320.0 / 290.0, places=4)
        x, y, w, h = cal.roi
        self.assertLessEqual(x, 120)
        self.assertLessEqual(y, 40)
        self.assertGreaterEqual(x + w, 440)
        self.assertGreaterEqual(y + h, 360)
        self.assertLessEqual(x + w, 640)
        self.assertLessEqual(y + h, 480)

    def test_tamano_por_defecto_viene_de_config(self):
        self.assertEqual(PlateCalibrator().plate_size_mm, config.PLATE_SIZE_MM)
        self.assertEqual(config.PLATE_SIZE_MM, 290.0)

    def test_rechaza_numero_de_puntos_incorrecto(self):
        with self.assertRaises(ValueError):
            PlateCalibrator().calculate_homography([(0, 0), (1, 0), (1, 1)])


if __name__ == '__main__':
    unittest.main()
