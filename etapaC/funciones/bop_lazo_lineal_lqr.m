function S = bop_lazo_lineal_lqr(P, L, C, tau, w)
%BOP_LAZO_LINEAL_LQR Lazo lineal discreto de un eje con el LQR: margenes y polos.
%
%   S = bop_lazo_lineal_lqr(P, L, C, tau, w)
%
% Misma cadena que bop_lazo_lineal (para comparar con el PID en igualdad de
% condiciones): th -> planta de la Etapa A (con sus ceros) ZOH con retardo tau
% -> Xm -> Kalman -> (x_hat, v_hat) -> LQR lineal (sin saturacion).
%   u[k] = -(Ke x_hat + Kv v_hat + sum Ku_i u[k-d+i-1] + Kz z),  z = Ts/(z-1) x_hat
% Ganancia de lazo abierta en la entrada de la planta: Lz = -Pz*Cyu.

if nargin < 5 || isempty(w)
    w = logspace(-1, log10(0.999*pi/C.Ts), 4000);
end
Ts = C.Ts;  K = C.K(:)';  d = C.d;
Ke = K(1);  Kv = K(2);  Ku = K(3:2+d);  Kz = K(end);
Dm = bop_discretizar(L.A, L.B, L.C(2,:), L.D(2), Ts, tau);
F  = [1 Ts; 0 1];  H = [1 0];
Af = (eye(2) - C.Kf*H)*F;
n  = size(Dm.A,1);

Lz = zeros(size(w));  Pz = Lz;  Cz = Lz;
for i = 1:numel(w)
    zz = exp(1j*w(i)*Ts);
    Pz(i) = Dm.C*((zz*eye(n) - Dm.A)\Dm.B) + Dm.D;
    X = (eye(2) - Af/zz)\C.Kf;               % [x_hat; v_hat]/y
    den = 1;
    for j = 1:d
        den = den + Ku(j)*zz^(-(d - j + 1));  % Ku(j) multiplica a u[k-d+j-1]
    end
    Cz(i) = -(Ke*X(1) + Kv*X(2) + Kz*Ts/(zz - 1)*X(1))/den;   % u/y
    Lz(i) = -Pz(i)*Cz(i);
end
S.w = w(:);  S.L = Lz(:);  S.P = Pz(:);  S.C = Cz(:);
S.mag_dB = 20*log10(abs(S.L));
S.fase_deg = rad2deg(unwrap(angle(S.L)));

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
S.margen_retardo = deg2rad(S.PM)/S.wc;
ip = find(diff(sign(imag(S.L))) ~= 0 & real(S.L(1:end-1)) < 0);
S.GM_sup_dB = Inf;  S.GM_inf_dB = -Inf;  S.w180 = [];
for k = ip(:)'
    wk = interp1(imag(S.L(k:k+1)), w(k:k+1), 0);
    Lk = interp1(w(k:k+1), S.L(k:k+1), wk);
    S.w180(end+1) = wk;
    g = -20*log10(abs(Lk));
    if wk > S.wc
        S.GM_sup_dB = min(S.GM_sup_dB, g);
    else
        S.GM_inf_dB = max(S.GM_inf_dB, g);
    end
end

% Polos de lazo cerrado. Estado: [xp; x_hat[k-1]; u[k-d..k-1]; z]
Ap = Dm.A;  Bp = Dm.B;  Cp = Dm.C;
Kxv = [Ke Kv];
% u[k] = -Kxv*(Af*h + Kf*Cp*xp) - Ku*ub - Kz*z
Uxp = -Kxv*C.Kf*Cp;  Uh = -Kxv*Af;  Uub = -Ku;  Uz = -Kz;
N = n + 2 + d + 1;
Acl = zeros(N);
ip_ = 1:n;  ih = n+(1:2);  iu = n+2+(1:d);  iz = N;
Acl(ip_,ip_) = Ap + Bp*Uxp;  Acl(ip_,ih) = Bp*Uh;  Acl(ip_,iu) = Bp*Uub;  Acl(ip_,iz) = Bp*Uz;
Acl(ih,ip_) = C.Kf*Cp;       Acl(ih,ih) = Af;                         % x_hat[k]
if d > 0
    Acl(iu(1:end-1), iu(2:end)) = eye(d-1);                           % desplazamiento
    Acl(iu(end), ip_) = Uxp;  Acl(iu(end), ih) = Uh;  Acl(iu(end), iu) = Uub;  Acl(iu(end), iz) = Uz;
end
Acl(iz,ip_) = Ts*[1 0]*C.Kf*Cp;  Acl(iz,ih) = Ts*[1 0]*Af;  Acl(iz,iz) = 1;
S.Acl = Acl;                                    % para simular el lazo lineal
S.idx = struct('planta',ip_,'xhat',ih,'ub',iu,'z',iz);
S.Cy = [Cp zeros(1, N - n)];                      % salida Xm
S.polos_lc = eig(Acl);
S.radio_max = max(abs(S.polos_lc));
S.estable = S.radio_max < 1;
end
