"""Apertura de la camara con los ajustes que importan para la latencia."""

import cv2

from src import config
from src.camera.v4l2_config import V4L2Configurator


def abrir_camara(index: int = None, aplicar_v4l2: bool = True, buffers: int = None):
    """Devuelve un cv2.VideoCapture listo, o None.

    Las dos lineas que mas latencia quitan y que faltaban antes:
      - BUFFERSIZE = 1: sin esto OpenCV encola frames y la latencia crece
        sola durante la sesion.
      - FOURCC explicito: si no se fija, el driver negocia lo que quiera y
        MJPG o YUYV cambian bastante el periodo y la latencia.
    """
    if aplicar_v4l2:
        V4L2Configurator().apply_defaults()

    idx = config.CAMERA_INDEX if index is None else index
    cap = cv2.VideoCapture(idx, cv2.CAP_V4L2)
    if not cap.isOpened():
        print(f"Error: no se pudo abrir la camara {idx}")
        return None

    cap.set(cv2.CAP_PROP_FOURCC,
            cv2.VideoWriter_fourcc(*config.FOURCC))
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, config.FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, config.FRAME_HEIGHT)
    cap.set(cv2.CAP_PROP_FPS, config.FRAME_FPS)
    nb = config.CAMERA_BUFFERS if buffers is None else buffers
    cap.set(cv2.CAP_PROP_BUFFERSIZE, nb)

    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    f = cap.get(cv2.CAP_PROP_FPS)
    cc = int(cap.get(cv2.CAP_PROP_FOURCC))
    cc = "".join(chr((cc >> 8 * i) & 0xFF) for i in range(4))
    print(f"Camara abierta: {w}x{h} @ {f:g} fps, formato {cc}, "
          f"buffers {int(cap.get(cv2.CAP_PROP_BUFFERSIZE))} (pedidos {nb})")
    if (w, h) != (config.FRAME_WIDTH, config.FRAME_HEIGHT):
        print(f"AVISO: se pidio {config.FRAME_WIDTH}x{config.FRAME_HEIGHT} "
              f"y el driver entrego {w}x{h}")
    return cap
