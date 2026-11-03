function th = bop_cinematica_directa(phi, P, modo, th0)
%BOP_CINEMATICA_DIRECTA Inclinacion del plato para unos angulos de servo.
%
%   th = bop_cinematica_directa(phi, P)              modo '3D'
%   th = bop_cinematica_directa(phi, P, 'plano')
%   th = bop_cinematica_directa(phi, P, modo, th0)   con valor inicial
%
% Resuelve bop_cinematica_inversa(th) = phi con Newton y jacobiano numerico.
% Devuelve NaN si no converge.

if nargin < 3 || isempty(modo)
    modo = '3D';
end
if nargin < 4 || isempty(th0)
    th0 = phi*0.343;            % solo valor inicial (pendiente aproximada en el neutro)
end

th = th0(:);
tol = 1e-12;  e = 1e-7;
for it = 1:50
    F = bop_cinematica_inversa(th, P, modo) - phi(:);
    if any(isnan(F))
        th = [NaN; NaN];
        return
    end
    if max(abs(F)) < tol
        return
    end
    Jn = zeros(2);
    for j = 1:2
        dth = zeros(2,1);  dth(j) = e;
        Jn(:,j) = (bop_cinematica_inversa(th+dth, P, modo) - ...
                   bop_cinematica_inversa(th-dth, P, modo))/(2*e);
    end
    th = th - Jn\F;
end
if max(abs(F)) > 1e-9
    th = [NaN; NaN];
end
end
