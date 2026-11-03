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


if __name__ == '__main__':
    unittest.main()
