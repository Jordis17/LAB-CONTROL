import cv2
import numpy as np
import json
import os

class BallDetector:
    def __init__(self, homography_matrix: np.ndarray = None, hsv_config_path: str = "hsv_config.json"):

        """
        homography_matrix: La matriz 3x3 cargada desde 'calibration_matrix.npy'
        hsv_config_path: Ruta al archivo JSON con los valores de color
        """
        self.homography_matrix = homography_matrix
        
        # Cargar configuración HSV o usar valores por defecto
        if os.path.exists(hsv_config_path):
            with open(hsv_config_path, 'r') as f:
                data = json.load(f)
                self.hsv_lower = np.array(data["hsv_lower"])
                self.hsv_upper = np.array(data["hsv_upper"])
            print(f"Configuración HSV cargada exitosamente desde {hsv_config_path}")
        else:
            print(f"Advertencia: No se encontró {hsv_config_path}. Usando verde por defecto.")
            self.hsv_lower = np.array([35, 100, 100])
            self.hsv_upper = np.array([85, 255, 255])

    def detect(self, frame: np.ndarray) -> tuple:
        """
        Procesa el frame, busca la bola y devuelve su posición (X, Y) en milímetros.
        Retorna: (x_mm, y_mm, bola_encontrada_booleano)
        """
        # 1. Convertir a HSV
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        
        # 2. Crear una máscara (Blanco donde esté el color, negro en el resto)
        mask = cv2.inRange(hsv, self.hsv_lower, self.hsv_upper)
        
        # 3. Limpiar ruido (mosaico) usando operaciones morfológicas (Erosión y Dilatación)
        kernel = np.ones((5, 5), np.uint8)
        mask = cv2.erode(mask, kernel, iterations=1)
        mask = cv2.dilate(mask, kernel, iterations=2)
        
        # 4. Encontrar contornos
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if len(contours) > 0:
            # Asumimos que la bola es el contorno más grande del color correcto
            largest_contour = max(contours, key=cv2.contourArea)
            
            # 5. Calcular el centro de masa (Centroide) en Píxeles
            M = cv2.moments(largest_contour)
            if M["m00"] > 0:
                cx_px = int(M["m10"] / M["m00"])
                cy_px = int(M["m01"] / M["m00"])
                
                # 6. Convertir píxeles a Milímetros (Homografía)
                if self.homography_matrix is not None:
                    # OpenCV requiere un formato específico para transformar un solo punto
                    pt_px = np.array([[[cx_px, cy_px]]], dtype=np.float32)
                    pt_mm = cv2.perspectiveTransform(pt_px, self.homography_matrix)
                    
                    x_mm = float(pt_mm[0][0][0])
                    y_mm = float(pt_mm[0][0][1])
                    
                    # Desplazamos el origen al centro del plato (Restamos 150mm)
                    # Asumiendo plato de 300x300
                    x_centro = x_mm - 150.0
                    y_centro = y_mm - 150.0
                    
                    return x_centro, y_centro, True
                else:
                    # Si no hay matriz, devolvemos píxeles crudos (para depuración)
                    return float(cx_px), float(cy_px), True
                    
        # Si no encontró la bola o el contorno es inválido
        return 0.0, 0.0, False