function E = bop_terminos_error(R, P, L)
%BOP_TERMINOS_ERROR Descompone el error de aceleracion del modelo lineal (eje X).
%
%   E = bop_terminos_error(R, P, L)     R de bop_simular_triplete
%
% Sobre la trayectoria del modelo NO lineal se evalua
%   e_total   = xdd_no_lineal - xdd_lineal,  xdd_lineal = c*(-g*thx + h_ef*thxdd)
% y se separa en
%   e_sen     = c*g*(thx - sin(thx)*cos(thy))   (aproximacion del seno)
%   e_centrif = c*x*thxd^2                      (fuerza centrifuga)
%   e_resto   = e_total - e_sen - e_centrif     (terminos de acople entre ejes)
% Cada uno tambien como inclinacion equivalente th_eq = max|e|/(c*g) [deg].
%
% Es un error "instantaneo" del modelo: no se acumula como el error de
% posicion en lazo abierto, asi que dice cuanto se equivoca el modelo lineal
% en cada instante, que es lo que vera un controlador en lazo cerrado.

n = numel(R.t);
E.total = zeros(n,1);
for i = 1:n
    a = bop_aceleracion([R.x_nl(i); R.y_nl(i)], [R.xd_nl(i); R.yd_nl(i)], ...
        [R.thx(i); R.thy(i)], [R.thxd(i); R.thyd(i)], [R.thxdd(i); R.thydd(i)], P);
    E.total(i) = a(1) - P.c_rod*(-P.g*R.thx(i) + L.h_ef*R.thxdd(i));
end
E.sen     = P.c_rod*P.g*(R.thx - sin(R.thx).*cos(R.thy));
E.centrif = P.c_rod*R.x_nl.*R.thxd.^2;
E.resto   = E.total - E.sen - E.centrif;

aeq = @(e) rad2deg(max(abs(e))/(P.c_rod*P.g));
E.max_total = max(abs(E.total));    E.th_eq_total_deg = aeq(E.total);
E.max_sen   = max(abs(E.sen));      E.th_eq_sen_deg   = aeq(E.sen);
E.max_cf    = max(abs(E.centrif));  E.th_eq_cf_deg    = aeq(E.centrif);
E.max_resto = max(abs(E.resto));    E.th_eq_resto_deg = aeq(E.resto);
end
