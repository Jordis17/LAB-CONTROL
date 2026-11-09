import struct
import unittest
from unittest.mock import MagicMock, patch

import serial

from src.communication.transmitter import SerialTransmitter


class TestSerialTransmitter(unittest.TestCase):
    @patch('src.communication.transmitter.serial.Serial')
    def setUp(self, mock_serial):
        self.tx = SerialTransmitter(port="/dev/ttyUSB0", baudrate=921600)

    def test_packet_creation(self):
        state, x, y, vx, vy = 1, 10.0, -5.0, 0.0, 2.5
        packet = self.tx._build_packet(state, x, y, vx, vy)

        self.assertEqual(len(packet), 20)
        self.assertEqual(packet[0], 0xAA)
        self.assertEqual(packet[-1], 0x55)

        payload = packet[1:18]
        un = struct.unpack('<Bffff', payload)
        self.assertEqual(un[0], state)
        self.assertAlmostEqual(un[1], x, places=4)
        self.assertAlmostEqual(un[2], y, places=4)
        self.assertAlmostEqual(un[3], vx, places=4)
        self.assertAlmostEqual(un[4], vy, places=4)

        chk = 0
        for b in payload:
            chk ^= b
        self.assertEqual(packet[18], chk)

    @patch('src.communication.transmitter.serial.Serial')
    def test_send_data(self, mock_serial):
        tx = SerialTransmitter(port="/dev/ttyUSB0", baudrate=921600)
        tx.serial_port = MagicMock()
        self.assertTrue(tx.send(1, 10.0, -5.0, 0.0, 2.5))
        self.assertTrue(tx.serial_port.write.called)
        self.assertEqual(tx.enviados, 1)

    @patch('src.communication.transmitter.serial.Serial',
           side_effect=serial.SerialException("no existe"))
    def test_sin_puerto_no_finge_exito(self, mock_serial):
        tx = SerialTransmitter(port="/dev/ttyNADA")
        self.assertFalse(tx.is_connected)
        self.assertFalse(tx.send(1, 0, 0, 0, 0))
        self.assertEqual(tx.fallos, 1)

    @patch('src.communication.transmitter.serial.Serial',
           side_effect=serial.SerialException("no existe"))
    def test_obligatorio_aborta(self, mock_serial):
        with self.assertRaises(RuntimeError):
            SerialTransmitter(port="/dev/ttyNADA", obligatorio=True)

    @patch('src.communication.transmitter.serial.Serial')
    def test_error_de_escritura_no_se_traga(self, mock_serial):
        tx = SerialTransmitter(port="/dev/ttyUSB0")
        tx.serial_port = MagicMock()
        tx.serial_port.write.side_effect = serial.SerialException("cable")
        self.assertFalse(tx.send(1, 0, 0, 0, 0))
        self.assertEqual(tx.fallos, 1)
        self.assertFalse(tx.is_connected)

    @patch('src.communication.transmitter.serial.Serial')
    def test_close_envia_estado_cero(self, mock_serial):
        tx = SerialTransmitter(port="/dev/ttyUSB0")
        puerto = MagicMock()
        tx.serial_port = puerto
        tx.close()
        ultima = puerto.write.call_args[0][0]
        self.assertEqual(ultima[1], 0)        # estado = 0
        self.assertTrue(puerto.close.called)




class TestTelemetria(unittest.TestCase):
    @staticmethod
    def trama(modo=2, banderas=1, n=7, t_ms=1234, f=(1.5, -2.0, 1.6, -2.1, 0.01, -0.02, 30.0, 40.0, 12.5)):
        cuerpo = struct.pack('<BBII9f', modo, banderas, n, t_ms, *f)
        x = 0
        for b in cuerpo:
            x ^= b
        return bytes([0xBB]) + cuerpo + bytes([x, 0x66])

    def test_parse(self):
        t = SerialTransmitter._parse_telemetria(self.trama())
        self.assertEqual(len(self.trama()), 49)
        self.assertEqual(t["modo"], 2)
        self.assertEqual(t["n"], 7)
        self.assertAlmostEqual(t["thx"], 1.5, places=5)
        self.assertAlmostEqual(t["x_rx"], 12.5, places=5)

    def test_parse_formato_2(self):
        cuerpo = struct.pack('<BBII9fHHI', 1, 0, 9, 500, *([0.5] * 9), 3, 7, 41000)
        x = 0
        for b in cuerpo:
            x ^= b
        t = SerialTransmitter._parse_telemetria(bytes([0xBC]) + cuerpo + bytes([x, 0x66]))
        self.assertEqual(len(cuerpo) + 3, 57)
        self.assertEqual(t["n"], 9)
        self.assertEqual(t["descartadas"], 3)
        self.assertEqual(t["loop_us"], 41000)

    def test_checksum_malo(self):
        b = bytearray(self.trama());  b[20] ^= 0xFF
        self.assertIsNone(SerialTransmitter._parse_telemetria(bytes(b)))

    @patch('src.communication.transmitter.serial.Serial')
    def test_leer_con_basura_y_dos_tramas(self, mock_serial):
        tx = SerialTransmitter(port="/dev/ttyUSB0")
        datos = b"\x00\x12basura" + self.trama(n=1) + self.trama(n=2)[:20]
        tx.serial_port = MagicMock()
        tx.serial_port.in_waiting = len(datos)
        tx.serial_port.read.return_value = datos
        t = tx.leer_telemetria()
        self.assertEqual(t["n"], 1)
        resto = self.trama(n=2)[20:]
        tx.serial_port.in_waiting = len(resto)
        tx.serial_port.read.return_value = resto
        self.assertEqual(tx.leer_telemetria()["n"], 2)
        self.assertEqual(tx.telemetria_ok, 2)


if __name__ == '__main__':
    unittest.main()
