function qdd = bop_aceleracion(q, qd, th, thd, thdd, P)
%BOP_ACELERACION Dinamica no lineal de la bola sobre el plato (2 ejes).
%
%   qdd = bop_aceleracion(q, qd, th, thd, thdd, P)
%
%   q    = [x; y]        posicion del centro de la bola en el MARCO DEL PLATO [mm]
%   qd   = [xd; yd]      velocidad relativa al plato [mm/s]
%   th   = [thx; thy]    inclinacion del plato [rad]; thx > 0 levanta el lado +X,
%                        thy > 0 levanta el lado +Y
%   thd, thdd            primera y segunda derivada de th [rad/s, rad/s^2]
%   qdd  = [xdd; ydd]    [mm/s^2]
%
% Modelo (Lagrange, derivado en etapaA/LEEME_etapaA.md, seccion 2):
%   - rotacion del plato R = Rx(thy)*Ry(-thx) alrededor del centro de la junta
%     universal (eje exterior de la cruceta fijo a la base sobre X);
%   - centro de la bola a una altura h sobre el pivote, medida sobre la normal;
%   - rodadura sin deslizamiento y sin giro relativo alrededor de la normal;
%   - bola rigida con J = k m r^2, c = 1/(1+k); la masa se cancela;
%   - sin friccion de rodadura (se agrega en la Etapa B si los datos lo piden).

x  = q(1);   y  = q(2);
xd = qd(1);  yd = qd(2);
ax = th(1);  ay = th(2);
axd = thd(1);  ayd = thd(2);
axdd = thdd(1); aydd = thdd(2);

g = P.g;  c = P.c_rod;  h = P.h;  kr = P.k_inercia*P.r_bola;   % k*r_b = J/(m r_b)

sx = sin(ax);  cx = cos(ax);

fx = -g*sx*cos(ay) ...
     + x*axd^2 + x*ayd^2*sx^2 + 0.5*h*ayd^2*sin(2*ax) ...
     - 2*ayd*yd*sx - y*aydd*sx ...
     + (h + kr)*axdd;

fy = -g*sin(ay) ...
     - kr*axd*ayd*sx - 2*h*axd*ayd*sx + 2*x*axd*ayd*cx + y*ayd^2 ...
     + 2*ayd*xd*sx ...
     + aydd*((kr + h)*cx + x*sx);

qdd = c*[fx; fy];
end
