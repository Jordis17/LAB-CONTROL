import cv2
import numpy as np
import os

class PlateCalibrator:
    def __init__(self, plate_size_mm: float = 300.0):
        self.plate_size_mm = plate_size_mm
        self.matrix = None

    def calculate_homography(self, src_pts: list) -> np.ndarray:
        """
        Calcula la matriz de transformación desde los 4 píxeles seleccionados 
        hacia un cuadrado perfecto en milímetros.
        """
        pts_src = np.array(src_pts, dtype=np.float32)
        
        pts_dst = np.array([
            [0, 0],
            [self.plate_size_mm, 0],
            [self.plate_size_mm, self.plate_size_mm],
            [0, self.plate_size_mm]
        ], dtype=np.float32)

        self.matrix = cv2.getPerspectiveTransform(pts_src, pts_dst)
        return self.matrix

    def save_calibration(self, filename: str = "calibration_data.npy"):
        if self.matrix is not None:
            np.save(filename, self.matrix)
            print(f"Matriz de calibración guardada en {filename}")
        else:
            print("Error: No hay matriz para guardar.")

    def load_calibration(self, filename: str = "calibration_data.npy"):
        if os.path.exists(filename):
            self.matrix = np.load(filename)
            return self.matrix
        return None