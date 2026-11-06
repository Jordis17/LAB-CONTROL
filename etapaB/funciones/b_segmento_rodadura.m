function S = b_segmento_rodadura(t, p, x_lim, n_salto)
%B_SEGMENTO_RODADURA Tramo de rodadura libre de un ensayo B1 y ajuste cuadratico.
%
%   S = b_segmento_rodadura(t, p, x_lim, n_salto)
%
%   t, p     tiempo [s] y posicion cruda de la camara en el eje [mm] (NaN = no detectada)
%   x_lim    no usar puntos con |p| > x_lim (antes de tocar el borde) [mm]
%   n_salto  cuadros que se descartan despues de la suelta (mano en la imagen)
%
% Criterio (fijo, el mismo para todos los ensayos):
%   - posicion de reposo = mediana de los primeros 5 cuadros validos;
%   - suelta = primer cuadro con |p - reposo| > 3 mm;
%   - el tramo empieza n_salto cuadros despues de la suelta y sigue mientras
%     la bola este detectada, |p| < x_lim y no cambie de sentido (rebote);
%   - se ajusta p = p0 + v0*tau + a*tau^2/2 por minimos cuadrados (tau desde
%     el primer punto del tramo).
% S.ok = false si el tramo tiene menos de 8 puntos.

S.ok = false;  S.motivo = '';
val = find(~isnan(p));
if numel(val) < 15, S.motivo = 'pocas detecciones'; return; end
reposo = median(p(val(1:5)));
k_suelta = val(find(abs(p(val) - reposo) > 3, 1, 'first'));
if isempty(k_suelta), S.motivo = 'la bola no se movio'; return; end
k0 = k_suelta + n_salto;
if k0 > numel(p), S.motivo = 'sin datos tras la suelta'; return; end
% sentido del movimiento
k_fin_dir = min(numel(p), k0 + 6);
sv = sign(p(k_fin_dir) - p(k0));
if sv == 0 || isnan(sv), S.motivo = 'sentido indefinido'; return; end
idx = k0;
for k = k0+1:numel(p)
    if isnan(p(k)) || abs(p(k)) > x_lim, break; end
    if sign(p(k) - p(idx(end))) == -sv && abs(p(k) - p(idx(end))) > 1.5, break; end   % rebote
    idx(end+1) = k; %#ok<AGROW>
end
idx = idx(~isnan(p(idx)));
if numel(idx) < 8, S.motivo = sprintf('tramo corto (%d puntos)', numel(idx)); return; end
tau = t(idx) - t(idx(1));
A = [ones(size(tau)) tau 0.5*tau.^2];
coef = A \ p(idx);
res = p(idx) - A*coef;
S.ok = true;  S.idx = idx;  S.tau = tau;  S.p = p(idx);
S.p0 = coef(1);  S.v0 = coef(2);  S.a = coef(3);
S.res = res;  S.rms = sqrt(mean(res.^2));
S.reposo = reposo;  S.k_suelta = k_suelta;  S.sentido = sv;
end
