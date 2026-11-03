"""Bloqueo de los automatismos de la camara via V4L2 (Linux).

Si estos controles no se aplican, la camara cambia sola la exposicion y el
balance de blancos durante la sesion, y la calibracion HSV deja de valer.
Por eso aqui se VERIFICA leyendo de vuelta, en lugar de confiar en que el
comando no fallo.
"""

import subprocess

from src import config


class V4L2Configurator:
    """Configura parametros de hardware de la camara via v4l2-ctl."""

    # Algunos kernels/camaras usan nombres distintos para el mismo control.
    ALIASES = {
        "auto_exposure": ("auto_exposure", "exposure_auto"),
        "white_balance_automatic": ("white_balance_automatic", "white_balance_temperature_auto"),
        "exposure_time_absolute": ("exposure_time_absolute", "exposure_absolute"),
        "exposure_dynamic_framerate": ("exposure_dynamic_framerate",),
        "white_balance_temperature": ("white_balance_temperature",),
    }

    def __init__(self, device: str = None):
        self.device = device or config.CAMERA_DEVICE
        self.problemas = []

    # ------------------------------------------------------------ interno --
    def _run_command(self, control: str, value: int):
        """Ejecuta v4l2-ctl -c control=value. Devuelve True si no fallo."""
        try:
            subprocess.run(
                ['v4l2-ctl', '-d', self.device, '-c', f'{control}={value}'],
                check=True,
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error configurando {control}: {e}")
            return False
        except FileNotFoundError:
            print("ERROR: v4l2-ctl no esta instalado (apt install v4l-utils)")
            return False

    def _get(self, control: str):
        """Lee el valor actual de un control. None si no existe."""
        try:
            out = subprocess.run(
                ['v4l2-ctl', '-d', self.device, '-C', control],
                check=True, capture_output=True, text=True,
            ).stdout
            return int(out.strip().split(':')[-1])
        except Exception:
            return None

    def _set_any(self, clave: str, value: int):
        """Prueba los alias de un control hasta que uno funcione."""
        for nombre in self.ALIASES.get(clave, (clave,)):
            if self._get(nombre) is None:
                continue
            if self._run_command(nombre, value):
                return nombre
        self.problemas.append(f"{clave}: no se pudo aplicar (= {value})")
        return None

    # ------------------------------------------------------------ publico --
    def disable_auto_features(self):
        """Apaga exposicion automatica, balance automatico y framerate dinamico."""
        # 1 = Manual Mode en la API nueva de UVC.
        self._run_command('auto_exposure', 1)
        self._run_command('white_balance_automatic', 0)
        # 0 = FPS fijos. Critico: con FPS variables el dt del filtro no es fiable.
        self._run_command('exposure_dynamic_framerate', 0)
        # Reintento con alias por si la camara usa los nombres viejos.
        if self._get('auto_exposure') is None:
            self._set_any('auto_exposure', 1)
        if self._get('white_balance_automatic') is None:
            self._set_any('white_balance_automatic', 0)

    def set_exposure(self, value: int):
        """Tiempo de exposicion absoluto, en unidades de 100 us."""
        self._run_command('exposure_time_absolute', value)
        if self._get('exposure_time_absolute') is None:
            self._set_any('exposure_time_absolute', value)

    def set_white_balance_temp(self, value: int):
        """Temperatura de color (tipico 2800 a 6500 K)."""
        self._run_command('white_balance_temperature', value)

    def apply_defaults(self):
        """Aplica toda la configuracion de src/config.py y la verifica."""
        self.problemas = []
        self.disable_auto_features()
        self.set_exposure(config.EXPOSURE_ABS)
        self.set_white_balance_temp(config.WHITE_BALANCE_K)
        return self.verify()

    def verify(self):
        """Lee de vuelta los controles criticos. Avisa fuerte si no cuadran."""
        esperado = {
            'auto_exposure': 1,
            'white_balance_automatic': 0,
            'exposure_time_absolute': config.EXPOSURE_ABS,
        }
        for clave, valor in esperado.items():
            leido = None
            for nombre in self.ALIASES.get(clave, (clave,)):
                leido = self._get(nombre)
                if leido is not None:
                    break
            if leido is None:
                self.problemas.append(f"{clave}: el control no existe en {self.device}")
            elif leido != valor:
                self.problemas.append(f"{clave}: quedo en {leido}, se pidio {valor}")

        if self.problemas:
            print("\n" + "!" * 68)
            print("AVISO: la camara NO quedo bloqueada como se pidio.")
            for p in self.problemas:
                print("  - " + p)
            print("Con automatismos activos la calibracion HSV y el dt del filtro")
            print("dejan de ser validos durante la sesion.")
            print("Revise 'v4l2-ctl -d %s --list-ctrls'" % self.device)
            print("!" * 68 + "\n")
            return False

        print(f"Camara {self.device}: automatismos bloqueados y verificados.")
        return True
