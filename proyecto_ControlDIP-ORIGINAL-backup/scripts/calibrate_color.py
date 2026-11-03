import cv2
import numpy as np
import sys
import os
import json

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.camera.v4l2_config import V4L2Configurator

def nothing(x):
    pass

def main():
    print("Iniciando Calibrador de Color HSV...")
    
    # 1. Configurar Hardware (La cámara debe estar configurada EXACTAMENTE igual que en el entorno real)
    cam_config = V4L2Configurator("/dev/video0")
    cam_config.disable_auto_features()
    cam_config.set_exposure(157) # Ajusta si necesitas más luz

    cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    if not cap.isOpened():
        print("Error al abrir la cámara.")
        return

    # 2. Crear Ventana y Trackbars
    cv2.namedWindow("Ajuste HSV")
    cv2.namedWindow("Mascara")
    
    # Valores iniciales (Rango completo)
    cv2.createTrackbar("H_MIN", "Ajuste HSV", 0, 179, nothing)
    cv2.createTrackbar("H_MAX", "Ajuste HSV", 179, 179, nothing)
    cv2.createTrackbar("S_MIN", "Ajuste HSV", 0, 255, nothing)
    cv2.createTrackbar("S_MAX", "Ajuste HSV", 255, 255, nothing)
    cv2.createTrackbar("V_MIN", "Ajuste HSV", 0, 255, nothing)
    cv2.createTrackbar("V_MAX", "Ajuste HSV", 255, 255, nothing)

    print("\nINSTRUCCIONES:")
    print("1. Pon la bola sobre el plato iluminado.")
    print("2. Mueve los deslizadores hasta que en la ventana 'Mascara' la bola sea BLANCA y todo lo demás NEGRO.")
    print("3. Presiona 'g' para guardar los valores y salir.")
    print("4. Presiona 'q' para salir sin guardar.")

    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        
        # Leer valores actuales de los trackbars
        h_min = cv2.getTrackbarPos("H_MIN", "Ajuste HSV")
        h_max = cv2.getTrackbarPos("H_MAX", "Ajuste HSV")
        s_min = cv2.getTrackbarPos("S_MIN", "Ajuste HSV")
        s_max = cv2.getTrackbarPos("S_MAX", "Ajuste HSV")
        v_min = cv2.getTrackbarPos("V_MIN", "Ajuste HSV")
        v_max = cv2.getTrackbarPos("V_MAX", "Ajuste HSV")
        
        lower_bound = np.array([h_min, s_min, v_min])
        upper_bound = np.array([h_max, s_max, v_max])
        
        # Aplicar máscara
        mask = cv2.inRange(hsv, lower_bound, upper_bound)
        
        # Operaciones morfológicas para limpiar ruido (Igual que en detector.py)
        kernel = np.ones((5, 5), np.uint8)
        mask = cv2.erode(mask, kernel, iterations=1)
        mask = cv2.dilate(mask, kernel, iterations=2)
        
        # Resultado visual
        result = cv2.bitwise_and(frame, frame, mask=mask)
        
        cv2.imshow("Ajuste HSV", result)
        cv2.imshow("Mascara", mask)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('g'):
            data = {
                "hsv_lower": [h_min, s_min, v_min],
                "hsv_upper": [h_max, s_max, v_max]
            }
            with open("hsv_config.json", "w") as f:
                json.dump(data, f)
            print(f"\n¡Valores guardados en hsv_config.json!")
            print(f"Lower: {lower_bound}")
            print(f"Upper: {upper_bound}")
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()