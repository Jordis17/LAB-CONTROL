"""Envio de la trama binaria de estado a la ESP32."""

import struct
import time

import serial

from src import config


class SerialTransmitter:
    """Trama de 20 bytes: 0xAA | estado | x | y | vx | vy | checksum | 0x55.

    El formato NO cambio respecto a la version anterior, para no romper el
    firmware de la ESP32. Lo que cambio es que ahora los fallos se notan:
    antes, si el puerto no existia, send() no hacia nada en silencio y el lazo
    corria feliz sin que llegara un solo byte.
    """

    def __init__(self, port: str = None, baudrate: int = None,
                 obligatorio: bool = False):
        self.port = port or config.SERIAL_PORT
        self.baudrate = baudrate or config.SERIAL_BAUD
        self.serial_port = None
        self.enviados = 0
        self.fallos = 0
        self._ultimo_intento = 0.0
        self._rx = bytearray()
        self.telemetria_ok = 0
        self.telemetria_malas = 0
        self._connect()
        if obligatorio and not self.is_connected:
            raise RuntimeError(
                f"No se pudo abrir {self.port}. Con --require-serial esto aborta "
                f"en vez de correr el lazo sin enviar nada.")

    # --------------------------------------------------------------------- #
    @property
    def is_connected(self) -> bool:
        return self.serial_port is not None and self.serial_port.is_open

    def _connect(self) -> bool:
        self._ultimo_intento = time.monotonic()
        try:
            self.serial_port = serial.Serial(
                self.port, self.baudrate,
                timeout=0,
                write_timeout=config.SERIAL_WRITE_TIMEOUT_S,
            )
            print(f"Puerto serial conectado: {self.port} a {self.baudrate} bps")
            return True
        except serial.SerialException as e:
            print(f"AVISO: no se pudo conectar a {self.port}. {e}")
            self.serial_port = None
            return False

    def _reintentar(self):
        if time.monotonic() - self._ultimo_intento < config.SERIAL_RECONNECT_S:
            return False
        print(f"Reintentando conexion con {self.port}...")
        return self._connect()

    # --------------------------------------------------------------------- #
    def _build_packet(self, state: int, x: float, y: float,
                      vx: float, vy: float) -> bytes:
        payload = struct.pack('<Bffff', state, x, y, vx, vy)
        checksum = 0
        for byte in payload:
            checksum ^= byte
        return bytes([0xAA]) + payload + bytes([checksum, 0x55])

    def send(self, state: int, x: float, y: float,
             vx: float, vy: float) -> bool:
        """Devuelve True si la trama salio. Reintenta la conexion si se cayo."""
        if not self.is_connected and not self._reintentar():
            self.fallos += 1
            return False
        try:
            self.serial_port.write(self._build_packet(state, x, y, vx, vy))
            self.enviados += 1
            return True
        except (serial.SerialException, serial.SerialTimeoutException) as e:
            # Antes esto era 'pass' y las desconexiones pasaban inadvertidas.
            self.fallos += 1
            if self.fallos % 30 == 1:
                print(f"ERROR enviando por {self.port}: {e}")
            try:
                self.serial_port.close()
            except Exception:
                pass
            self.serial_port = None
            return False

    # ----------------------------------------------------------- telemetria --
    # Formatos del firmware bop_prueba_circulo_lazo (ver el .ino):
    #   0xBB: 49 bytes;  0xBC: 57 bytes (agrega descartadas, malas y loop_us)
    TEL_LARGOS = {0xBB: 49, 0xBC: 57}
    TEL_CAMPOS = ("modo", "banderas", "n", "t_ms", "thx", "thy", "leyx", "leyy",
                  "Ix", "Iy", "rx", "ry", "x_rx")

    @classmethod
    def _parse_telemetria(cls, b: bytes):
        """Trama de telemetria de la ESP32, o None si no es valida."""
        if not b or b[0] not in cls.TEL_LARGOS:
            return None
        n_bytes = cls.TEL_LARGOS[b[0]]
        if len(b) != n_bytes or b[-1] != 0x66:
            return None
        x = 0
        for byte in b[1:n_bytes - 2]:
            x ^= byte
        if x != b[n_bytes - 2]:
            return None
        modo, banderas, n, t_ms = struct.unpack('<BBII', b[1:11])
        f = struct.unpack('<9f', b[11:47])
        t = dict(zip(cls.TEL_CAMPOS, (modo, banderas, n, t_ms) + f))
        if b[0] == 0xBC:
            t["descartadas"], t["malas"], t["loop_us"] = struct.unpack('<HHI', b[47:55])
        return t

    def leer_telemetria(self):
        """Lee lo que mando la ESP32 y devuelve la ultima trama valida, o None.

        No bloquea (timeout=0). Si el firmware no manda telemetria (v1, v2),
        siempre devuelve None y el lazo sigue igual.
        """
        if not self.is_connected:
            return None
        try:
            k = self.serial_port.in_waiting
            if k:
                self._rx += self.serial_port.read(k)
        except (serial.SerialException, OSError):
            return None
        ultima = None
        while True:
            i = next((q for q, c in enumerate(self._rx) if c in self.TEL_LARGOS), -1)
            if i < 0:
                self._rx.clear()
                break
            if i > 0:
                del self._rx[:i]
            largo = self.TEL_LARGOS[self._rx[0]]
            if len(self._rx) < largo:
                break
            t = self._parse_telemetria(bytes(self._rx[:largo]))
            if t is None:
                self.telemetria_malas += 1
                del self._rx[0]           # resincronizar
                continue
            ultima = t
            self.telemetria_ok += 1
            del self._rx[:largo]
        if len(self._rx) > 4096:          # basura sin cabecera valida
            self._rx.clear()
        return ultima

    def send_idle(self):
        """Trama de 'sin bola'. Le dice a la ESP32 que lleve el plato a cero."""
        self.send(0, 0.0, 0.0, 0.0, 0.0)

    def close(self):
        """Salida segura: avisa estado 0 y cierra el puerto.

        Sin esto, al matar el programa la ESP32 se queda con el ultimo comando
        y los servos quedan forzados en una posicion, calentandose.
        """
        if self.is_connected:
            try:
                self.send_idle()
                self.serial_port.flush()
            except Exception:
                pass
            try:
                self.serial_port.close()
            except Exception:
                pass
        self.serial_port = None
        print(f"Serial cerrado. Tramas enviadas: {self.enviados}, fallos: {self.fallos}, "
              f"telemetria recibida: {self.telemetria_ok} (malas: {self.telemetria_malas})")

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()
        return False
