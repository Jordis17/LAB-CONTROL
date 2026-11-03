function L = bop_modelo_lineal(P)
%BOP_MODELO_LINEAL Modelo lineal de UN eje alrededor de x = 0, th = 0, thd = 0.
%
%   L = bop_modelo_lineal(P)
%
% Linealizando bop_aceleracion y bop_medicion (ver LEEME_etapaA.md):
%
%   xdd = c*( -g*th + h_ef*thdd ),     h_ef = h + k*r_b
%   Xm  = x - h*th                      (lo que mide la camara)
%
% El termino en thdd impide escribir el modelo con th como entrada y
% (x, xd) como estados sin derivar la entrada. Se usa el cambio de variable
%
%   xi = x - c*h_ef*th    =>    xi_dd = -c*g*th
%
% y queda un doble integrador con transmision directa:
%
%   d/dt [xi; xid] = [0 1; 0 0]*[xi; xid] + [0; -c*g]*th
%   x  = xi + c*h_ef*th
%   Xm = xi + (c*h_ef - h)*th = xi - (1-c)*h_sup*th
%
% Funciones de transferencia:
%   X(s)/TH(s)  = ( c*h_ef*s^2 - c*g ) / s^2
%   Xm(s)/TH(s) = ( -(1-c)*h_sup*s^2 - c*g ) / s^2
%
% Unidades: th [rad], x y Xm [mm].

c = P.c_rod;  g = P.g;
L.h_ef = P.h + P.k_inercia*P.r_bola;      % [mm]
L.Kg   = c*g;                             % [mm/(s^2 rad)]
L.Dx   = c*L.h_ef;                        % [mm/rad]
L.Dm   = c*L.h_ef - P.h;                  % [mm/rad] (= -(1-c)*h_sup)

L.A = [0 1; 0 0];
L.B = [0; -L.Kg];
L.C = [1 0; 1 0];                         % filas: x, Xm
L.D = [L.Dx; L.Dm];
L.salidas = {'x_mm','Xm_mm'};
L.estados = {'xi_mm','xid_mm_s'};
L.entrada = 'th_rad';

% Numerador y denominador en potencias decrecientes de s.
L.num_x  = [L.Dx 0 -L.Kg];
L.num_Xm = [L.Dm 0 -L.Kg];
L.den    = [1 0 0];

% Ceros (analiticos).
L.ceros_x  = raices2(L.Dx, -L.Kg);
L.ceros_Xm = raices2(L.Dm, -L.Kg);
L.polos    = [0; 0];
end

function z = raices2(a, b)
% raices de a*s^2 + b = 0
if a == 0
    z = zeros(0,1);
else
    z = sqrt(complex(-b/a))*[1; -1];
end
end
