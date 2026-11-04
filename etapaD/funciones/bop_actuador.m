function A = bop_actuador(P, tipo)
%BOP_ACTUADOR Modelo del actuador (servo + mecanismo) por eje, para el MIL.
%
%   A = bop_actuador(P, tipo)
%
%   tipo = 'medido'           relacion comando -> plato MEDIDA en el prototipo
%                             (datos_prototipo/mecanica/servo_plato_v2_convencion_plato.csv,
%                             2026-11-04). El firmware simulado invierte la misma
%                             tabla (asi lo hara el firmware real).
%          'medido_ik_lineal' planta con la relacion medida, pero el firmware
%                             convierte con la pendiente del diseno y sin tabla:
%                             c = -th/0,343 (sirve para ver por que hace falta la tabla)
%          'diseno'           cinematica de cuatro barras del diseno (Etapa A)
%
% Estado del actuador, por eje: a [rad]. Con 'medido', a es el COMANDO del
% sketch (grados respecto de 1500 us, pasados a rad; 11,1 us por grado); con
% 'diseno', es el angulo fisico del brazo.
% Campos:
%   A.fk(e, a)  -> [th, dth/da, d2th/da2]   inclinacion del plato [rad] (convencion
%                                            del modelo: th > 0 levanta el lado +)
%   A.ik(e, th) -> a                         lo que manda el firmware para pedir th
%   A.amin, A.amax [rad]                     carrera usable del estado a
%   A.wmax [rad/s]                           velocidad maxima de a
%   A.a0 [2x1]                               estado inicial (firmware pidiendo th = 0)
%   A.th_alcance [rad]                       inclinacion simetrica alcanzable (min de los ejes)

if nargin < 2, tipo = 'medido'; end
A.tipo = tipo;
switch tipo
    case 'diseno'
        A.fk = @(e, a) fk_diseno(a, P);
        A.ik = @(e, th) ik_diseno(e, th, P);
        A.amin = -P.phi_max*[1;1];  A.amax = P.phi_max*[1;1];
        A.wmax = P.omega_srv*[1;1];
        A.a0 = [0; 0];
        thl = [fk_diseno(-P.phi_max, P) fk_diseno(P.phi_max, P)];
        A.th_alcance = min(abs(thl));

    case {'medido', 'medido_ik_lineal'}
        raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        arch = fullfile(raiz, 'datos_prototipo', 'mecanica', 'servo_plato_v2_convencion_plato.csv');
        if ~isfile(arch)
            error('bop_actuador:SinTabla', 'No se encontro %s', arch);
        end
        M = dlmread(arch, ',', 1, 0);           % comando_deg, thx_deg, thy_deg
        c  = deg2rad(M(:,1));
        th = deg2rad(M(:,2:3));
        A.c_tab = c;  A.th_tab = th;  A.archivo = arch;
        % Escala del servo: grados fisicos por grado de comando. Estimacion del
        % ajuste de la tabla (1,66 en X y 1,75 en Y, 2026-11-04). Solo se usa
        % para pasar la velocidad maxima del servo a unidades de comando.
        A.k_servo = 1.70;
        % Interpolacion pchip (monotona, derivada continua), armada una sola vez,
        % con sus derivadas analiticas.
        pp = cell(2,3);  ppi = cell(2,1);
        for e = 1:2
            pp{e,1} = pchip(c, th(:,e));
            pp{e,2} = derivar_pp(pp{e,1});
            pp{e,3} = derivar_pp(pp{e,2});
            [ths, i] = sort(th(:,e));
            ppi{e} = pchip(ths, c(i));
            A.th_rango(e,:) = [ths(1) ths(end)];
        end
        A.fk = @(e, a) fk_tabla(a, c, pp(e,:));
        if strcmp(tipo, 'medido')
            A.ik = @(e, t) ppval(ppi{e}, min(max(t, A.th_rango(e,1)), A.th_rango(e,2)));
        else
            A.ik = @(e, t) min(max(-t/0.343, c(1)), c(end));
        end
        A.amin = c(1)*[1;1];  A.amax = c(end)*[1;1];
        A.wmax = P.omega_srv/A.k_servo*[1;1];
        A.a0 = [A.ik(1, 0); A.ik(2, 0)];   % lo que manda el firmware para th = 0
        A.th_alcance = min(min(abs([max(th); min(th)])));

    otherwise
        error('bop_actuador:Tipo', 'Tipo de actuador desconocido: %s', tipo);
end
end

% ----------------------------------------------------------------------
function [g0, g1, g2] = fk_diseno(a, P)
[g0, g1, g2] = bop_fk_plano(a, P);
end

function a = ik_diseno(e, th, P)
t2 = [0; 0];  t2(e) = th;
phi = bop_cinematica_inversa(t2, P, 'plano');
a = phi(e);
if isnan(a), a = sign(th)*P.phi_max; end
a = min(max(a, -P.phi_max), P.phi_max);
end

function [g0, g1, g2] = fk_tabla(a, c, pp)
ac = min(max(a, c(1)), c(end));
g0 = ppval(pp{1}, ac);
g1 = ppval(pp{2}, ac);
g2 = ppval(pp{3}, ac);
end

function ppd = derivar_pp(pp)
% Derivada de un polinomio por tramos (sin toolboxes).
[b, cf, l, k] = unmkpp(pp);
if k <= 1
    ppd = mkpp(b, zeros(l,1));
else
    ppd = mkpp(b, cf(:,1:k-1).*repmat(k-1:-1:1, l, 1));
end
end
