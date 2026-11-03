import unittest
import numpy as np
from src.processing.kalman import BallKalmanFilter

class TestBallKalmanFilter(unittest.TestCase):
    def setUp(self):
        # Inicializamos asumiendo 30 FPS
        self.kf = BallKalmanFilter(dt=0.033)

    def test_kalman_prediction_and_update(self):
        # La bola arranca en el centro
        self.kf.predict()
        self.kf.update(0.0, 0.0)
        
        # Simulamos convergencia a velocidad constante durante 30 frames (1 segundo)
        # Un estado oculto requiere iteraciones para alcanzar el estado estacionario.
        for i in range(1, 31):
            self.kf.predict()
            self.kf.update(i * 2.0, 0.0)
        
        # Frame 31
        self.kf.predict()
        updated_state = self.kf.update(62.0, 0.0)
        
        x, y, vx, vy = updated_state
        
        # Verificamos que X sigue fielmente la medida real (62.0)
        self.assertAlmostEqual(x, 62.0, delta=0.5)
        self.assertAlmostEqual(y, 0.0, delta=0.5)
        
        # Verificamos que detectó velocidad positiva en X
        # Se mueve 2 mm cada 0.033s = ~60 mm/s
        self.assertTrue(vx > 40.0)
        self.assertAlmostEqual(vy, 0.0, delta=5.0)

if __name__ == '__main__':
    unittest.main()