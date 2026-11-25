function [K, Pr] = dlqr_propio(A, B, Q, R)
%DLQR_PROPIO Ganancia LQR discreta por iteracion de la ecuacion de Riccati.
%
%   [K, Pr] = dlqr_propio(A, B, Q, R)
%
% Minimiza  J = sum( x'Qx + u'Ru )  con  x[k+1] = A x[k] + B u[k],  u = -K x.
% Equivale a dlqr de Control System Toolbox (C2 lo compara si esta instalado),
% pero no lo necesita.

Pr = Q;
for it = 1:200000
    K = (R + B'*Pr*B)\(B'*Pr*A);
    Pn = A'*Pr*(A - B*K) + Q;
    Pn = (Pn + Pn')/2;
    if max(abs(Pn(:) - Pr(:))) <= 1e-13*max(1, max(abs(Pr(:))))
        Pr = Pn;
        break
    end
    Pr = Pn;
end
K = (R + B'*Pr*B)\(B'*Pr*A);
end
