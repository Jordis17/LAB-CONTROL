function D = disenar_pd_asignacion(P, te, zeta, a)
%DISENAR_PD_ASIGNACION Ganancias PD por asignacion de polos con retardo.
%
%   D = disenar_pd_asignacion(P, te, zeta, a)
%
% Modelo de diseno de un eje (Etapa A, sin los ceros, retardo como atraso):
%     Xm(s)/TH(s) ~ -c*g / (s^2 * (te*s + 1))
% Ley:  th = Kp*(x - r) + Kd*v
% Polinomio caracteristico del lazo cerrado:
%     te*s^3 + s^2 + c*g*Kd*s + c*g*Kp = 0
% Se iguala a te*(s + a*w)*(s^2 + 2*zeta*w*s + w^2). El coeficiente de s^2
% fija w = 1/(te*(a + 2*zeta)): con un retardo dado, la velocidad del lazo
% no es libre. Luego:
%     Kd = te*(2*zeta*a + 1)*w^2/(c*g),   Kp = te*a*w^3/(c*g)
% Unidades: Kp [rad/mm], Kd [rad/(mm/s)], w [rad/s].

cg = P.c_rod*P.g;
D.w  = 1/(te*(a + 2*zeta));
D.Kd = te*(2*zeta*a + 1)*D.w^2/cg;
D.Kp = te*a*D.w^3/cg;
D.te = te;  D.zeta = zeta;  D.a = a;
D.polos = roots(te*conv([1 a*D.w], [1 2*zeta*D.w D.w^2]));
end
