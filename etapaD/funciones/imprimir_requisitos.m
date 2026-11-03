function imprimir_requisitos(M, Rq)
%IMPRIMIR_REQUISITOS Metricas del ensayo de requisitos y verificacion explicita.
imprimir_metricas_D(M);
fprintf('  Verificacion de requisitos:\n');
fprintf('    R1 ts  = %5.2f s   <= %.1f s   -> %s\n', M.ts, Rq.ts_max_s, sino(M.cumple.ts));
fprintf('    R2 Mp  = %5.1f %%   <= %.0f %%    -> %s\n', M.Mp, Rq.Mp_max_pct, sino(M.cumple.Mp));
fprintf('    R3 ess = %5.2f mm  <= %.1f mm  -> %s\n', M.ess, Rq.ess_max_mm, sino(M.cumple.ess));
fprintf('    R4 max|x| (plato) = %5.1f mm <= %.0f mm -> %s\n', M.max_abs_x_plato, Rq.x_lim_mm, sino(M.cumple.pared));
end
