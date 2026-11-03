import unittest

from src.processing.kalman import BallKalmanFilter


class TestBallKalmanFilter(unittest.TestCase):
    def setUp(self):
        self.dt = 1.0 / 30.0
        self.kf = BallKalmanFilter(dt=self.dt, meas_noise_std=1.0,
                                   accel_std=1500.0)

    def test_sigue_velocidad_constante(self):
        paso = 2.0                       # mm por frame
        v_real = paso / self.dt          # ~60 mm/s
        for i in range(40):
            self.kf.predict(self.dt)
            x, y, vx, vy = self.kf.update(i * paso, 0.0)

        self.assertAlmostEqual(x, 39 * paso, delta=1.0)
        self.assertAlmostEqual(y, 0.0, delta=1.0)
        self.assertAlmostEqual(vx, v_real, delta=0.2 * v_real)
        self.assertAlmostEqual(vy, 0.0, delta=5.0)

    def test_predice_sin_medida(self):
        """Sin bola hay que poder seguir prediciendo, no congelarse."""
        for i in range(40):
            self.kf.predict(self.dt)
            self.kf.update(i * 2.0, 0.0)
        x0, _, vx0, _ = self.kf.state
        x1, _, _, _ = self.kf.predict(self.dt)
        self.assertGreater(x1, x0)
        self.assertAlmostEqual(x1 - x0, vx0 * self.dt, delta=0.5)

    def test_dt_variable_cambia_la_transicion(self):
        self.kf.predict(0.05)
        self.assertAlmostEqual(float(self.kf.kf.transitionMatrix[0][2]), 0.05,
                               places=5)
        self.kf.predict(0.02)
        self.assertAlmostEqual(float(self.kf.kf.transitionMatrix[0][2]), 0.02,
                               places=5)

    def test_R_corresponde_al_ruido_declarado(self):
        kf = BallKalmanFilter(meas_noise_std=2.0)
        self.assertAlmostEqual(float(kf.kf.measurementNoiseCov[0][0]), 4.0,
                               places=4)

    def test_filtra_ruido(self):
        """Con la bola quieta y ruido, la salida debe ser mas suave."""
        import random
        random.seed(7)
        kf = BallKalmanFilter(dt=self.dt, meas_noise_std=1.0, accel_std=200.0)
        medidas, salidas = [], []
        for _ in range(200):
            z = random.gauss(0.0, 1.0)
            kf.predict(self.dt)
            x, _, _, _ = kf.update(z, 0.0)
            medidas.append(z); salidas.append(x)
        import statistics
        self.assertLess(statistics.pstdev(salidas[50:]),
                        statistics.pstdev(medidas[50:]))

    def test_reset(self):
        self.kf.predict(self.dt); self.kf.update(50.0, 50.0)
        self.kf.reset()
        self.assertEqual(self.kf.state, (0.0, 0.0, 0.0, 0.0))


if __name__ == '__main__':
    unittest.main()
