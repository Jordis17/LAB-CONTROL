function [th, dth, d2th] = bop_fk_plano(phi, P)
%BOP_FK_PLANO Cinematica directa de UN eje (forma cerrada) y sus derivadas.
%
%   [th, dth, d2th] = bop_fk_plano(phi, P)
%
%   phi  angulo del servo [rad] (escalar o vector)
%   th   inclinacion del plato [rad]
%   dth  = dth/dphi, d2th = d2th/dphi2 (diferencias centrales)
%
% Mecanismo plano de cuatro barras (mismo de bop_cinematica_inversa en modo
% 'plano'): rotula en (d, z_rot) del plato, eje del servo en
% (d - sigma*r, -H_serv), varilla L_var. Rama que da th = 0 en phi = 0.

th = fk(phi, P);
if nargout > 1
    h = 1e-4;
    tp = fk(phi + h, P);  tm = fk(phi - h, P);
    dth  = (tp - tm)/(2*h);
    d2th = (tp - 2*th + tm)/h^2;
end
end

function th = fk(phi, P)
s = P.sigma_brazo;  r = P.r_brazo;
Ax = P.d - s*r + s*r*cos(phi);
Az = -P.H_serv + r*sin(phi);
rho  = hypot(P.d, P.z_rot);
beta = atan2(P.z_rot, P.d);
nA   = hypot(Ax, Az);
gam  = atan2(Az, Ax);
th = gam + acos((rho^2 + nA.^2 - P.L_var^2)./(2*rho*nA)) - beta;
end
