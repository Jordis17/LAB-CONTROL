function x = b_corregir_inclinacion(Xm, th, P)
%B_CORREGIR_INCLINACION Posicion sobre el plato a partir de la de la camara (un eje).
%
%   x = b_corregir_inclinacion(Xm, th, P)
%
% Invierte, en un eje, el modelo de medicion de la Etapa A (bop_medicion):
%   p1 = x cos(th) - h sin(th),  p3 = x sin(th) + h cos(th)
%   Xm = p1 (H - rb) / (H - (p3 - h_sup))
% Despejando x (forma cerrada):
%   x = [Xm (H + h_sup - h cos th) + h sin th (H - rb)] / [cos th (H - rb) + Xm sin th]
% th [rad] con signo (th > 0 levanta el lado +), Xm y x en mm.
H = P.H_cam;  rb = P.r_bola;  h = P.h;  hs = P.h_sup;
c = cos(th);  s = sin(th);
x = (Xm.*(H + hs - h*c) + h*s*(H - rb)) ./ (c*(H - rb) + Xm*s);
end
