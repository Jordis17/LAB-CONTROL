function [y, S] = planta_bop_paso(th_cmd, S, Pp)
%PLANTA_BOP_PASO Un periodo Ts de la planta del banco SIL/PIL (dos ejes).
%
%   [y, S] = planta_bop_paso(th_cmd, S, Pp)
%
%   th_cmd [rad] (2x1)  inclinacion pedida (ya retrasada un cuadro afuera)
%   y (6x1)             [x_hat_x; v_hat_x; x_hat_y; v_hat_y; x_plato_x; x_plato_y]
%
% Cadena, en este orden:
%   1. camara: mide el estado actual (bop_medicion, Etapa A) + ruido gaussiano
%      con un generador congruencial propio (la misma secuencia en cada rama);
%   2. la medicion entra a una cola de nd cuadros (retardo de medicion);
%   3. Kalman por eje (igual a kalman.py) con la medicion retrasada -> salida;
%   4. integracion de Ts en N subpasos: servo de 2o orden sobre el angulo del
%      plato con limite de velocidad y de inclinacion, y bola no lineal de dos
%      ejes (bop_aceleracion, Etapa A).
%
% Simplificaciones respecto del MIL (etapaD): el actuador es directamente el
% angulo del plato (sin la tabla servo-plato ni el PWM de 20 ms) y el retardo
% es un numero entero de cuadros. Para SIL/PIL alcanza: lo que se compara es
% el controlador de las dos ramas con la MISMA planta.
%#codegen

P = Pp.P;
% 1-2. medicion con ruido y cola de retardo
ym = bop_medicion(S.q, S.th, P);
[n1, S.semilla] = normal_lcg(S.semilla);
[n2, S.semilla] = normal_lcg(S.semilla);
ym = ym + Pp.sigma*[n1; n2];
yd = S.buf(:,1);
S.buf = [S.buf(:,2:end) ym];

% 3. Kalman
F = [1 Pp.Ts; 0 1];  H = [1 0];
Q = Pp.kal_sa^2*[Pp.Ts^4/4 Pp.Ts^3/2; Pp.Ts^3/2 Pp.Ts^2];
R = Pp.kal_sm^2;
for e = 1:2
    if ~S.kini
        S.kx(:,e) = [yd(e); 0];
        S.kP(:,:,e) = [R 0; 0 1e4];
    else
        S.kx(:,e) = F*S.kx(:,e);
        S.kP(:,:,e) = F*S.kP(:,:,e)*F' + Q;
    end
    K = S.kP(:,:,e)*H'/(H*S.kP(:,:,e)*H' + R);
    S.kx(:,e) = S.kx(:,e) + K*(yd(e) - H*S.kx(:,e));
    S.kP(:,:,e) = (eye(2) - K*H)*S.kP(:,:,e);
end
S.kini = true;
y = [S.kx(1,1); S.kx(2,1); S.kx(1,2); S.kx(2,2); S.q(1); S.q(2)];

% 4. integracion (Euler semi-implicito, dt = Ts/N)
dt = Pp.Ts/Pp.N;
obj = min(max(th_cmd(:), -Pp.th_max), Pp.th_max);
for i = 1:Pp.N
    thdd = Pp.wn^2*(obj - S.th) - 2*Pp.wn*S.thd;
    S.thd = min(max(S.thd + thdd*dt, -Pp.w_max), Pp.w_max);
    S.th = min(max(S.th + S.thd*dt, -Pp.th_max), Pp.th_max);
    qdd = bop_aceleracion(S.q, S.qd, S.th, S.thd, thdd, P);
    S.qd = S.qd + qdd*dt;
    S.q = S.q + S.qd*dt;
end
end

function [n, s] = normal_lcg(s)
% Normal(0,1) por Box-Muller con un generador congruencial (exacto en double).
s = mod(1664525*s + 1013904223, 4294967296);  u1 = (s + 0.5)/4294967296;
s = mod(1664525*s + 1013904223, 4294967296);  u2 = (s + 0.5)/4294967296;
n = sqrt(-2*log(u1))*cos(2*pi*u2);
end
