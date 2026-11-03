function t_rec = tiempo_recuperacion(R, eje, banda)
%TIEMPO_RECUPERACION Instante (desde t_espera) desde el cual |x_hat| < banda para siempre.
x = R.k_xh(:,eje);  t = R.k_tcap;
sel = t >= R.cfg.t_espera - 1e-9;  x = x(sel);  t = t(sel) - R.cfg.t_espera;
fuera = find(abs(x) >= banda, 1, 'last');
if isempty(fuera), t_rec = 0;
elseif fuera == numel(t), t_rec = NaN;
else, t_rec = t(fuera+1);
end
end
