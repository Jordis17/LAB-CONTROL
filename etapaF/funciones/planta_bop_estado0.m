function S = planta_bop_estado0(Pp)
%PLANTA_BOP_ESTADO0 Estado inicial de la planta del banco SIL/PIL (ver planta_bop_paso).
% La estructura se arma de una sola vez: la generacion de codigo no permite
% agregar campos a una estructura despues de haberla leido.
%#codegen
q0  = Pp.x0;                       % posicion de la bola en el marco del plato [mm] (2x1)
th0 = [0; 0];                      % inclinacion del plato [rad]
y0  = bop_medicion(q0, th0, Pp.P); % primera medicion (sin ruido) para llenar la cola
S = struct( ...
    'q',       q0, ...             % posicion [mm]
    'qd',      [0; 0], ...         % velocidad [mm/s]
    'th',      th0, ...            % inclinacion del plato [rad]
    'thd',     [0; 0], ...         % velocidad angular del plato [rad/s]
    'buf',     repmat(y0, 1, Pp.nd), ...  % mediciones en transito (retardo de nd cuadros)
    'kx',      zeros(2,2), ...     % Kalman: columna e = [x_hat; v_hat] del eje e
    'kP',      zeros(2,2,2), ...   % Kalman: covarianza del eje e
    'kini',    false, ...
    'semilla', Pp.semilla);        % generador congruencial (mismo en las dos ramas)
end
