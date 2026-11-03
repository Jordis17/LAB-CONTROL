function [th, thd, thdd] = bop_perfil_triplete(t, A, T, t0, tr)
%BOP_PERFIL_TRIPLETE Perfil de inclinacion +A / -A / +A suavizado.
%
%   [th, thd, thdd] = bop_perfil_triplete(t, A, T, t0, tr)
%
%   +A durante T, -A durante 2T, +A durante T, y luego 0, empezando en t0.
%   Con un doble integrador ideal, este perfil deja la bola en reposo en el
%   punto de partida, con un desplazamiento maximo de c*g*A*T^2. Por eso
%   sirve para comparar el modelo lineal con el no lineal en una planta que
%   no es estable en lazo abierto: la bola no se va a la pared.
%
%   Cada cambio es un escalon suavizado con coseno alzado de duracion tr,
%   centrado en el instante del cambio (el plato no puede saltar de angulo y
%   el modelo necesita thd y thdd finitos). Como todos los cambios usan la
%   misma tr, el perfil suavizado es el ideal convolucionado con un pulso
%   simetrico, y el retorno al origen se conserva en el modelo lineal.
%
%   A [rad], T, t0, tr [s]. Requiere tr < T y t0 >= tr/2 (perfil en reposo en t = 0).

if tr >= T
    error('bop_perfil_triplete: se requiere tr < T (tr = %g, T = %g).', tr, T);
end
if A ~= 0 && t0 - tr/2 < 0
    error('bop_perfil_triplete: la primera transicion empieza antes de t = 0 (t0 = %g, tr = %g).', t0, tr);
end

cambios = [t0, A; t0+T, -2*A; t0+3*T, 2*A; t0+4*T, -A];

th = zeros(size(t));  thd = th;  thdd = th;
for i = 1:size(cambios,1)
    tc = cambios(i,1);  D = cambios(i,2);
    tau = t - (tc - tr/2);
    dentro = tau >= 0 & tau <= tr;
    despues = tau > tr;
    w = pi/tr;
    th(dentro)   = th(dentro)   + D/2*(1 - cos(w*tau(dentro)));
    th(despues)  = th(despues)  + D;
    thd(dentro)  = thd(dentro)  + D/2*w*sin(w*tau(dentro));
    thdd(dentro) = thdd(dentro) + D/2*w^2*cos(w*tau(dentro));
end
end
