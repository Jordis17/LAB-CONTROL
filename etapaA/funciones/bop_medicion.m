function [Xm, p] = bop_medicion(q, th, P)
%BOP_MEDICION Posicion que entrega la camara para un estado del plato.
%
%   [Xm, p] = bop_medicion(q, th, P)
%
%   q  = [x; y]      posicion de la bola en el marco del plato [mm]
%   th = [thx; thy]  inclinacion del plato [rad]
%   Xm = [Xm; Ym]    posicion que reporta el pipeline de vision [mm]
%   p  = [px;py;pz]  centro de la bola en el marco fijo, origen en la junta [mm]
%
% Hipotesis (a verificar en la Etapa B):
%   - la camara esta fija al suelo, sobre el eje vertical que pasa por la junta,
%     a P.H_cam sobre la cara superior del plato horizontal;
%   - la homografia se calibro con el plato horizontal y queda fija, asi que
%     mapea puntos del PLANO z = h_sup (marco fijo), no del plato inclinado;
%   - el pipeline multiplica por (H_cam - r_bola)/H_cam (paralaje, config.py).
% Con el plato horizontal Xm = [x; y] exactamente. Con el plato inclinado la
% camara ve la proyeccion horizontal del centro de la bola, no la coordenada
% sobre el plato. A primer orden: Xm = x - h*thx.

ax = th(1);  ay = th(2);
R = [1 0 0; 0 cos(ay) -sin(ay); 0 sin(ay) cos(ay)] * ...
    [cos(-ax) 0 sin(-ax); 0 1 0; -sin(-ax) 0 cos(-ax)];
p = R*[q(1); q(2); P.h];

% Rayo desde la camara (0, 0, h_sup + H_cam) por el centro de la bola,
% intersectado con el plano z = h_sup.
altura_sobre_plano = p(3) - P.h_sup;
escala_rayo = P.H_cam/(P.H_cam - altura_sobre_plano);
escala_paralaje = (P.H_cam - P.r_bola)/P.H_cam;
Xm = p(1:2)*escala_rayo*escala_paralaje;
end
