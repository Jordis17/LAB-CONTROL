function Xm = b_prediccion_borde(hs, th, x, P)
%B_PREDICCION_BORDE Medicion de la camara (un eje) para la bola en x con el plato en th,
% usando h_sup = hs (modelo bop_medicion de la Etapa A).
Pn = P;  Pn.h_sup = hs;  Pn.h = hs + P.r_bola;
v = bop_medicion([x; 0], [th; 0], Pn);
Xm = v(1);
end
