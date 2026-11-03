"""Homografia de pixeles a milimetros sobre el plano del plato."""

import os

import cv2
import numpy as np

from src import config


class PlateCalibrator:
    """Convierte los 4 puntos marcados en la imagen a un cuadrado en mm.

    IMPORTANTE: los cuatro puntos deben ser las ESQUINAS EXTERIORES de las
    marcas grabadas, no sus centros. Las cuatro esquinas exteriores estan a
    5 mm de cada borde del plato de 300 mm, asi que forman un cuadrado
    perfecto de 290 mm. Los centros no sirven: el patron de alineacion mide
    20 mm y los otros tres 28 mm, de modo que sus centros no son un cuadrado.
    """

    def __init__(self, plate_size_mm: float = None):
        if plate_size_mm is None:
            plate_size_mm = config.PLATE_SIZE_MM
        self.plate_size_mm = float(plate_size_mm)
        self.matrix = None
        self.roi = None          # (x, y, w, h) en pixeles
        self.px_per_mm = None

    # --------------------------------------------------------------------- #
    def calculate_homography(self, src_pts, frame_shape=None) -> np.ndarray:
        """src_pts: 4 puntos en pixeles, en sentido horario desde la esquina
        de referencia. Devuelve la matriz 3x3 y calcula ROI y escala."""
        pts_src = np.array(src_pts, dtype=np.float32).reshape(-1, 2)
        if pts_src.shape[0] != 4:
            raise ValueError("Se necesitan exactamente 4 puntos")

        s = self.plate_size_mm
        pts_dst = np.array([[0, 0], [s, 0], [s, s], [0, s]], dtype=np.float32)
        self.matrix = cv2.getPerspectiveTransform(pts_src, pts_dst)

        # ROI: caja que encierra los 4 puntos, con margen, recortada al frame.
        x, y, w, h = cv2.boundingRect(pts_src.astype(np.int32))
        m = config.ROI_MARGIN_PX
        x0, y0 = max(0, x - m), max(0, y - m)
        x1, y1 = x + w + m, y + h + m
        if frame_shape is not None:
            x1 = min(x1, frame_shape[1])
            y1 = min(y1, frame_shape[0])
        self.roi = (int(x0), int(y0), int(x1 - x0), int(y1 - y0))

        # Escala media: perimetro en pixeles entre perimetro en mm.
        per_px = sum(
            float(np.linalg.norm(pts_src[i] - pts_src[(i + 1) % 4]))
            for i in range(4)
        )
        self.px_per_mm = per_px / (4.0 * s)
        return self.matrix

    # --------------------------------------------------------------------- #
    def save(self, filename: str = None):
        filename = filename or config.CALIBRATION_FILE
        if self.matrix is None:
            raise RuntimeError("No hay matriz para guardar")
        np.savez(
            filename,
            matrix=self.matrix,
            roi=np.array(self.roi, dtype=np.int32),
            px_per_mm=np.float64(self.px_per_mm),
            plate_size_mm=np.float64(self.plate_size_mm),
        )
        print(f"Calibracion guardada en {filename}  "
              f"({self.px_per_mm:.3f} px/mm, ROI {self.roi})")

    @classmethod
    def load(cls, filename: str = None):
        """Devuelve un PlateCalibrator cargado, o None si no existe."""
        filename = filename or config.CALIBRATION_FILE
        if not os.path.exists(filename):
            return None
        d = np.load(filename)
        cal = cls(plate_size_mm=float(d["plate_size_mm"]))
        cal.matrix = d["matrix"]
        cal.roi = tuple(int(v) for v in d["roi"])
        cal.px_per_mm = float(d["px_per_mm"])
        return cal

    # Nombres antiguos, por compatibilidad con scripts viejos.
    def save_calibration(self, filename: str = None):
        self.save(filename)

    def load_calibration(self, filename: str = None):
        otra = PlateCalibrator.load(filename)
        if otra is None:
            return None
        self.matrix = otra.matrix
        self.roi = otra.roi
        self.px_per_mm = otra.px_per_mm
        self.plate_size_mm = otra.plate_size_mm
        return self.matrix
