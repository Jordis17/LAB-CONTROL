function M = bop_metricas_respuesta(R, eje, Rq, t_ini)
%BOP_METRICAS_RESPUESTA Metricas de un ensayo con las definiciones de C0_requisitos_BoP.
%
%   M = bop_metricas_respuesta(R, eje, Rq)          ensayo desde t_espera
%   M = bop_metricas_respuesta(R, eje, Rq, t_ini)   ensayo que empieza en t_ini
%
% Senal: x_hat del Kalman en los instantes de captura (R.k_tcap, R.k_xh).
% x0 = promedio de x_hat en los 0,3 s previos a t_ini (o el primer cuadro si
% no hay); r = referencia en el ultimo cuadro. Tiempos medidos desde t_ini.
% Si |r - x0| < 5 mm (ensayo de perturbacion) tr, ts y Mp quedan en NaN.

if nargin < 4, t_ini = R.cfg.t_espera; end
t_all = R.k_tcap;  x_all = R.k_xh(:,eje);
previo = t_all < t_ini - 1e-9 & t_all >= t_ini - 0.3 - 1e-9;
sel = t_all >= t_ini - 1e-9;
t = t_all(sel) - t_ini;  x = x_all(sel);  r_all = R.k_r(sel,eje);
r = r_all(end);
if any(previo), x0 = mean(x_all(previo)); else, x0 = x(1); end
D = r - x0;
M.x0 = x0;  M.r = r;  M.D = D;

% tr (10 - 90 %)
if abs(D) >= 5     % con un cambio de referencia menor a 5 mm, tr/ts/Mp no se definen
    p = (x - x0)/D;
    i10 = find(p >= 0.1, 1, 'first');  i90 = find(p >= 0.9, 1, 'first');
    if isempty(i10) || isempty(i90), M.tr = NaN; else, M.tr = t(i90) - t(i10); end
    banda = Rq.banda_frac*abs(D);
    fuera = find(abs(x - r) > banda, 1, 'last');
    if isempty(fuera), M.ts = 0;
    elseif fuera == numel(t), M.ts = NaN;      % nunca entra en la banda
    else, M.ts = t(fuera + 1);
    end
    M.Mp = max(0, max((x - r)*sign(D)))/abs(D)*100;
    M.banda = banda;
else
    M.tr = NaN;  M.ts = NaN;  M.Mp = NaN;  M.banda = NaN;
end
ult = t >= t(end) - Rq.ventana_ess_s;
M.ess = abs(mean(x(ult) - r));
M.max_abs_xhat = max(abs(x));

% Del modelo (no medible en el experimento)
selc = R.t >= t_ini - 1e-9;
M.max_abs_x_plato = max(abs(R.x(selc,eje)));
M.toca_pared = M.max_abs_x_plato > Rq.x_lim_mm;

% Accion de control
thc = R.k_th(sel,eje);
M.th_min_deg = rad2deg(min(thc));  M.th_max_deg = rad2deg(max(thc));
M.pct_saturado = 100*mean(R.k_sat(sel,eje));
M.t_saturado = sum(R.k_sat(sel,eje))*R.cfg.C.Ts;
ss = t >= t(end) - Rq.ventana_ess_s;
M.std_th_ss_deg = rad2deg(std(thc(ss)));

M.cumple = struct('ts', M.ts <= Rq.ts_max_s, 'Mp', M.Mp <= Rq.Mp_max_pct, ...
    'ess', M.ess <= Rq.ess_max_mm, 'pared', ~M.toca_pared);
end
