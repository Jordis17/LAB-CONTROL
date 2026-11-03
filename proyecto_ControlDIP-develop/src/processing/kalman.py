"""Filtro de Kalman lineal 2D para posicion y velocidad de la bola."""

import cv2
import numpy as np

from src import config


class BallKalmanFilter:
    """Modelo de velocidad constante con aceleracion aleatoria.

    Estados: x, y, vx, vy (mm y mm/s). Medidas: x, y.

    Sobre la sintonizacion. R es la varianza del ruido de la camara y se MIDE:
    bola quieta, >=500 muestras, desviacion estandar en mm, al cuadrado. Q sale
    de cuanta aceleracion no modelada hay; como no modelamos la inclinacion del
    plato, toda la aceleracion de la bola es no modelada, y su limite fisico es
    (5/7)*g*sen(14 deg) = 1700 mm/s^2.

    La version anterior tenia R = 1e-3 y Q = 1e-2, o sea le creia diez veces mas
    a la camara que a la fisica, y afirmaba que el centroide tenia 0.03 mm de
    desviacion. Con eso el filtro no filtraba nada y la velocidad salia tan
    ruidosa como una resta de posiciones consecutivas.
    """

    def __init__(self, dt: float = None,
                 meas_noise_std: float = None,
                 accel_std: float = None):
        self.dt = float(dt) if dt else 1.0 / config.FRAME_FPS
        self.meas_noise_std = float(
            meas_noise_std if meas_noise_std is not None else config.MEAS_NOISE_STD_MM)
        self.accel_std = float(
            accel_std if accel_std is not None else config.PROCESS_ACCEL_STD)

        self.kf = cv2.KalmanFilter(4, 2)
        self.kf.measurementMatrix = np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
        ], np.float32)
        self.kf.measurementNoiseCov = (
            np.eye(2, dtype=np.float32) * np.float32(self.meas_noise_std ** 2))
        self._set_dt(self.dt)
        self.reset()

    # --------------------------------------------------------------------- #
    def _set_dt(self, dt: float):
        """Reconstruye F y Q para el dt REAL de este ciclo.

        Dejar dt fijo en 0.033 cuando la camara entrega otra cosa escala mal
        todas las velocidades.
        """
        dt = float(max(dt, 1e-4))
        self.dt = dt
        self.kf.transitionMatrix = np.array([
            [1, 0, dt, 0],
            [0, 1, 0, dt],
            [0, 0, 1, 0],
            [0, 0, 0, 1],
        ], np.float32)

        s2 = self.accel_std ** 2
        d4, d3, d2 = dt ** 4 / 4.0, dt ** 3 / 2.0, dt ** 2
        self.kf.processNoiseCov = np.array([
            [d4, 0, d3, 0],
            [0, d4, 0, d3],
            [d3, 0, d2, 0],
            [0, d3, 0, d2],
        ], np.float32) * np.float32(s2)

    def reset(self, x: float = 0.0, y: float = 0.0):
        """Reinicia el estado. Se llama cuando se pierde la bola mucho rato."""
        self.kf.statePost = np.array([[x], [y], [0.], [0.]], np.float32)
        self.kf.statePre = self.kf.statePost.copy()
        P = np.eye(4, dtype=np.float32)
        P[0, 0] = P[1, 1] = np.float32(self.meas_noise_std ** 2)
        P[2, 2] = P[3, 3] = np.float32(1e4)   # no sabemos nada de la velocidad
        self.kf.errorCovPost = P
        self.inicializado = False

    # --------------------------------------------------------------------- #
    def predict(self, dt: float = None) -> tuple:
        """Predice el estado. Debe llamarse SIEMPRE, haya bola o no."""
        if dt is not None:
            self._set_dt(dt)
        p = self.kf.predict()
        return float(p[0, 0]), float(p[1, 0]), float(p[2, 0]), float(p[3, 0])

    def update(self, meas_x: float, meas_y: float) -> tuple:
        """Corrige con la medida de la camara."""
        if not self.inicializado:
            # Arrancar en la primera medida evita un transitorio desde (0,0).
            self.kf.statePost = np.array(
                [[meas_x], [meas_y], [0.], [0.]], np.float32)
            self.kf.statePre = self.kf.statePost.copy()
            self.inicializado = True

        z = np.array([[np.float32(meas_x)], [np.float32(meas_y)]])
        e = self.kf.correct(z)
        return float(e[0, 0]), float(e[1, 0]), float(e[2, 0]), float(e[3, 0])

    @property
    def state(self) -> tuple:
        s = self.kf.statePost
        return float(s[0, 0]), float(s[1, 0]), float(s[2, 0]), float(s[3, 0])
