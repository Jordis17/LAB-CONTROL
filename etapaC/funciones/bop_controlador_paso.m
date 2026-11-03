function [th_cmd, E, info] = bop_controlador_paso(x_hat, v_hat, r, E, C, usar_aw, saturar)
%BOP_CONTROLADOR_PASO Un paso del controlador de UN eje (envoltorio de bop_ley_control).
%
%   [th_cmd, E, info] = bop_controlador_paso(x_hat, v_hat, r, E, C)
%   [...] = bop_controlador_paso(..., usar_aw, saturar)
%
%   x_hat [mm], v_hat [mm/s]  posicion y velocidad del Kalman
%   r     [mm]                referencia
%   E                         estado: E.I [rad] integrador, E.nq cuadros con la
%                             bola quieta (inicial: bop_controlador_estado0)
%   C                         controlador (etapaC/resultados/C1_controlador.mat)
%   usar_aw (true)            proteccion del integrador por clamping
%   saturar (true)            limitar th_cmd a +-C.th_lim
%
% El algoritmo esta en bop_ley_control.m (unica fuente, ver ahi la ley).
% Integracion condicional: el integrador solo trabaja cuando la bola lleva al
% menos Nq cuadros con |v_hat| < v_int. Con C.v_int = Inf y C.e_clip = Inf
% es un PID clasico.

if nargin < 6, usar_aw = true; end
if nargin < 7, saturar = true; end

[th_cmd, E.I, E.nq, u, saturado, integra] = bop_ley_control(x_hat, v_hat, r, E.I, E.nq, ...
    C.Kp, C.Ki, C.Kd, C.Ts, C.th_lim, C.e_clip, C.v_int, C.Nq, usar_aw, saturar);
info.u = u;  info.saturado = saturado;  info.integra = integra;
info.congelado = usar_aw && saturado && (sign(x_hat - r) == sign(u));
end
