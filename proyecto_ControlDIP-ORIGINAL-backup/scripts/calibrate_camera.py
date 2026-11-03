import cv2
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.camera.v4l2_config import V4L2Configurator
from src.processing.calibrator import PlateCalibrator

# Variables globales para los clics del mouse
clicked_points = []

def mouse_callback(event, x, y, flags, param):
    if event == cv2.EVENT_LBUTTONDOWN:
        if len(clicked_points) < 4:
            clicked_points.append((x, y))
            print(f"Punto registrado: ({x}, {y})")

def main():
    print("Iniciando Calibración...")
    
    # 1. Configurar Hardware
    cam_config = V4L2Configurator("/dev/video0")
    cam_config.disable_auto_features()
    cam_config.set_exposure(157) # Ajusta este valor si es necesario

    cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    if not cap.isOpened():
        print("Error al abrir la cámara.")
        return

    # 2. Fase de Previsualización en Vivo
    print("\n--- FASE 1: PREVISUALIZACIÓN ---")
    print("Acomoda la planta y la cámara.")
    print("Presiona la tecla 's' para capturar la foto y pasar a la calibración.")
    print("Presiona 'q' para salir.")
    
    frame_to_calibrate = None

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error leyendo la cámara.")
            break
            
        cv2.putText(frame, "Previsualizacion en vivo", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        cv2.putText(frame, "Presiona 's' para tomar foto", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        cv2.imshow("Video en Vivo", frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('s'):
            frame_to_calibrate = frame.copy()
            break
        elif key == ord('q'):
            cap.release()
            cv2.destroyAllWindows()
            return

    # Liberamos la cámara y cerramos la ventana de video en vivo
    cap.release()
    cv2.destroyWindow("Video en Vivo")

    if frame_to_calibrate is None:
        return

    # 3. Fase de Selección Manual (Clics)
    print("\n--- FASE 2: SELECCIÓN DE PUNTOS ---")
    print("Haz clic en las 4 marcas (esquinas) del plato en este orden exacto:")
    print("1. Superior Izquierda (o tu marca de referencia)")
    print("2. Superior Derecha")
    print("3. Inferior Derecha")
    print("4. Inferior Izquierda")
    print("Presiona 'c' para confirmar la matriz o 'r' para reiniciar los puntos.")

    clone = frame_to_calibrate.copy()
    cv2.namedWindow("Calibracion de Puntos")
    cv2.setMouseCallback("Calibracion de Puntos", mouse_callback)

    while True:
        img_display = clone.copy()
        
        # Dibujar los puntos seleccionados
        for i, pt in enumerate(clicked_points):
            cv2.circle(img_display, pt, 5, (0, 255, 0), -1)
            cv2.putText(img_display, str(i+1), (pt[0]+10, pt[1]-10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
            
            # Dibujar lineas conectando para ver el cuadrado
            if i > 0:
                cv2.line(img_display, clicked_points[i-1], clicked_points[i], (255, 0, 0), 2)
            if len(clicked_points) == 4:
                cv2.line(img_display, clicked_points[3], clicked_points[0], (255, 0, 0), 2)

        cv2.imshow("Calibracion de Puntos", img_display)
        key = cv2.waitKey(1) & 0xFF

        if key == ord('r'):
            clicked_points.clear()
            print("Puntos reiniciados.")
        elif key == ord('c') and len(clicked_points) == 4:
            break
        elif key == ord('q'):
            cv2.destroyAllWindows()
            return

    cv2.destroyAllWindows()

    # 4. Calcular y guardar
    calibrator = PlateCalibrator(plate_size_mm=300.0)
    calibrator.calculate_homography(clicked_points)
    calibrator.save_calibration("calibration_matrix.npy")
    print("¡Calibración exitosa! La matriz ha sido guardada en 'calibration_matrix.npy'.")

if __name__ == "__main__":
    main()