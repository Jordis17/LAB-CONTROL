import subprocess

class V4L2Configurator:
    """Clase para configurar parámetros de hardware de la cámara vía V4L2 en Linux."""
    
    def __init__(self, device: str = "/dev/video0"):
        self.device = device

    def _run_command(self, control: str, value: int):
        """Ejecuta el comando v4l2-ctl en el sistema."""
        try:
            subprocess.run(
                ['v4l2-ctl', '-d', self.device, '-c', f'{control}={value}'],
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Error configurando {control}: {e}")

    def disable_auto_features(self):
        """Apaga los ajustes automáticos basados en los controles de la Redragon GW800."""
        # 1 = Manual (Aperture Priority Mode a Manual)
        self._run_command('auto_exposure', 1)
        # 0 = Apagado
        self._run_command('white_balance_automatic', 0)
        # 0 = FPS Fijos (Crítico para el Filtro de Kalman)
        self._run_command('exposure_dynamic_framerate', 0)

    def set_exposure(self, value: int):
        """Ajusta el tiempo de exposición absoluto (min=1, max=5000)."""
        self._run_command('exposure_time_absolute', value)
        
    def set_white_balance_temp(self, value: int):
        """Ajusta la temperatura de color (min=2800, max=6500)."""
        self._run_command('white_balance_temperature', value)