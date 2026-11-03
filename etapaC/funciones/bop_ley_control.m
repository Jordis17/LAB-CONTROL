function [th_cmd, I_n, nq_n, u, saturado, integra] = bop_ley_control(x_hat, v_hat, r, I, nq, ...
    Kp, Ki, Kd, Ts, th_lim, e_clip, v_int, Nq, usar_aw, saturar)
%BOP_LEY_CONTROL Ley de control de UN eje, un paso (escalares, apta para codigo).
%
%   [th_cmd, I_n, nq_n, u, saturado, integra] = bop_ley_control(x_hat, v_hat, r, I, nq, ...
%       Kp, Ki, Kd, Ts, th_lim, e_clip, v_int, Nq, usar_aw, saturar)
%
% UNICA FUENTE del algoritmo. La usan:
%   - el MIL (etapaD, a traves de bop_controlador_paso), y
%   - el bloque MATLAB Function de Controller_BoP.slx (etapaE): el script
%     E0_build_Controller_BoP copia este archivo dentro del bloque.
% Si se cambia aqui, hay que reconstruir el modelo y repetir E1 (equivalencia).
%
% Entradas:  x_hat [mm], v_hat [mm/s], r [mm], I [rad], nq [cuadros]
% Parametros: Kp [rad/mm], Ki [rad/(mm s)], Kd [rad/(mm/s)], Ts [s],
%             th_lim [rad], e_clip [mm], v_int [mm/s], Nq [cuadros]
%             usar_aw, saturar: logicos (en el modelo del controlador, true)
% Salidas:   th_cmd [rad], I_n y nq_n (estado del paso siguiente),
%            u [rad] (sin saturar), saturado, integra (logicos)
%
% Ley (eps = x_hat - r, ganancias positivas: th > 0 acelera la bola hacia -x):
%   u      = Kp*eps + I + Kd*v_hat
%   th_cmd = sat(u, +-th_lim)
%   nq_n   = nq + 1 si |v_hat| < v_int, si no 0
%   I_n    = I + Ki*Ts*sat(eps, +-e_clip)  si nq_n >= max(Nq,1) y no
%            (usar_aw y saturado y sign(eps) == sign(u));  si no, I_n = I
%#codegen

eps_ = x_hat - r;
u = Kp*eps_ + I + Kd*v_hat;
if saturar
    th_cmd = min(max(u, -th_lim), th_lim);
else
    th_cmd = u;
end
saturado = (th_cmd ~= u);
congelar = usar_aw && saturado && (sign(eps_) == sign(u));

if abs(v_hat) < v_int
    nq_n = nq + 1;
else
    nq_n = 0;
end
integra = ~congelar && (nq_n >= max(Nq, 1));
if integra
    I_n = I + Ki*Ts*min(max(eps_, -e_clip), e_clip);
else
    I_n = I;
end
end
