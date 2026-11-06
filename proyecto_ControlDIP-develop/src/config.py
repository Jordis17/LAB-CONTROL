"""Configuracion unica del sistema Ball on Plate.

TODOS los scripts leen de aqui. No dupliquen estos valores en otro archivo:
la calibracion de color solo es valida para la exposicion con que se hizo,
asi que si alguien cambia la exposicion en un script y no en los otros, la
calibracion queda invalida sin que nada lo avise.
"""

# --------------------------------------------------------------- Camara ---
CAMERA_DEVICE = "/dev/video0"
CAMERA_INDEX = 0
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
FRAME_FPS = 30

# MJPG o YUYV. Cual conviene se decide con run_benchmark.py --period en cada
# una de las dos; gana la que de menor periodo y menor jitter.
FOURCC = "YUYV"

# exposure_time_absolute va en unidades de 100 us, asi que 50 = 5.0 ms.
# El valor anterior (157 = 15.7 ms) era casi medio periodo de frame: una bola
# a 500 mm/s se corre 7.8 mm durante la exposicion y el centroide queda
# sesgado en la direccion del movimiento. Bajar esto exige MAS LUZ.
EXPOSURE_ABS = 50
WHITE_BALANCE_K = 4600

# ------------------------------------------------------------ Geometria ---
# Cuadrado formado por las ESQUINAS EXTERIORES de las cuatro marcas grabadas.
# Las marcas estan a 5 mm del borde del plato de 300 mm: 300 - 2*5 = 290.
# OJO: los CENTROS de las marcas no forman un cuadrado, porque el patron de
# alineacion mide 20 mm y los otros tres 28 mm.
PLATE_SIZE_MM = 290.0

BALL_DIAMETER_MM = 40.0

# Altura del lente sobre la cara superior del plato. Define la correccion de
# paralaje: el centro de la bola esta BALL_DIAMETER_MM/2 por encima del plano
# que calibra la homografia, asi que lo medido sale escalado hacia afuera.
CAMERA_HEIGHT_MM = 450.0

# True si el +Y que entrega la vision no coincide con el +Y mecanico.
# Se determina empujando la bola a mano hacia el servo Y y viendo si sube.
INVERT_Y = False

# Radio util del centro de la bola: (294/2) - 20 = 127 mm.
MAX_RADIUS_MM = 127.0

# ------------------------------------------------------------- Deteccion --
# Fracciones del area teorica de la bola en pixeles (pi * r_px^2).
BALL_AREA_MIN_FRAC = 0.35
BALL_AREA_MAX_FRAC = 2.50
CIRCULARITY_MIN = 0.70
MORPH_KERNEL = 5
ROI_MARGIN_PX = 25
# Margen extra sobre MAX_RADIUS_MM antes de descartar una deteccion por estar
# fuera del plato (absorbe el error de calibracion).
OUT_OF_PLATE_MARGIN_MM = 25.0

# ---------------------------------------------------------------- Filtro --
# MEDIR: dejar la bola quieta en el centro, grabar >=500 muestras y calcular
# la desviacion estandar en mm. Este valor es la raiz de R.
MEAS_NOISE_STD_MM = 0.11

# Aceleracion no modelada, en mm/s^2. El limite fisico es
# (5/7)*9810*sen(14 deg) = 1700 mm/s^2, que es lo que el plato puede imponer.
PROCESS_ACCEL_STD = 500.0

# Cuantos frames seguidos sin bola se toleran prediciendo antes de declarar
# "sin bola" y reiniciar el filtro.
MAX_COAST_FRAMES = 5

# ---------------------------------------------------------------- Serial --
SERIAL_PORT = "/dev/ttyUSB0"
SERIAL_BAUD = 921600
SERIAL_WRITE_TIMEOUT_S = 0.05
SERIAL_RECONNECT_S = 2.0

# -------------------------------------------------------------- Archivos --
CALIBRATION_FILE = "calibration.npz"
HSV_FILE = "hsv_config.json"
LOG_DIR = "logs"


def parallax_scale() -> float:
    """Factor que corrige el paralaje del centro de la bola.

    La homografia mapea el PLANO del plato, pero el centro de la bola esta a
    r = BALL_DIAMETER_MM/2 por encima de ese plano. Con la camara sobre el eje
    central, el efecto es exactamente un factor de escala: lo medido es
    d * H / (H - r), asi que la posicion real es lo medido por (H - r) / H.

    Con H = 450 mm y r = 20 mm da 0.956, o sea unos 6 mm de correccion en el
    borde util. Si la camara no queda sobre el centro, el error deja de ser un
    factor limpio: conviene plomar el portico.
    """
    r = BALL_DIAMETER_MM / 2.0
    if CAMERA_HEIGHT_MM <= r:
        raise ValueError("CAMERA_HEIGHT_MM debe ser mayor que el radio de la bola")
    return (CAMERA_HEIGHT_MM - r) / CAMERA_HEIGHT_MM
