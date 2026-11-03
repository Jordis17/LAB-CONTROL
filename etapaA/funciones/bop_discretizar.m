function Dm = bop_discretizar(A, B, C, D, Ts, tau)
%BOP_DISCRETIZAR Discretizacion ZOH exacta con retardo de entrada tau >= 0.
%
%   Dm = bop_discretizar(A, B, C, D, Ts, tau)
%
% Sistema continuo  xdot = A x + B u(t - tau),  y = C x + D u(t - tau),
% con u constante por tramos de largo Ts (ZOH). Una sola entrada.
%
% Con tau = (d-1)*Ts + tau1, 0 < tau1 <= Ts (Astrom y Wittenmark):
%   x[k+1] = Phi x[k] + G1 u[k-d] + G0 u[k-d+1]
%   y[k]   = C x[k] + D u[k-d]
% El estado aumentado guarda las d entradas pasadas:
%   z = [x; u[k-d]; u[k-d+1]; ... ; u[k-1]].
% Con tau = 0 no se agregan estados.
%
% No usa Control System Toolbox (asi corre igual en cualquier instalacion).

n = size(A,1);

expAB = @(t) expm([A B; zeros(1,n+1)]*t);   % [e^{At}, int_0^t e^{As} ds B]

M = expAB(Ts);
Phi = M(1:n,1:n);

if tau <= 0
    Dm.A = Phi;  Dm.B = M(1:n,n+1);  Dm.C = C;  Dm.D = D;
    Dm.d = 0;  Dm.tau1 = 0;  Dm.Ts = Ts;  Dm.tau = 0;
    return
end

d = ceil(tau/Ts - 1e-12);
tau1 = tau - (d-1)*Ts;                      % 0 < tau1 <= Ts

M0 = expAB(Ts - tau1);
G0 = M0(1:n,n+1);                           % int_0^{Ts-tau1} e^{As} ds B
M1 = expAB(tau1);
G1 = M0(1:n,1:n)*M1(1:n,n+1);               % e^{A(Ts-tau1)} int_0^{tau1} e^{As} ds B

ny = size(C,1);
N = n + d;
Ad = zeros(N);  Bd = zeros(N,1);
Ad(1:n,1:n) = Phi;
Ad(1:n,n+1) = G1;                           % u[k-d]
if d >= 2
    Ad(1:n,n+2) = G0;                       % u[k-d+1]
else
    Bd(1:n) = G0;                           % con d = 1, u[k-d+1] = u[k]
end
% registro de desplazamiento de las entradas pasadas
for i = 1:d-1
    Ad(n+i, n+i+1) = 1;
end
Bd(n+d) = 1;                                % la ultima posicion recibe u[k]

Cd = zeros(ny,N);
Cd(:,1:n) = C;
Cd(:,n+1) = D;                              % y[k] usa u[k-d]
Dd = zeros(ny,1);

Dm.A = Ad;  Dm.B = Bd;  Dm.C = Cd;  Dm.D = Dd;
Dm.d = d;  Dm.tau1 = tau1;  Dm.Ts = Ts;  Dm.tau = tau;
end
