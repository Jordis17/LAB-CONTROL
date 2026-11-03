function S = bop_lazo_lineal(P, L, C, tau, w)
%BOP_LAZO_LINEAL Lazo lineal discreto de un eje: respuesta en frecuencia,
% margenes y polos de lazo cerrado.
%
%   S = bop_lazo_lineal(P, L, C, tau, w)
%
%   P, L   parametros y modelo lineal de la Etapa A
%   C      controlador (Kp, Ki, Kd, Ts, Kf = ganancia del Kalman)
%   tau    retardo total del lazo [s] (> 0)
%   w      frecuencias [rad/s] (opcional)
%
% Cadena (todo a Ts):  th -> planta ZOH con retardo -> Xm -> Kalman
%   -> (x_hat, v_hat) -> controlador lineal (sin saturacion ni recorte)
%   th = Kp*x_hat + Ki*Ts/(z-1)*x_hat + Kd*v_hat
% Ganancia de lazo (abierto en la entrada de la planta, realimentacion
% negativa): Lz = -Pz*Cz, porque la planta tiene ganancia negativa y el
% controlador ganancias positivas.

if nargin < 5 || isempty(w)
    w = logspace(-1, log10(0.999*pi/C.Ts), 4000);
end
Ts = C.Ts;
Dm = bop_discretizar(L.A, L.B, L.C(2,:), L.D(2), Ts, tau);
F  = [1 Ts; 0 1];  H = [1 0];
Af = (eye(2) - C.Kf*H)*F;            % x_hat[k] = Af*x_hat[k-1] + Kf*y[k]
n  = size(Dm.A,1);

Lz = zeros(size(w));  Pz = Lz;  Cz = Lz;
for i = 1:numel(w)
    z = exp(1j*w(i)*Ts);
    Pz(i) = Dm.C*((z*eye(n) - Dm.A)\Dm.B) + Dm.D;
    X = (eye(2) - Af/z)\C.Kf;        % [x_hat; v_hat] / y
    Cz(i) = C.Kp*X(1) + C.Ki*Ts/(z - 1)*X(1) + C.Kd*X(2);
    Lz(i) = -Pz(i)*Cz(i);
end
S.w = w(:);  S.L = Lz(:);  S.P = Pz(:);  S.C = Cz(:);
S.mag_dB = 20*log10(abs(S.L));
S.fase_deg = rad2deg(unwrap(angle(S.L)));

% Cruce de ganancia (el de mayor frecuencia) y margen de fase
m = abs(S.L);
ic = find(diff(sign(m - 1)) ~= 0);
if isempty(ic)
    S.wc = NaN;  S.PM = NaN;
else
    k = ic(end);
    S.wc = interp1(log(m(k:k+1)), w(k:k+1), 0);
    Lc = interp1(w(k:k+1), S.L(k:k+1), S.wc);
    S.PM = mod(rad2deg(angle(Lc)) + 180 + 180, 360) - 180;
end
S.margen_retardo = deg2rad(S.PM)/S.wc;          % [s] retardo adicional tolerable

% Cruces de fase (-180): Im(L) cambia de signo con Re(L) < 0
ip = find(diff(sign(imag(S.L))) ~= 0 & real(S.L(1:end-1)) < 0);
S.GM_sup_dB = Inf;  S.GM_inf_dB = -Inf;  S.w180 = [];
for k = ip(:)'
    wk = interp1(imag(S.L(k:k+1)), w(k:k+1), 0);
    Lk = interp1(w(k:k+1), S.L(k:k+1), wk);
    S.w180(end+1) = wk;
    g = -20*log10(abs(Lk));
    if wk > S.wc
        S.GM_sup_dB = min(S.GM_sup_dB, g);      % cuanto puede SUBIR la ganancia
    else
        S.GM_inf_dB = max(S.GM_inf_dB, g);      % cuanto puede BAJAR (valor negativo)
    end
end

% Polos de lazo cerrado (estado: planta aumentada, x_hat anterior, integrador)
Kc = [C.Kp C.Kd];
Acl = [Dm.A + Dm.B*Kc*C.Kf*Dm.C,        Dm.B*Kc*Af,        Dm.B;
       C.Kf*Dm.C,                         Af,                zeros(2,1);
       C.Ki*Ts*[1 0]*C.Kf*Dm.C,           C.Ki*Ts*[1 0]*Af,  1];
S.polos_lc = eig(Acl);
S.radio_max = max(abs(S.polos_lc));
S.estable = S.radio_max < 1;
end
