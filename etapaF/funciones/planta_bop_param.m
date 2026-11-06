function Pp = planta_bop_param()
%PLANTA_BOP_PARAM Parametros de la planta del banco SIL/PIL.
% ARCHIVO GENERADO por planta_bop_param_escribir (2026-11-06 10:35). No editar a mano.
%#codegen
P.g = 9810;
P.c_rod = 0.7142857142857143;
P.k_inercia = 0.39999999999999991;
P.r_bola = 20;
P.h = 69;
P.h_sup = 49;
P.H_cam = 450;
Pp.P = P;
Pp.Ts = 0.033333333333333333;          % periodo [s]
Pp.N = 33;              % subpasos de integracion por periodo
Pp.wn = 50;          % servo, 2o orden critico [rad/s] (supuesto, igual que el MIL)
Pp.w_max = 3.4906585039886591;       % velocidad maxima del plato [rad/s] (200 deg/s)
Pp.th_max = 0.19722220547535926;      % inclinacion maxima del plato [rad] (11,3 deg, tabla medida)
Pp.nd = 1;              % retardo de medicion [cuadros] (+1 cuadro del Unit Delay del banco)
Pp.sigma = 1;           % ruido de la camara [mm]
Pp.kal_sa = 500;      % Kalman sigma_a [mm/s^2]
Pp.kal_sm = 1;      % Kalman sigma_m [mm]
Pp.x0 = [80; -60];      % posicion inicial de la bola [mm] (como el ensayo D4)
Pp.semilla = 12345;
end
