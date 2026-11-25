function M = bop_modelo_lqr(P, tau_d)
%BOP_MODELO_LQR Modelo discreto de diseno del LQR para UN eje.
%
%   M = bop_modelo_lqr(P, tau_d)
%
% Planta de diseno: doble integrador xdd = -c*g*th (sin los ceros de la Etapa A,
% igual que el diseno del PID), con un retardo de entrada tau_d que representa
% el retardo del lazo y el atraso del servo. Discretizacion ZOH exacta con
% retardo fraccionario (bop_discretizar, Astrom y Wittenmark).
%
% Estado aumentado (n = 2 + d + 1):
%   s = [ e ; v ; u[k-d] ; ... ; u[k-1] ; z ]
%   e = x - r [mm], v [mm/s], u [rad] entradas ya enviadas (las conoce el
%   controlador), z [mm s] integral del error:  z[k+1] = z[k] + Ts*e[k].
% Con referencia constante, e cumple la misma dinamica que x.

c = P.c_rod;  g = P.g;  Ts = P.Ts;
Dm = bop_discretizar([0 1; 0 0], [0; -c*g], [1 0], 0, Ts, tau_d);
n = size(Dm.A,1);                       % 2 + d
A = zeros(n+1);  B = zeros(n+1,1);
A(1:n,1:n) = Dm.A;  B(1:n) = Dm.B;
A(n+1,1) = Ts;  A(n+1,n+1) = 1;         % integrador del error
M.A = A;  M.B = B;  M.d = Dm.d;  M.n = n + 1;  M.tau_d = tau_d;  M.Ts = Ts;
M.estados = [{'e_mm','v_mm_s'}, arrayfun(@(i) sprintf('u_k-%d_rad', Dm.d - i + 1), 1:Dm.d, 'UniformOutput', false), {'z_mm_s'}];
end
