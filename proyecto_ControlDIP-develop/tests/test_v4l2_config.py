import unittest
from unittest.mock import patch

from src.camera.v4l2_config import V4L2Configurator


class TestV4L2Configurator(unittest.TestCase):
    def setUp(self):
        self.c = V4L2Configurator(device="/dev/video0")

    @patch('subprocess.run')
    def test_disable_auto_features(self, mock_run):
        self.c.disable_auto_features()
        mock_run.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'auto_exposure=1'], check=True)
        mock_run.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'white_balance_automatic=0'],
            check=True)
        mock_run.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'exposure_dynamic_framerate=0'],
            check=True)

    @patch('subprocess.run')
    def test_set_manual_exposure(self, mock_run):
        self.c.set_exposure(100)
        mock_run.assert_any_call(
            ['v4l2-ctl', '-d', '/dev/video0', '-c', 'exposure_time_absolute=100'],
            check=True)

    @patch('subprocess.run')
    def test_verify_reporta_problemas_si_no_lee(self, mock_run):
        # Con subprocess mockeado, _get no devuelve enteros: verify() debe
        # reportar que no pudo comprobar, en vez de dar por buena la config.
        self.assertFalse(self.c.verify())
        self.assertTrue(self.c.problemas)


if __name__ == '__main__':
    unittest.main()
