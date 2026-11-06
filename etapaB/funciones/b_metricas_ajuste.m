function M = b_metricas_ajuste(y, yhat)
%B_METRICAS_AJUSTE Metricas de validacion (CLAUDE.md, Etapa B).
%   RMSE, MAE, sesgo = media(y - yhat), R2, FIT = 100*(1 - ||e|| / ||y - media(y)||),
%   y estructura temporal del residuo: autocorrelacion en el retardo 1 y pendiente
%   del residuo contra el tiempo de muestra (si el residuo tiene tendencia o esta
%   correlacionado, al modelo le falta algo).
e = y(:) - yhat(:);
M.rmse = sqrt(mean(e.^2));
M.mae = mean(abs(e));
M.sesgo = mean(e);
M.r2 = 1 - sum(e.^2)/sum((y(:) - mean(y(:))).^2);
M.fit = 100*(1 - norm(e)/norm(y(:) - mean(y(:))));
ec = e - mean(e);
if numel(e) > 2 && any(ec ~= 0)
    M.acorr1 = sum(ec(1:end-1).*ec(2:end))/sum(ec.^2);
else
    M.acorr1 = NaN;
end
k = (0:numel(e)-1)';
pf = [ones(size(k)) k] \ e;
M.tendencia = pf(2);      % mm por muestra
M.res = e;
end
