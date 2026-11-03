function init_Controller_BoP()
%INIT_CONTROLLER_BOP Parametros de Controller_BoP.slx en el workspace base.
%
% Lo llama el InitFcn del modelo y los scripts E0 a E2. Lee el controlador
% disenado en la Etapa C (etapaC/resultados/C1_controlador.mat) y crea:
%   Ts_ctrl                      periodo de muestreo del modelo [s] (double)
%   BoP_Kp, BoP_Ki, BoP_Kd,      Simulink.Parameter, double, ExportedGlobal:
%   BoP_Ts, BoP_th_lim,          quedan como variables globales calibrables en
%   BoP_e_clip, BoP_v_int,       el codigo generado (las comparten los dos ejes)
%   BoP_Nq
% No cambia ningun valor: si hay que cambiar el controlador, se cambia en la
% Etapa C y se vuelve a correr C1.

carpeta = fileparts(mfilename('fullpath'));
archivoC = fullfile(fileparts(carpeta), 'etapaC', 'resultados', 'C1_controlador.mat');
if ~isfile(archivoC)
    error('init_Controller_BoP:SinControlador', ...
        'Falta %s. Corra primero etapaC/C1_disenar_controlador_BoP.', archivoC);
end
S = load(archivoC, 'Ctrl');
C = S.Ctrl;

def = { 'BoP_Kp',     C.Kp,     'Ganancia proporcional [rad/mm]';
        'BoP_Ki',     C.Ki,     'Ganancia integral continua [rad/(mm s)]';
        'BoP_Kd',     C.Kd,     'Ganancia derivativa, sobre v_hat del Kalman [rad/(mm/s)]';
        'BoP_Ts',     C.Ts,     'Periodo usado en la integral [s]';
        'BoP_th_lim', C.th_lim, 'Saturacion de la inclinacion pedida [rad]';
        'BoP_e_clip', C.e_clip, 'Recorte del error que entra al integrador [mm]';
        'BoP_v_int',  C.v_int,  'Umbral de bola quieta [mm/s]';
        'BoP_Nq',     C.Nq,     'Cuadros seguidos con la bola quieta para integrar [-]' };
for i = 1:size(def,1)
    v = def{i,2};
    if ~isscalar(v) || ~isfinite(v)
        error('init_Controller_BoP:Valor', '%s debe ser un escalar finito.', def{i,1});
    end
    p = Simulink.Parameter;
    p.Value = double(v);
    p.DataType = 'double';
    p.CoderInfo.StorageClass = 'ExportedGlobal';
    p.Description = def{i,3};
    assignin('base', def{i,1}, p);
end
assignin('base', 'Ts_ctrl', double(C.Ts));
end
