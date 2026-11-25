%% ETAPA D - MIL DE LA SEGUNDA ESTRATEGIA (LQR) Y COMPARACION CON EL PID
% El enunciado pide dos estrategias de control validadas hasta MIL. Este script
% evalua el LQR de C2 con el mismo simulador, la misma planta, el mismo Ts,
% retardo, ruido (misma semilla), configuracion numerica y tiempo de simulacion
% que el PID de D1, y corre el PID en cada caso para comparar en igualdad:
%   L1  Requisitos: bola a 100 mm en X, referencia 0.
%   L2  Saturacion y proteccion del integrador del LQR: empujon de 420 mm/s con
%       desnivel de 1 deg: (1) actuador ideal, (2) saturado sin AW, (3) con AW.
%   L3  Perturbacion: desnivel de 1 deg con la bola en el centro.
%   L4  Dos ejes: (80, -60) -> (0, 0) y a los 4,5 s -> (50, 50).
%   L5  Robustez: L1 con un parametro cambiado a la vez, incluidos los valores
%       identificados en el prototipo (Etapa B): c efectivo ~0,2 y retardo ~0,3 s.
%
% Requisitos previos: etapaC/resultados/C1_controlador.mat y C2_controlador_LQR.mat.
% Salidas (resultados/): D2_consola.txt, D2_resultados.mat, D2_comparacion.csv,
%   D_caso_LQR_<nombre>.csv (mismo formato que D1; I_x_deg es el aporte del
%   integrador -Kz*z). Orden de columnas en etapaD/orden_csv.md.

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), ...
        fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaC'), fullfile(raiz,'etapaC','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'D2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA D - D2_MIL_LQR_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('%s\n', version);

S1 = load(fullfile(raiz,'etapaC','resultados','C1_controlador.mat'));  Cpid = S1.Ctrl;  Rq = S1.Rq;
S2 = load(fullfile(raiz,'etapaC','resultados','C2_controlador_LQR.mat'));  Clqr = S2.Ctrl;
P = A0_parametros_BoP(false);
fprintf('PID (C1): Kp = %.5f deg/mm, Kd = %.5f deg/(mm/s), Ki = %.5f deg/(mm s), integracion condicional\n', ...
    rad2deg(Cpid.Kp), rad2deg(Cpid.Kd), rad2deg(Cpid.Ki));
fprintf('LQR (C2): Ke = %.5f deg/mm, Kv = %.5f deg/(mm/s), Kz = %.6f deg/(mm s), d = %d entradas pasadas\n', ...
    -rad2deg(Clqr.K(1)), -rad2deg(Clqr.K(2)), -rad2deg(Clqr.K(end)), Clqr.d);
fprintf('Los dos: th_lim = %.1f deg, Kalman sigma_a = %g, sigma_m = %g, servo omega_n = %g rad/s\n\n', ...
    rad2deg(Clqr.th_lim), Clqr.kalman_sigma_a, Clqr.kalman_sigma_m, Clqr.omega_n_servo);

base = bop_mil_config(P, Clqr);
base.kalman_sigma_a = Clqr.kalman_sigma_a;
base.kalman_sigma_m = Clqr.kalman_sigma_m;
base.omega_n_servo  = Clqr.omega_n_servo;
ctrl = {'PID', Cpid; 'LQR', Clqr};

tabla = {};      % filas: {caso, controlador, eje, M}
resultados = struct();

%% L1 - Requisitos
fprintf('=== L1. Ensayo de requisitos: x0 = %g mm, r = 0 ===\n', Rq.x0_mm);
for j = 1:2
    cfg = base;  cfg.C = ctrl{j,2};  cfg.x0 = [Rq.x0_mm; 0];  cfg.T_fin = 6.5;
    R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
    fprintf(' %s\n', ctrl{j,1});  imprimir_requisitos(M, Rq);
    if j == 2, guardar_caso(dirRes, 'LQR_L1_requisitos', R); end
    tabla(end+1,:) = {'L1_requisitos', ctrl{j,1}, 1, M};  resultados.(['L1_' ctrl{j,1}]) = M;
end

%% L2 - Saturacion y anti-windup del LQR
fprintf('\n=== L2. Saturacion y anti-windup (LQR): empujon de 420 mm/s desde el centro, desnivel 1 deg ===\n');
nombres = {'L2_sin_saturacion','L2_sat_sin_AW','L2_sat_con_AW'};
desc = {'(1) actuador ideal, sin saturacion', '(2) saturado, sin anti-windup', '(3) saturado, con anti-windup'};
for i = 1:3
    cfg = base;  cfg.v0 = [420; 0];  cfg.th_dist = [deg2rad(1); 0];  cfg.t_espera = 0;  cfg.T_fin = 6;
    switch i
        case 1, cfg.actuador_ideal = true;
        case 2, cfg.usar_aw = false;
        case 3, cfg.usar_aw = true;
    end
    R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
    t_rec = tiempo_recuperacion(R, 1, Rq.ess_max_mm);
    fprintf('  %s\n', desc{i});
    fprintf('    max|x_hat| = %.1f mm, max|x| plato = %.1f mm, th_cmd en [%.2f, %.2f] deg, u en [%.2f, %.2f] deg\n', ...
        M.max_abs_xhat, M.max_abs_x_plato, M.th_min_deg, M.th_max_deg, rad2deg(min(R.k_u(:,1))), rad2deg(max(R.k_u(:,1))));
    fprintf('    saturado %.1f %% del tiempo (%.2f s); aporte del integrador en [%.3f, %.3f] deg; |x_hat| < %.0f mm desde %.2f s; ess = %.2f mm\n', ...
        M.pct_saturado, M.t_saturado, rad2deg(min(R.k_I(:,1))), rad2deg(max(R.k_I(:,1))), Rq.ess_max_mm, t_rec, M.ess);
    if R.toca_pared, fprintf('    AVISO: la bola pasa |x| = %.0f mm.\n', P.x_max); end
    guardar_caso(dirRes, ['LQR_' nombres{i}], R);
    tabla(end+1,:) = {nombres{i}, 'LQR', 1, M};  resultados.(nombres{i}) = M;  resultados.(nombres{i}).t_rec = t_rec;
end

%% L3 - Perturbacion (desnivel)
fprintf('\n=== L3. Perturbacion: desnivel de 1 deg en X, bola en el centro ===\n');
for j = 1:2
    cfg = base;  cfg.C = ctrl{j,2};  cfg.th_dist = [deg2rad(1); 0];  cfg.t_espera = 0;  cfg.T_fin = 10;
    R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
    t_rec = tiempo_recuperacion(R, 1, Rq.ess_max_mm);
    fprintf('  %s: max|x_hat| = %.1f mm, ess (ultimo s) = %.2f mm, recupera |x_hat| < %.0f mm a los %.2f s\n', ...
        ctrl{j,1}, M.max_abs_xhat, M.ess, Rq.ess_max_mm, t_rec);
    if j == 2, guardar_caso(dirRes, 'LQR_L3_desnivel', R); end
    tabla(end+1,:) = {'L3_desnivel', ctrl{j,1}, 1, M};
end

%% L4 - Dos ejes
fprintf('\n=== L4. Dos ejes: (80, -60) -> (0, 0) y a los 4,5 s -> (50, 50) ===\n');
ejes = 'XY';
for j = 1:2
    cfg = base;  cfg.C = ctrl{j,2};  cfg.x0 = [80; -60];  cfg.r = @(t) [50; 50]*(t >= 4.5);  cfg.T_fin = 9;
    R = bop_mil_simular(cfg);
    for e = 1:2
        Ma = bop_metricas_respuesta(recortar(R, 4.5), e, Rq);
        Mb = bop_metricas_respuesta(R, e, Rq, 4.5);
        fprintf('  %s eje %s, tramo 1: ', ctrl{j,1}, ejes(e));  imprimir_corto(Ma);
        fprintf('  %s eje %s, tramo 2: ', ctrl{j,1}, ejes(e));  imprimir_corto(Mb);
        tabla(end+1,:) = {sprintf('L4_eje%s_tramo1',ejes(e)), ctrl{j,1}, e, Ma};
        tabla(end+1,:) = {sprintf('L4_eje%s_tramo2',ejes(e)), ctrl{j,1}, e, Mb};
    end
    if j == 2, guardar_caso(dirRes, 'LQR_L4_dos_ejes', R); end
end

%% L5 - Robustez
fprintf('\n=== L5. Robustez: ensayo L1 con un parametro cambiado a la vez ===\n');
var = { 'nominal',                    base;
        'retardo 120 ms',             setc(base,'retardo',0.120);
        'c = 0,685',                  setP(base,'c_rod',0.685);
        'ruido 2 mm',                 setc(base,'sigma_ruido',2.0);
        'firmware sin tabla',         setc(base,'actuador_tipo','medido_ik_lineal');
        'c = 0,2 (identificado)',     setP(base,'c_rod',0.2);
        'c = 0,2 y retardo 0,3 s',    setc(setP(base,'c_rod',0.2),'retardo',0.3) };
fprintf('  caso                        ctrl   ts[s]   Mp[%%]  ess[mm]  max|x|[mm]  cumple\n');
for i = 1:size(var,1)
    for j = 1:2
        cfg = var{i,2};  cfg.C = ctrl{j,2};  cfg.x0 = [Rq.x0_mm; 0];  cfg.T_fin = 8;
        R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
        ok = all(cell2mat(struct2cell(M.cumple)));
        fprintf('  %-27s %-4s %6.2f  %6.1f  %6.2f  %9.1f      %s\n', var{i,1}, ctrl{j,1}, M.ts, M.Mp, M.ess, ...
            M.max_abs_x_plato, sino(ok));
        tabla(end+1,:) = {['L5_' limpiar(var{i,1})], ctrl{j,1}, 1, M};
    end
end

%% Tabla de comparacion
cols = {'caso','controlador','eje','x0_mm','r_mm','tr_s','ts_s','Mp_pct','ess_mm','max_abs_xhat_mm', ...
        'max_abs_x_plato_mm','th_min_deg','th_max_deg','pct_saturado','t_saturado_s','std_th_ss_deg'};
fid = fopen(fullfile(dirRes,'D2_comparacion.csv'),'w');
fprintf(fid, '%s', cols{1});  fprintf(fid, ',%s', cols{2:end});  fprintf(fid, '\n');
for i = 1:size(tabla,1)
    M = tabla{i,4};
    v = [tabla{i,3} M.x0 M.r M.tr M.ts M.Mp M.ess M.max_abs_xhat M.max_abs_x_plato ...
         M.th_min_deg M.th_max_deg M.pct_saturado M.t_saturado M.std_th_ss_deg];
    fprintf(fid, '%s,%s', tabla{i,1}, tabla{i,2});  fprintf(fid, ',%.6g', v);  fprintf(fid, '\n');
end
fclose(fid);

save(fullfile(dirRes,'D2_resultados.mat'), 'resultados', 'tabla', 'Cpid', 'Clqr', 'P', 'Rq');
fprintf('\nResultados en %s\n', dirRes);
fprintf('FIN D2\n');
