function imprimir_metricas(nombre, M)
%IMPRIMIR_METRICAS Una linea con las metricas de bop_metricas_error.
fprintf('    %s: max|ref| = %8.2f mm, max|err| = %7.3f mm (%6.2f %%), RMSE = %7.3f mm, sesgo = %+7.3f mm\n', ...
    nombre, M.max_ref, M.max_err, M.rel_pct, M.rmse, M.sesgo);
end
