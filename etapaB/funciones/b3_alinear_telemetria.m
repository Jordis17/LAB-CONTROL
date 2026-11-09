function [th, s, coincide] = b3_alinear_telemetria(L)
%B3_ALINEAR_TELEMETRIA Inclinacion pedida al plato en cada cuadro del log.
%
%   [th, s, coincide] = b3_alinear_telemetria(L)
%
% En el log de main_vision.py, cada fila guarda la ultima telemetria que llego
% ANTES de mandar la trama de esa fila, o sea la respuesta a una trama
% anterior. El eco tel_x_rx (x que recibio la ESP32) dice a cual: se busca el
% corrimiento s (0 a 3 filas) para el que tel_x_rx(k) = x(k - s).
% th (n x 2, deg): th(j,:) = [tel_thx tel_thy] de la respuesta a la trama j,
% es decir, la inclinacion que la ESP32 mando al plato despues de recibir el
% cuadro j (convencion del firmware: th > 0 levanta el lado del servo).
% coincide: fraccion de filas cuyo eco coincide con ese corrimiento.
n = L.n;
mejor = -1;  s = 1;
for cand = 0:3
    k = (1+cand):n;
    ok = abs(L.tel_x_rx(k) - L.x(k-cand)) < 0.015;
    f = sum(ok)/max(1, sum(~isnan(L.tel_x_rx(k))));
    if f > mejor, mejor = f;  s = cand; end
end
coincide = mejor;
th = NaN(n, 2);
j = 1:(n-s);
th(j,1) = L.tel_thx(j+s);
th(j,2) = L.tel_thy(j+s);
end
