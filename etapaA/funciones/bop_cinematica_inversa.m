function phi = bop_cinematica_inversa(th, P, modo)
%BOP_CINEMATICA_INVERSA Angulos de servo para una inclinacion del plato.
%
%   phi = bop_cinematica_inversa(th, P)            modo '3D' (exacto)
%   phi = bop_cinematica_inversa(th, P, 'plano')   cada eje por separado
%
%   th  = [thx; thy] inclinacion del plato [rad]
%   phi = [phix; phiy] angulo de cada servo [rad]; 0 = brazo horizontal,
%         positivo levanta la punta del brazo (y el lado correspondiente del plato).
%
% Geometria (marco fijo, origen en el centro de la junta, z hacia arriba):
%   rotula X en (d, 0, z_rot) del plato; rotula Y en (0, d, z_rot) del plato.
%   eje del servo X en (d - sigma*r, 0, -H_serv), brazo en el plano XZ.
%   eje del servo Y en (0, d - sigma*r, -H_serv), brazo en el plano YZ.
%   varilla rigida de largo L_var entre la punta del brazo y la rotula.
% En modo '3D' la rotula de un eje se mueve fuera del plano del otro servo
% cuando el plato se inclina en los dos ejes; el modo 'plano' lo ignora
% (es lo que haria un firmware que trata cada eje por separado).
%
% NaN si la inclinacion pedida no es alcanzable con el mecanismo.

if nargin < 3
    modo = '3D';
end

ax = th(1);  ay = th(2);
if strcmpi(modo,'plano')
    Rx_ = rot(ax, 0);
    Ry_ = rot(0, ay);
else
    Rx_ = rot(ax, ay);
    Ry_ = Rx_;
end

PX = Rx_*[P.d; 0; P.z_rot];      % rotula X en el marco fijo
PY = Ry_*[0; P.d; P.z_rot];      % rotula Y en el marco fijo

s = P.sigma_brazo;  r = P.r_brazo;  L = P.L_var;

% Servo X: el brazo se mueve en el plano XZ (coordenada "en el plano" = x).
SX = [P.d - s*r; 0; -P.H_serv];
DX = PX - SX;
phix = resolver(s*DX(1), DX(3), DX'*DX, r, L);

% Servo Y: plano YZ (coordenada "en el plano" = y).
SY = [0; P.d - s*r; -P.H_serv];
DY = PY - SY;
phiy = resolver(s*DY(2), DY(3), DY'*DY, r, L);

phi = [phix; phiy];
end

function R = rot(ax, ay)
R = [1 0 0; 0 cos(ay) -sin(ay); 0 sin(ay) cos(ay)] * ...
    [cos(-ax) 0 sin(-ax); 0 1 0; -sin(-ax) 0 cos(-ax)];
end

function phi = resolver(Din, Dz, D2, r, L)
% |D - r*(s*cos(phi) e_in + sin(phi) e_z)|^2 = L^2
%   => Din*cos(phi) + Dz*sin(phi) = (|D|^2 + r^2 - L^2)/(2 r)
K  = (D2 + r^2 - L^2)/(2*r);
R0 = hypot(Din, Dz);
if abs(K) > R0
    phi = NaN;
    return
end
alfa = atan2(Dz, Din);
phi  = alfa - acos(K/R0);       % rama que da phi = 0 en el neutro
end
