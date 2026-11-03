function [th_cmd, E, info] = bop_controlador_paso(x_hat, v_hat, r, E, C, usar_aw, saturar)
%BOP_CONTROLADOR_PASO Un paso del controlador de UN eje (ley discreta).
%
%   [th_cmd, E, info] = bop_controlador_paso(x_hat, v_hat, r, E, C)
%   [...] = bop_controlador_paso(..., usar_aw, saturar)
%
% Entradas (por cuadro de camara, cada Ts):
%   x_hat [mm], v_hat [mm/s]  posicion y velocidad del Kalman
%   r     [mm]                referencia
%   E                         estado interno: E.I [rad] integrador,
%                             E.nq [-] cuadros seguidos con la bola quieta
%                             (inicial: bop_controlador_estado0)
%   C                         controlador (etapaC/resultados/C1_controlador.mat)
%   usar_aw (true)            proteccion del integrador por clamping
%   saturar (true)            limitar th_cmd a +-C.th_lim
% Salida:
%   th_cmd [rad]  inclinacion pedida al plato (entra a la cinematica inversa)
%   E             estado para el paso siguiente
%
% Ley (eps = x_hat - r: "inclinar hacia donde esta la bola", ganancias > 0):
%   u      = Kp*eps + I + Kd*v_hat
%   th_cmd = sat(u, +-th_lim)
%   nq     = nq + 1 si |v_hat| < v_int, si no nq = 0
%   I     <- I + Ki*Ts*sat(eps, +-e_clip)   solo si nq >= max(Nq, 1)
%
% Integracion condicional: el integrador solo trabaja cuando la bola lleva
% al menos Nq cuadros casi quieta (|v_hat| < v_int). Entonces el error que
% queda es un sesgo (desnivel del plato, neutro del servo, bola desbalanceada)
% y no un transitorio. Con C.v_int = Inf y C.e_clip = Inf es un PID clasico.
% Clamping: si th_cmd esta saturado y eps empuja en el mismo sentido que u,
% el integrador no se actualiza.
% El signo sale de la planta: th > 0 acelera la bola hacia -x (Etapa A).

if nargin < 6, usar_aw = true; end
if nargin < 7, saturar = true; end

eps_ = x_hat - r;
u = C.Kp*eps_ + E.I + C.Kd*v_hat;
if saturar
    th_cmd = min(max(u, -C.th_lim), C.th_lim);
else
    th_cmd = u;
end
saturado = (th_cmd ~= u);
congelar = usar_aw && saturado && (sign(eps_) == sign(u));

if abs(v_hat) < C.v_int
    E.nq = E.nq + 1;
else
    E.nq = 0;
end
integra = ~congelar && (E.nq >= max(C.Nq, 1));
if integra
    E.I = E.I + C.Ki*C.Ts*min(max(eps_, -C.e_clip), C.e_clip);
end
info.u = u;  info.saturado = saturado;  info.congelado = congelar;  info.integra = integra;
end
