import cv2
import time
import sys
import os

# Agregar la raíz del proyecto al path para poder importar 'src'
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.camera.v4l2_config import V4L2Configurator

def main():
    # 1. Configuración de Hardware
    print("Configurando hardware de la cámara...")
    cam_config = V4L2Configurator("/dev/video0")
    cam_config.disable_auto_features()
    cam_config.set_exposure(157) # Ajusta este valor según tus pruebas (menor = más oscuro pero sin blur)

    # 2. Inicialización de Captura (OpenCV)
    cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 30)

    if not cap.isOpened():
        print("Error: No se pudo abrir la cámara.")
        return

    prev_frame_time = 0
    print("Iniciando Benchmarking... Presiona 'q' para salir.")

    while True:
        new_frame_time = time.time()
        ret, frame = cap.read()
        if not ret:
            break
        
        fps = 1 / (new_frame_time - prev_frame_time)
        prev_frame_time = new_frame_time
        latency_ms = (time.time() - new_frame_time) * 1000

        cv2.putText(frame, f"FPS: {int(fps)}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.putText(frame, f"Read Time: {latency_ms:.1f} ms", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        
        cv2.imshow('Benchmarking Redragon GW800', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()