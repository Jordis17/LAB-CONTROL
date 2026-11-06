function S = planta_bop_estado0(Pp)
%PLANTA_BOP_ESTADO0 Estado inicial de la planta del banco SIL/PIL (ver planta_bop_paso).
%#codegen
S.q   = Pp.x0;              % posicion de la bola en el marco del plato [mm] (2x1)
S.qd  = [0; 0];             % velocidad [mm/s]
S.th  = [0; 0];             % inclinacion del plato [rad]
S.thd = [0; 0];             % velocidad angular del plato [rad/s]
y0 = bop_medicion(S.q, S.th, Pp.P);
S.buf = repmat(y0, 1, Pp.nd);   % mediciones en transito (retardo de nd cuadros)
S.kx  = zeros(2,2);         % Kalman: columna e = [x_hat; v_hat] del eje e
S.kP  = zeros(2,2,2);       % Kalman: covarianza del eje e
S.kini = false;
S.semilla = Pp.semilla;     % generador congruencial (mismo en las dos ramas)
end
