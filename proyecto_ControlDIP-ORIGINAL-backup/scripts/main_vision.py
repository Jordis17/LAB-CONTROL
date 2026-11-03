import cv2
import time
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.camera.v4l2_config import V4L2Configurator
from src.processing.calibrator import PlateCalibrator
from src.processing.detector import BallDetector
from src.processing.kalman import BallKalmanFilter
from src.communication.transmitter import SerialTransmitter

def main():
    print("Iniciando Sistema de Visión y Predicción...")

    # 1. Configurar Hardware
    cam_config = V4L2Configurator("/dev/video0")
    cam_config.disable_auto_features()
    cam_config.set_exposure(157) # Ajustar según las pruebas de luz

    # 2. Cargar Calibraciones
    calibrator = PlateCalibrator(plate_size_mm=300.0)
    homography_matrix = calibrator.load_calibration("calibration_matrix.npy")
    
    if homography_matrix is None:
        print("CRÍTICO: No se encontró calibration_matrix.npy. Ejecuta calibrate_camera.py primero.")
        return

    # 3. Inicializar Módulos de Procesamiento
    detector = BallDetector(homography_matrix=homography_matrix, hsv_config_path="hsv_config.json")
    kalman_filter = BallKalmanFilter(dt=0.033) # 30 FPS

    # 4. Inicializar Transmisor Serial
    # En Linux, las ESP32 usualmente montan en ttyUSB0 o ttyUSB1
    transmitter = SerialTransmitter(port="/dev/ttyUSB0", baudrate=921600)

    # 5. Inicializar Cámara
    cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 30)

    if not cap.isOpened():
        print("Error al abrir la cámara.")
        return

    print("\n¡Bucle de Control Activo! Presiona 'q' en la ventana para salir.")
    
    prev_frame_time = 0

    while True:
        new_frame_time = time.time()
        ret, frame = cap.read()
        
        if not ret:
            print("Pérdida de fotograma.")
            continue
        
        # Calcular FPS reales
        fps = 1 / (new_frame_time - prev_frame_time)
        prev_frame_time = new_frame_time

        # Pipeline de Visión
        x_raw, y_raw, ball_found = detector.detect(frame)
        
        # Pipeline Matemático y Estructura de Salida
        if ball_found:
            # Siempre se debe predecir antes de actualizar
            kalman_filter.predict()
            x_filt, y_filt, vx, vy = kalman_filter.update(x_raw, y_raw)
            estado_presencia = 1
        else:
            # Si no hay bola, enviamos todo en 0 y presencia en 0
            x_filt, y_filt, vx, vy = 0.0, 0.0, 0.0, 0.0
            estado_presencia = 0

        # --- Enviar Trama Binaria a ESP32 ---
        transmitter.send(estado_presencia, x_filt, y_filt, vx, vy)

        # Print esporádico para no saturar la terminal (cada ~30 frames)
        if int(new_frame_time * 10) % 10 == 0:
            print(f"ESTADO: {estado_presencia} | X: {x_filt:6.1f} | Y: {y_filt:6.1f} | Vx: {vx:6.1f} | Vy: {vy:6.1f} | FPS: {fps:.1f}")

        
        # --- Visualización para Depuración ---
        # Dibujamos un círculo donde el Filtro de Kalman "cree" que está la bola
        if ball_found:
            # Convertir mm de vuelta a píxeles (aproximado solo para dibujo visual)
            # Como restamos 150mm en el detector, sumamos 150mm para volver a coordenadas relativas del plato
            # Esto es solo visual, la ESP32 usará los milímetros limpios.
            cv2.putText(frame, f"X:{x_filt:.1f} Y:{y_filt:.1f} mm", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
            cv2.putText(frame, f"Vx:{vx:.1f} Vy:{vy:.1f} mm/s", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)
        else:
            cv2.putText(frame, "BOLA NO ENCONTRADA", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)

        cv2.imshow("Main Control Vision", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()