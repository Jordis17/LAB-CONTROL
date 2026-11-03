function imprimir_corto(M)
fprintf('tr = %.2f s, ts = %.2f s, Mp = %.1f %%, ess = %.2f mm, th en [%.1f, %.1f] deg\n', ...
    M.tr, M.ts, M.Mp, M.ess, M.th_min_deg, M.th_max_deg);
end
