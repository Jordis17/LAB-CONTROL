function [T, tr] = parametros_triplete(A, x_pico_frac, P, L, omega_plato, modo, frac_lenta)
%PARAMETROS_TRIPLETE Duracion base y de transicion del triplete de prueba.
%
%   T  : el doble integrador ideal (xdd = -c*g*sin(A)) llega a
%        x_pico_frac*x_max en el pico del triplete: c*g*sin(A)*T^2 = x_pico.
%   tr : duracion de cada transicion de coseno alzado.
%        modo 'rapida': el salto mayor (2A) se hace a la velocidad maxima del
%                       plato, (pi/2)*2A/tr = omega_plato, con minimo T_pwm.
%        modo 'lenta' : tr = frac_lenta*T.
%   Error si tr >= T (el perfil no se puede armar).

if nargin < 6, modo = 'rapida'; end
if nargin < 7, frac_lenta = 0.8; end

x_pico = x_pico_frac*P.x_max;
T = sqrt(x_pico/(L.Kg*sin(A)));         % L.Kg = c*g
switch lower(modo)
    case 'rapida'
        tr = max(P.T_pwm, pi*A/omega_plato);
    case 'lenta'
        tr = frac_lenta*T;
    otherwise
        error('parametros_triplete: modo desconocido "%s".', modo);
end
if tr >= T
    error('parametros_triplete: tr = %.3f s >= T = %.3f s para A = %.2f deg.', tr, T, rad2deg(A));
end
end
