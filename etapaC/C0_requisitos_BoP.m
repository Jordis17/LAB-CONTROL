function Rq = C0_requisitos_BoP()
%C0_REQUISITOS_BOP Requisitos de desempeno y definiciones de las metricas.
%
% No hay enunciado oficial del proyecto final (2026-11-03). Estos requisitos
% los propuso la IA y los acepto el equipo. Son DECISIONES DE INGENIERIA, no
% requisitos del curso. Se usan IGUALES en MIL (Etapa D) y en el experimento
% (Etapa H), con las mismas definiciones (CLAUDE.md, seccion 9).
%
% Ensayo de referencia: bola en reposo a x0 = 100 mm en un eje, referencia 0.

Rq.x0_mm      = 100;     % posicion inicial del ensayo de requisitos [mm]
Rq.ts_max_s   = 3.0;     % R1: tiempo de establecimiento [s]
Rq.Mp_max_pct = 20;      % R2: sobreimpulso [% del cambio]
Rq.ess_max_mm = 3.0;     % R3: error estacionario [mm]
Rq.x_lim_mm   = 127;     % R4: la bola nunca sale de +-127 mm (marco del plato)

% Criterios de diseno en frecuencia (tambien decision de ingenieria)
Rq.PM_min_deg   = 40;    % margen de fase minimo
Rq.GM_min_dB    = 6;     % margen de ganancia minimo (por arriba y por abajo)

% ---- Definiciones de las metricas (una sola para todo el proyecto) ----
% Senal: posicion FILTRADA por el Kalman (x_hat), en los instantes de cuadro.
%   Es la misma senal que registra main_vision.py, asi que la definicion se
%   puede aplicar igual a datos simulados y experimentales.
% Cambio:   D = r - x0 (r: referencia final; x0: posicion al iniciar el ensayo).
% tr:       tiempo entre el 10 % y el 90 % de D (primer cruce de cada nivel).
% ts:       ultimo instante en que |x - r| > banda, con banda = 5 % de |D|,
%           medido desde el inicio del ensayo.
% Mp:       max(0, max((x - r)*sign(D))) / |D| * 100.
% ess:      |media(x - r)| en el ultimo segundo del ensayo.
% Ademas:   max|x| (marco del plato, del modelo), min y max de th_cmd,
%           porcentaje del tiempo con th_cmd saturado.
Rq.banda_frac = 0.05;
Rq.ventana_ess_s = 1.0;
end
