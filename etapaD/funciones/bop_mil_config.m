function cfg = bop_mil_config(P, C)
%BOP_MIL_CONFIG Configuracion nominal de una simulacion MIL (ver bop_mil_simular).
%
%   cfg = bop_mil_config(P, C)   y luego se cambian los campos del caso.
%
% Todos los casos de la Etapa D parten de aqui, asi que comparten planta,
% Ts, retardo, configuracion numerica y condiciones, salvo lo que el caso
% cambia a proposito.

cfg.P = P;                      % parametros de la planta (A0_parametros_BoP)
cfg.C = C;                      % controlador (C1_controlador.mat)
cfg.planta = 'no_lineal';       % 'no_lineal' (Etapa A) o 'lineal'
cfg.actuador_tipo = 'medido';   % 'medido' (tabla del prototipo), 'medido_ik_lineal' o 'diseno'
cfg.actuador_ideal = false;     % true: sin saturaciones ni limite de velocidad
                                %       (el plato sigue la dinamica del servo sin limites)
cfg.saturar = true;             % saturacion de th_cmd en el controlador (+-C.th_lim)
cfg.usar_aw = true;             % clamping del integrador
cfg.omega_n_servo = 50;         % [rad/s] dinamica del servo, 2o orden critico. SUPUESTO
                                % (la hoja de datos solo da la velocidad maxima)
cfg.retardo = P.retardo;        % retardo total [s]; la parte de medicion es retardo - T_pwm/2
cfg.sigma_ruido = 1.0;          % ruido de la camara [mm] (marcador de config.py, PENDIENTE medir)
cfg.semilla = 1;                % semilla del ruido (misma en todos los casos)
cfg.x0 = [0; 0];                % posicion inicial de la bola [mm]
cfg.v0 = [0; 0];                % velocidad inicial de la bola [mm/s] (empujon)
cfg.t_espera = 0.5;             % [s] controlador apagado (plato horizontal) al inicio;
                                %     el Kalman ya corre. El ensayo empieza en t_espera.
cfg.r  = @(t) [0; 0];           % referencia [mm] en funcion del tiempo
cfg.th_dist = [0; 0];           % desnivel del plato [rad] (perturbacion de entrada)
cfg.T_fin = 6;                  % [s]
cfg.N_sub = 33;                 % pasos de integracion por periodo de muestreo (dt = Ts/33)
cfg.kalman_sigma_a = 1500;      % PROCESS_ACCEL_STD de config.py [mm/s^2]
cfg.kalman_sigma_m = 1.0;       % MEAS_NOISE_STD_MM de config.py [mm]
end
