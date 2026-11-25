function E = bop_controlador_estado0(C)
%BOP_CONTROLADOR_ESTADO0 Estado inicial del controlador de un eje.
%   E = bop_controlador_estado0()     PID (estrategia 1)
%   E = bop_controlador_estado0(C)    segun C.tipo ('PID' o 'LQR')
E.I = 0;     % integrador [rad] (PID)
E.nq = 0;    % cuadros seguidos con |v_hat| < v_int (PID)
if nargin >= 1 && isfield(C, 'tipo') && strcmp(C.tipo, 'LQR')
    E.ub = zeros(C.d, 1);   % entradas ya mandadas [rad]: u[k-d] ... u[k-1]
    E.z  = 0;               % integral del error [mm s]
end
end
