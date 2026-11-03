function imprimir_metricas_D(M)
%IMPRIMIR_METRICAS_D Resumen de bop_metricas_respuesta.
fprintf('    x0 = %.1f mm, r = %.1f mm: tr = %.2f s, ts = %.2f s, Mp = %.1f %%, ess = %.2f mm\n', ...
    M.x0, M.r, M.tr, M.ts, M.Mp, M.ess);
fprintf('    max|x_hat| = %.1f mm, max|x| plato = %.1f mm, th_cmd en [%.2f, %.2f] deg, saturado %.1f %% (%.2f s), std th en reposo %.3f deg\n', ...
    M.max_abs_xhat, M.max_abs_x_plato, M.th_min_deg, M.th_max_deg, M.pct_saturado, M.t_saturado, M.std_th_ss_deg);
end
