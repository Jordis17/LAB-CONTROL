import serial
import struct

class SerialTransmitter:
    def __init__(self, port: str = "/dev/ttyUSB0", baudrate: int = 921600):
        self.port = port
        self.baudrate = baudrate
        self.serial_port = None
        self._connect()

    def _connect(self):
        """Intenta abrir el puerto serial de forma segura."""
        try:
            self.serial_port = serial.Serial(self.port, self.baudrate, timeout=0)
            print(f"Puerto Serial conectado: {self.port} a {self.baudrate} bps")
        except serial.SerialException as e:
            print(f"Advertencia: No se pudo conectar a {self.port}. Error: {e}")
            self.serial_port = None

    def _build_packet(self, state: int, x: float, y: float, vx: float, vy: float) -> bytes:
        """
        Construye una trama binaria de 20 bytes en formato Little-Endian.
        [0xAA] [State: uchar] [X: float] [Y: float] [Vx: float] [Vy: float] [Checksum: uchar] [0x55]
        """
        # '<Bffff' -> Little-endian, 1 unsigned char, 4 floats (17 bytes)
        payload = struct.pack('<Bffff', state, x, y, vx, vy)
        
        # Calcular Checksum XOR (Protección contra ruido en el cable)
        checksum = 0
        for byte in payload:
            checksum ^= byte
            
        # Ensamblar: Cabecera (0xAA) + Payload + Checksum + Pie (0x55)
        packet = bytes([0xAA]) + payload + bytes([checksum, 0x55])
        return packet

    def send(self, state: int, x: float, y: float, vx: float, vy: float):
        """Envía la trama a la ESP32 si el puerto está abierto."""
        packet = self._build_packet(state, x, y, vx, vy)
        
        if self.serial_port and self.serial_port.is_open:
            try:
                self.serial_port.write(packet)
            except serial.SerialException:
                pass