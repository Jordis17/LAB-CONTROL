function E = bop_controlador_estado0()
%BOP_CONTROLADOR_ESTADO0 Estado inicial del controlador de un eje.
E.I = 0;     % integrador [rad]
E.nq = 0;    % cuadros seguidos con |v_hat| < v_int
end
