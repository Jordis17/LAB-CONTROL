function [th, atraso, coincide] = b3_alinear_telemetria(L)
%B3_ALINEAR_TELEMETRIA Inclinacion pedida al plato en el instante de cada fila del log.
%
%   [th, atraso, coincide] = b3_alinear_telemetria(L)
%
% th (n x 2, deg): ultima orden de inclinacion que la ESP32 mando al plato y
% que la PC ya habia recibido al capturar la fila k (tel_thx, tel_thy,
% retenida en las filas sin telemetria). La ESP32 manda la telemetria apenas
% mueve el plato, asi que esa orden esta aplicada desde un poco antes de t(k);
% la diferencia (y la respuesta del servo) la absorbe el retardo tau de B3.
% Esta es la entrada fisica al plato, aunque la ESP32 haya trabajado con datos
% atrasados (lo que paso en el log del 2026-11-09 12:06).
%
% atraso: diagnostico del atraso de los datos con los que trabajo la ESP32, en
% cuadros: la mediana de (k - j) con x(j) = eco tel_x_rx(k), buscando hasta 40
% filas atras, solo con la bola en movimiento (si esta quieta el eco coincide
% con cualquier fila). coincide: fraccion de ecos encontrados.
n = L.n;
th = NaN(n, 2);
ultimo = [NaN NaN];
for k = 1:n
    if ~isnan(L.tel_thx(k)), ultimo = [L.tel_thx(k) L.tel_thy(k)]; end
    th(k,:) = ultimo;
end
lags = [];  nt = 0;
for k = 2:n
    if isnan(L.tel_x_rx(k)) || isnan(L.vx(k)) || abs(L.vx(k)) < 80, continue; end
    nt = nt + 1;
    for s = 1:40
        j = k - s;
        if j < 1, break; end
        if abs(L.tel_x_rx(k) - L.x(j)) < 0.011, lags(end+1) = s; break; end %#ok<AGROW>
    end
end
if isempty(lags), atraso = NaN; else, atraso = median(lags); end
coincide = numel(lags)/max(1, nt);
end
