import unittest
from unittest.mock import patch
from src.camera.v4l2_config import V4L2Configurator

class TestV4L2Configurator(unittest.TestCase):
    def setUp(self):
        self.configurator = V4L2Configurator(device="/dev/video0")

    @patch('subprocess.run')
    def test_disable_auto_features(self, mock_subprocess):
        # Ejecutamos el método
        self.configurator.disable_auto_features()
        
        # Verificamos que se haya llamado con los comandos exactos de tu Redragon
        mock_subprocess.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'auto_exposure=1'], check=True
        )
        mock_subprocess.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'white_balance_automatic=0'], check=True
        )
        mock_subprocess.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'exposure_dynamic_framerate=0'], check=True
        )

    @patch('subprocess.run')
    def test_set_manual_exposure(self, mock_subprocess):
        self.configurator.set_exposure(100)
        mock_subprocess.assert_called_with(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'exposure_time_absolute=100'], check=True
        )

if __name__ == '__main__':
    unittest.main()