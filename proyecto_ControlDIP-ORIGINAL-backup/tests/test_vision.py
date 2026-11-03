import unittest
import numpy as np
import cv2
from src.processing.calibrator import PlateCalibrator

class TestPlateCalibrator(unittest.TestCase):
    def setUp(self):
        # Plato de 300x300 mm
        self.calibrator = PlateCalibrator(plate_size_mm=300.0)

    def test_homography_matrix_generation(self):
        # Simulamos 4 puntos clickeados en una imagen de 640x480
        # (Supongamos que el plato ocupa un cuadrado perfecto en el centro)
        src_points = [(100, 100), (500, 100), (500, 500), (100, 500)]
        
        # Generar matriz
        matrix = self.calibrator.calculate_homography(src_points)
        
        # La matriz debe ser de 3x3
        self.assertEqual(matrix.shape, (3, 3))
        
        # Probar la transformación: el punto (100,100) en píxeles debe ser (0,0) en mm
        pt_px = np.array([[[100, 100]]], dtype=np.float32)
        pt_mm = cv2.perspectiveTransform(pt_px, matrix)
        
        # Verificamos que el resultado sea cercano a (0,0) milímetros
        self.assertAlmostEqual(pt_mm[0][0][0], 0.0, places=3)
        self.assertAlmostEqual(pt_mm[0][0][1], 0.0, places=3)

if __name__ == '__main__':
    unittest.main()