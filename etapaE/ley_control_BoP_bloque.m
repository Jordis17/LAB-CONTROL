function [th_cmd, I_est, saturado] = ley_control_BoP_bloque(r, x_hat, v_hat, habilitado, ...
    Kp, Ki, Kd, Ts, th_lim, e_clip, v_int, Nq)
%LEY_CONTROL_BOP_BLOQUE Funcion principal del bloque MATLAB Function de Controller_BoP.slx.
%
% E0_build_Controller_BoP copia este archivo, seguido de bop_ley_control.m,
% dentro del bloque "ley_control". El modelo queda autocontenido: no depende
% de archivos externos despues de construido.
%
% Un eje. Se llama una vez por cuadro de camara (Ts).
%   r [mm], x_hat [mm], v_hat [mm/s]   referencia y estado del Kalman
%   habilitado (logico)                false: plato horizontal (th_cmd = 0) y
%                                      estado interno en cero (arranque, sin
%                                      bola, perdida de comunicacion)
%   Kp ... Nq                          parametros calibrables (init_Controller_BoP)
%   th_cmd [rad]                       inclinacion pedida al plato
%   I_est [rad]                        integrador (para registro y verificacion)
%   saturado (logico)                  th_cmd saturado en este paso
% Estado interno (persistente): I [rad], nq [cuadros con la bola quieta].
%#codegen

persistent I nq
if isempty(I)
    I = 0;
    nq = 0;
end
if habilitado
    [th_cmd, I, nq, ~, saturado, ~] = bop_ley_control(x_hat, v_hat, r, I, nq, ...
        Kp, Ki, Kd, Ts, th_lim, e_clip, v_int, Nq, true, true);
else
    th_cmd = 0;
    I = 0;
    nq = 0;
    saturado = false;
end
I_est = I;
end
