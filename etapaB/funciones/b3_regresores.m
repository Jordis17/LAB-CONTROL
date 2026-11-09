function [Phi, xr, tr] = b3_regresores(t, xm, th_deg, tau, ini, fin, P, sv, dtf, vk)
%B3_REGRESORES Regresores de una ventana para xdd = -c g sin(th(t - tau)) + b.
%
% Ventana de cuadros ini..fin. th_deg(j) es la orden de inclinacion conocida en
% la fila j (b3_alinear_telemetria); se toma aplicada (retencion de orden cero)
% desde t(j) + tau hasta t(j+1) + tau. Devuelve, para cada cuadro de la ventana:
%   xr   posicion sobre el plato (mm), corrigiendo la medicion de la camara con
%        la inclinacion real en ese instante (b_corregir_inclinacion, Etapa A);
%   Phi  [II(-g sin th)  (t-t0)^2/2  1  (t-t0)]: con x = Phi*[c; b; x0; v0].
% sv: signo de la vision en ese eje (x_plato = sv * x_vision).
t0 = t(ini);
tt = (t0:dtf:t(fin) + dtf/2)';
% inclinacion en cada instante fino: ultima orden j con t(j) + tau <= tt
idx = interp1(t + tau, (1:numel(t))', tt, 'previous');
idx(isnan(idx)) = 1;
thf = deg2rad(th_deg(idx));
a = -P.g*sin(thf);
v = [0; cumsum((a(1:end-1) + a(2:end))/2)*dtf];
p = [0; cumsum((v(1:end-1) + v(2:end))/2)*dtf];
k = (ini:fin)';
tr = t(k) - t0;
II = interp1(tt - t0, p, tr, 'linear', 'extrap');
th_k = deg2rad(th_deg(max(1, interp1(t + tau, (1:numel(t))', t(k), 'previous'))));
th_k(isnan(th_k)) = 0;
xr = b_corregir_inclinacion(sv*xm(k), th_k, P);
Phi = [II tr.^2/2 ones(size(tr)) tr];
% Rozamiento de rodadura (Coulomb): aceleracion -f*sign(v), con el signo de la
% velocidad del Kalman en cada cuadro (vk). Columna 5: con x = Phi*[c; b; x0; v0; f].
if nargin >= 10 && ~isempty(vk)
    sg = sign(sv*vk(idx));  sg(isnan(sg)) = 0;
    vf = [0; cumsum((-sg(1:end-1) - sg(2:end))/2)*dtf];
    pf = [0; cumsum((vf(1:end-1) + vf(2:end))/2)*dtf];
    Phi = [Phi interp1(tt - t0, pf, tr, 'linear', 'extrap')];
end
end
