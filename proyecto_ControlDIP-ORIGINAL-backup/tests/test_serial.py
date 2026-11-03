import unittest
import struct
from unittest.mock import patch, MagicMock
from src.communication.transmitter import SerialTransmitter

class TestSerialTransmitter(unittest.TestCase):
    @patch('src.communication.transmitter.serial.Serial')
    def setUp(self, mock_serial):
        # Inicializamos el transmisor sin abrir puerto físico real
        self.transmitter = SerialTransmitter(port="/dev/ttyUSB0", baudrate=921600)

    def test_packet_creation(self):
        # Simulamos valores: Estado=1, X=10.0, Y=-5.0, Vx=0.0, Vy=2.5
        state = 1
        x, y, vx, vy = 10.0, -5.0, 0.0, 2.5
        
        packet = self.transmitter._build_packet(state, x, y, vx, vy)
        
        # Longitud exacta debe ser 20 bytes
        # 1 (Start) + 1 (State) + 16 (4 floats) + 1 (Checksum) + 1 (End) = 20
        self.assertEqual(len(packet), 20)
        
        # Verificar Cabecera y Pie
        self.assertEqual(packet[0], 0xAA)
        self.assertEqual(packet[-1], 0x55)
        
        # Verificar el payload desempaquetándolo
        payload = packet[1:18]
        unpacked = struct.unpack('<Bffff', payload)
        self.assertEqual(unpacked[0], state)
        self.assertAlmostEqual(unpacked[1], x, places=4)
        self.assertAlmostEqual(unpacked[2], y, places=4)
        self.assertAlmostEqual(unpacked[3], vx, places=4)
        self.assertAlmostEqual(unpacked[4], vy, places=4)
        
        # Verificar Checksum (XOR del payload)
        expected_checksum = 0
        for byte in payload:
            expected_checksum ^= byte
        self.assertEqual(packet[18], expected_checksum)

    @patch('src.communication.transmitter.serial.Serial')
    def test_send_data(self, mock_serial):
        transmitter = SerialTransmitter(port="/dev/ttyUSB0", baudrate=921600)
        # Inyectamos un mock para espiar si se llama a write()
        transmitter.serial_port = MagicMock()
        
        transmitter.send(1, 10.0, -5.0, 0.0, 2.5)
        
        # Verificamos que se llamó al método write de la librería serial
        self.assertTrue(transmitter.serial_port.write.called)

if __name__ == '__main__':
    unittest.main()