function M = bop_metricas_error(t, y_ref, y_cmp, t_ini, t_fin)
%BOP_METRICAS_ERROR Metricas de la diferencia y_cmp - y_ref en [t_ini, t_fin].
%
%   M.max_ref   max |y_ref|                    (escala de la senal)
%   M.max_err   max |y_cmp - y_ref|
%   M.rmse      raiz del error cuadratico medio
%   M.sesgo     media de (y_cmp - y_ref)
%   M.rel_pct   100*max_err/max_ref
%
% Convencion del proyecto: y_ref = modelo NO lineal, y_cmp = modelo lineal,
% asi que el error es (lineal - no lineal).

sel = t >= t_ini & t <= t_fin;
e = y_cmp(sel) - y_ref(sel);
M.max_ref = max(abs(y_ref(sel)));
M.max_err = max(abs(e));
M.rmse    = sqrt(mean(e.^2));
M.sesgo   = mean(e);
if M.max_ref > 0
    M.rel_pct = 100*M.max_err/M.max_ref;
else
    M.rel_pct = NaN;
end
end
