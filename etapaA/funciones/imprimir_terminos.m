function imprimir_terminos(E)
%IMPRIMIR_TERMINOS Resumen de bop_terminos_error.
fprintf('    Error de aceleracion (max |.|, y como inclinacion equivalente):\n');
fprintf('      total      %9.2f mm/s^2  (%.4f deg)\n', E.max_total, E.th_eq_total_deg);
fprintf('      seno       %9.2f mm/s^2  (%.4f deg)\n', E.max_sen,   E.th_eq_sen_deg);
fprintf('      centrifugo %9.2f mm/s^2  (%.4f deg)\n', E.max_cf,    E.th_eq_cf_deg);
fprintf('      resto      %9.2f mm/s^2  (%.4f deg)\n', E.max_resto, E.th_eq_resto_deg);
end
