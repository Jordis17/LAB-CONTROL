function R = bop_simular_triplete(P, L, Ax, Ay, T, t0x, t0y, tr, t_fin, dt)
%BOP_SIMULAR_TRIPLETE Simula el modelo no lineal y el lineal con el mismo perfil.
%
%   R = bop_simular_triplete(P, L, Ax, Ay, T, t0x, t0y, tr, t_fin, dt)
%
%   Ax, Ay   amplitud del triplete en cada eje [rad] (0 = eje en reposo)
%   T        duracion base del triplete [s]
%   t0x,t0y  inicio del triplete en cada eje [s]
%   tr       duracion de cada transicion suavizada [s]
%   t_fin    tiempo final [s];  dt  paso de la rejilla de salida [s]
%
% El actuador se supone ideal (la inclinacion es exactamente el perfil): se
% compara solo la dinamica de la bola y la medicion, que es lo que se
% linealiza. Condicion inicial: bola en reposo en el centro.
%
% Estado integrado: [x y xd yd  xi_x xid_x xi_y xid_y]
%   los cuatro primeros, modelo no lineal (marco del plato);
%   los cuatro ultimos, modelo lineal desacoplado (xi = x - c*h_ef*th).

perfil = @(t) deal_perfil(t, Ax, Ay, T, t0x, t0y, tr);

rhs = @(t,s) derivada(t, s, perfil, P, L);
t = (0:dt:t_fin)';
opciones = odeset('RelTol',1e-9,'AbsTol',1e-9,'MaxStep',tr/4);
[~, S] = ode45(rhs, t, zeros(8,1), opciones);

[thx, thxd, thxdd] = bop_perfil_triplete(t, Ax, T, t0x, tr);
[thy, thyd, thydd] = bop_perfil_triplete(t, Ay, T, t0y, tr);

R.t = t;
R.thx = thx;  R.thy = thy;  R.thxd = thxd;  R.thyd = thyd;  R.thxdd = thxdd;  R.thydd = thydd;
R.x_nl = S(:,1);  R.y_nl = S(:,2);  R.xd_nl = S(:,3);  R.yd_nl = S(:,4);
R.x_li = S(:,5) + L.Dx*thx;
R.y_li = S(:,7) + L.Dx*thy;
R.Xm_li = S(:,5) + L.Dm*thx;
R.Ym_li = S(:,7) + L.Dm*thy;

R.Xm_nl = zeros(size(t));  R.Ym_nl = R.Xm_nl;
for i = 1:numel(t)
    Xm = bop_medicion([R.x_nl(i); R.y_nl(i)], [thx(i); thy(i)], P);
    R.Xm_nl(i) = Xm(1);  R.Ym_nl(i) = Xm(2);
end
R.toca_pared = any(abs([R.x_nl; R.y_nl]) > P.x_max);
end

function ds = derivada(t, s, perfil, P, L)
[th, thd, thdd] = perfil(t);
qdd = bop_aceleracion(s(1:2), s(3:4), th, thd, thdd, P);
ds = [s(3:4); qdd; ...
      s(6); -L.Kg*th(1); ...
      s(8); -L.Kg*th(2)];
end

function [th, thd, thdd] = deal_perfil(t, Ax, Ay, T, t0x, t0y, tr)
[a, b, c] = bop_perfil_triplete(t, Ax, T, t0x, tr);
[d, e, f] = bop_perfil_triplete(t, Ay, T, t0y, tr);
th = [a; d];  thd = [b; e];  thdd = [c; f];
end
