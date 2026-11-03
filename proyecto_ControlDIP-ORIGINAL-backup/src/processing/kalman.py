import cv2
import numpy as np

class BallKalmanFilter:
    def __init__(self, dt: float = 0.033):
        """
        Inicializa un Filtro de Kalman Lineal 2D.
        dt: Diferencial de tiempo entre frames (ej. 1/30 = 0.033 seg)
        """
        # 4 Estados dinámicos (x, y, vx, vy)
        # 2 Medidas (x, y) de la cámara
        self.kf = cv2.KalmanFilter(4, 2)
        
        # Matriz de Transición (A o F): Modelo cinemático (x = x_0 + v*dt)
        self.kf.transitionMatrix = np.array([
            [1, 0, dt, 0],
            [0, 1, 0, dt],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ], np.float32)
        
        # Matriz de Medición (H): Solo medimos posiciones
        self.kf.measurementMatrix = np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0]
        ], np.float32)
        
        # Ruido del proceso (Q): Qué tan errático es el movimiento real de la bola
        self.kf.processNoiseCov = np.eye(4, dtype=np.float32) * 1e-2
        
        # Ruido de medición (R): Qué tanta confianza le tenemos a la cámara
        self.kf.measurementNoiseCov = np.eye(2, dtype=np.float32) * 1e-3
        
        # Covarianza de error inicial (P)
        # Asignamos alta incertidumbre inicial (1000) a los estados de velocidad (índices 2 y 3)
        # para forzar al filtro a confiar en las primeras mediciones para hallar la derivada.
        self.kf.errorCovPost = np.eye(4, dtype=np.float32)
        self.kf.errorCovPost[2, 2] = 1000.0
        self.kf.errorCovPost[3, 3] = 1000.0        
        
        # Estado inicial (x, y, vx, vy)
        self.kf.statePost = np.zeros((4, 1), np.float32)

    def predict(self) -> tuple:
        """Predice dónde debería estar la bola antes de leer la cámara."""
        predicted = self.kf.predict()
        # Retorna X, Y, Vx, Vy
        return float(predicted[0][0]), float(predicted[1][0]), float(predicted[2][0]), float(predicted[3][0])

    def update(self, meas_x: float, meas_y: float) -> tuple:
        """
        Corrige la predicción con la medida real de la cámara.
        Retorna el estado filtrado (X, Y, Vx, Vy).
        """
        measurement = np.array([[np.float32(meas_x)], [np.float32(meas_y)]])
        estimated = self.kf.correct(measurement)
        
        return float(estimated[0][0]), float(estimated[1][0]), float(estimated[2][0]), float(estimated[3][0])