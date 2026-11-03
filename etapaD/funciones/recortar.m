function Rn = recortar(R, t_fin)
%RECORTAR Registro MIL truncado en t_fin (para medir un tramo de un ensayo).
Rn = R;
sel = R.k_tcap < t_fin - 1e-9;
for c = {'k_t','k_tcap','k_y','k_xh','k_vh','k_r','k_th','k_u','k_sat','k_I'}
    Rn.(c{1}) = R.(c{1})(sel,:);
end
selc = R.t < t_fin;
Rn.t = R.t(selc);  Rn.x = R.x(selc,:);  Rn.th = R.th(selc,:);  Rn.a = R.a(selc,:);
end
