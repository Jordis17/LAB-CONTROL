%% ETAPA D - MIL (MODEL-IN-THE-LOOP) DEL CONTROLADOR BALL ON PLATE
% Evalua el controlador de la Etapa C contra el modelo no lineal de la Etapa A
% con las restricciones reales del actuador (bop_mil_simular):
%   D1  Requisitos: bola a 100 mm en X, referencia 0.
%   D2  Saturacion y proteccion del integrador: empujon a la bola (420 mm/s
%       desde el centro) con desnivel de 1 deg; tres configuraciones bajo
%       condiciones identicas: (1) sin saturacion (actuador ideal), (2) saturado
%       sin AW, (3) saturado con AW. D2b: lo mismo con un PID clasico (sin
%       integracion condicional), para separar el efecto del clamping.
%   D3  Perturbacion: desnivel de 1 deg con la bola en el centro.
%   D4  Dos ejes: bola en (80, -60) mm, referencia (0, 0) y a los 4,5 s (50, 50).
%   D5  Robustez: D1 con variaciones de los parametros inciertos.
%   D6  Planta lineal vs no lineal en lazo cerrado (D1 y D2 con las dos plantas).
%
% Arranque: en D1, D4 y D5 la bola esta quieta y el controlador se habilita en
% t_espera = 0,5 s (las metricas se miden desde ahi). En D2 y D3 la bola ya se
% mueve o el plato ya esta desnivelado en t = 0, asi que t_espera = 0.
%
% Todas las comparaciones comparten planta, Ts, retardo, ruido (misma semilla),
% configuracion numerica (RK4, dt = Ts/33) y tiempo de simulacion, salvo lo que
% cada caso cambia a proposito.
% Metricas: definiciones de C0_requisitos_BoP (sobre x_hat del Kalman).
%
% Requisito previo: etapaC/resultados/C1_controlador.mat (correr C1 antes).
% Salidas (resultados/): D1_consola.txt, D1_resultados.mat, D1_metricas.csv,
%   D_caso_<nombre>.csv (series por cuadro). Orden de columnas en etapaD/orden_csv.md.

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), ...
        fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaC'), fullfile(raiz,'etapaC','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'D1_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA D - D1_MIL_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

archivoC = fullfile(raiz,'etapaC','resultados','C1_controlador.mat');
if ~isfile(archivoC)
    error('Falta %s. Corra primero etapaC/C1_disenar_controlador_BoP.', archivoC);
end
S = load(archivoC);  C = S.Ctrl;  Rq = S.Rq;
P = A0_parametros_BoP(true);
fprintf('Controlador (C1, %s): Kp = %.5f deg/mm, Kd = %.5f deg/(mm/s), Ki = %.5f deg/(mm s),\n', ...
    C.fecha, rad2deg(C.Kp), rad2deg(C.Kd), rad2deg(C.Ki));
fprintf('  th_lim = %.1f deg, e_clip = %g mm, v_int = %g mm/s, Nq = %d, Kalman sigma_a = %g, sigma_m = %g\n', ...
    rad2deg(C.th_lim), C.e_clip, C.v_int, C.Nq, C.kalman_sigma_a, C.kalman_sigma_m);

base = bop_mil_config(P, C);
base.kalman_sigma_a = C.kalman_sigma_a;
base.kalman_sigma_m = C.kalman_sigma_m;
base.omega_n_servo  = C.omega_n_servo;
fprintf('Simulacion: dt = Ts/%d, retardo total %.3f s (medicion %.3f s + PWM), servo omega_n = %g rad/s,\n', ...
    base.N_sub, base.retardo, base.retardo - P.T_pwm/2, base.omega_n_servo);
fprintf('  ruido de camara %.2f mm (semilla %d), velocidad del servo %.0f deg/s.\n\n', ...
    base.sigma_ruido, base.semilla, rad2deg(P.omega_srv));

tabla = {};      % filas: {nombre, eje, M}
resultados = struct();

%% D1 - Requisitos
fprintf('=== D1. Ensayo de requisitos: x0 = %g mm, r = 0 ===\n', Rq.x0_mm);
cfg = base;  cfg.x0 = [Rq.x0_mm; 0];  cfg.T_fin = 6.5;
R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
imprimir_requisitos(M, Rq);
guardar_caso(dirRes, 'D1_requisitos', R);
tabla(end+1,:) = {'D1_requisitos', 1, M};  resultados.D1 = M;

%% D2 - Saturacion y proteccion del integrador
fprintf('\n=== D2. Saturacion y anti-windup: empujon de 420 mm/s desde el centro, desnivel 1 deg ===\n');
nombres = {'D2_sin_saturacion','D2_sat_sin_AW','D2_sat_con_AW','D2b_PIDclasico_sat_sin_AW','D2b_PIDclasico_sat_con_AW'};
desc    = {'(1) actuador ideal, sin saturacion', '(2) saturado, sin anti-windup', '(3) saturado, con anti-windup', ...
           '(2b) PID clasico, saturado, sin anti-windup', '(3b) PID clasico, saturado, con anti-windup'};
for i = 1:numel(nombres)
    cfg = base;  cfg.v0 = [420; 0];  cfg.th_dist = [deg2rad(1); 0];  cfg.t_espera = 0;  cfg.T_fin = 6;
    switch i
        case 1, cfg.actuador_ideal = true;
        case {2,4}, cfg.usar_aw = false;
        case {3,5}, cfg.usar_aw = true;
    end
    if i >= 4
        cfg.C.v_int = Inf;  cfg.C.e_clip = Inf;  cfg.C.Nq = 1;
    end
    R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
    t_rec = tiempo_recuperacion(R, 1, Rq.ess_max_mm);
    fprintf('  %s\n', desc{i});
    fprintf('    max|x_hat| = %.1f mm, max|x| plato = %.1f mm, th_cmd en [%.2f, %.2f] deg, u en [%.2f, %.2f] deg\n', ...
        M.max_abs_xhat, M.max_abs_x_plato, M.th_min_deg, M.th_max_deg, rad2deg(min(R.k_u(:,1))), rad2deg(max(R.k_u(:,1))));
    fprintf('    saturado %.1f %% del tiempo (%.2f s); integrador en [%.3f, %.3f] deg; |x_hat| < %.0f mm desde %.2f s; ess = %.2f mm\n', ...
        M.pct_saturado, M.t_saturado, rad2deg(min(R.k_I(:,1))), rad2deg(max(R.k_I(:,1))), Rq.ess_max_mm, t_rec, M.ess);
    if R.toca_pared, fprintf('    AVISO: la bola pasa |x| = %.0f mm.\n', P.x_max); end
    guardar_caso(dirRes, nombres{i}, R);
    tabla(end+1,:) = {nombres{i}, 1, M};  resultados.(nombres{i}) = M;  resultados.(nombres{i}).t_rec = t_rec;
end

%% D3 - Perturbacion (desnivel)
fprintf('\n=== D3. Perturbacion: desnivel de 1 deg en X, bola en el centro ===\n');
cfg = base;  cfg.th_dist = [deg2rad(1); 0];  cfg.t_espera = 0;  cfg.T_fin = 10;
R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
t_rec = tiempo_recuperacion(R, 1, Rq.ess_max_mm);
fprintf('  max|x_hat| = %.1f mm, ess (ultimo s) = %.2f mm, recupera |x_hat| < %.0f mm a los %.2f s\n', ...
    M.max_abs_xhat, M.ess, Rq.ess_max_mm, t_rec);
fprintf('  Error que dejaria un PD: desnivel/Kp = %.1f mm\n', deg2rad(1)/C.Kp);
guardar_caso(dirRes, 'D3_desnivel', R);
tabla(end+1,:) = {'D3_desnivel', 1, M};  resultados.D3 = M;  resultados.D3.t_rec = t_rec;

%% D4 - Dos ejes
fprintf('\n=== D4. Dos ejes: (80, -60) -> (0, 0) y a los 4,5 s -> (50, 50) ===\n');
cfg = base;  cfg.x0 = [80; -60];  cfg.r = @(t) [50; 50]*(t >= 4.5);  cfg.T_fin = 9;
R = bop_mil_simular(cfg);
ejes = 'XY';
for e = 1:2
    Ma = bop_metricas_respuesta(recortar(R, 4.5), e, Rq);         % tramo 1: 0,5 a 4,5 s
    Mb = bop_metricas_respuesta(R, e, Rq, 4.5);                   % tramo 2: desde 4,5 s
    fprintf('  Eje %s, tramo 1 (x0 = %.0f -> 0):  ', ejes(e), Ma.x0);  imprimir_corto(Ma);
    fprintf('  Eje %s, tramo 2 (0 -> 50):         ', ejes(e));          imprimir_corto(Mb);
    tabla(end+1,:) = {sprintf('D4_eje%s_tramo1',ejes(e)), e, Ma};
    tabla(end+1,:) = {sprintf('D4_eje%s_tramo2',ejes(e)), e, Mb};
end
rad = sqrt(R.x(:,1).^2 + R.x(:,2).^2);
fprintf('  max distancia al centro (marco del plato): %.1f mm\n', max(rad));
guardar_caso(dirRes, 'D4_dos_ejes', R);

%% D5 - Robustez
fprintf('\n=== D5. Robustez: ensayo D1 con un parametro cambiado a la vez ===\n');
var = { 'nominal',               base;
        'retardo 120 ms',        setc(base,'retardo',0.120);
        'c = 0,685',             setP(base,'c_rod',0.685);
        'h_sup = 40 mm',         setP(base,'h_sup',40);
        'h_sup = 60 mm',         setP(base,'h_sup',60);
        'servos a 6 V',          setP(base,'omega_srv',deg2rad(60)/0.08);
        'servo lento (wn = 30)', setc(base,'omega_n_servo',30);
        'ruido 0,3 mm',          setc(base,'sigma_ruido',0.3);
        'ruido 2 mm',            setc(base,'sigma_ruido',2.0) };
fprintf('  caso                     ts[s]   Mp[%%]  ess[mm]  max|x|[mm]  std th ss[deg]  cumple\n');
for i = 1:size(var,1)
    cfg = var{i,2};  cfg.x0 = [Rq.x0_mm; 0];  cfg.T_fin = 6.5;
    R = bop_mil_simular(cfg);  M = bop_metricas_respuesta(R, 1, Rq);
    ok = all(cell2mat(struct2cell(M.cumple)));
    fprintf('  %-24s %5.2f  %6.1f  %6.2f  %9.1f  %12.3f      %s\n', var{i,1}, M.ts, M.Mp, M.ess, ...
        M.max_abs_x_plato, M.std_th_ss_deg, sino(ok));
    tabla(end+1,:) = {['D5_' limpiar(var{i,1})], 1, M};
end

%% D6 - Planta lineal vs no lineal en lazo cerrado
fprintf('\n=== D6. Planta lineal vs no lineal en lazo cerrado ===\n');
% columnas: nombre, x0, v0, desnivel, T_fin, t_espera
pruebas = {'D1', [Rq.x0_mm;0], [0;0],   [0;0],          6.5, 0.5;
           'D2', [0;0],        [420;0], [deg2rad(1);0], 6,   0};
for i = 1:size(pruebas,1)
    Ms = cell(1,2);  Rs = cell(1,2);
    pl = {'lineal','no_lineal'};
    for j = 1:2
        cfg = base;  cfg.planta = pl{j};
        cfg.x0 = pruebas{i,2};  cfg.v0 = pruebas{i,3};  cfg.th_dist = pruebas{i,4};  cfg.T_fin = pruebas{i,5};  cfg.t_espera = pruebas{i,6};
        Rs{j} = bop_mil_simular(cfg);  Ms{j} = bop_metricas_respuesta(Rs{j}, 1, Rq);
    end
    n = min(size(Rs{1}.k_xh,1), size(Rs{2}.k_xh,1));
    d = Rs{2}.k_xh(1:n,1) - Rs{1}.k_xh(1:n,1);
    fprintf('  Ensayo %s: lineal ts = %.2f s, Mp = %.1f %%, max|x| = %.1f mm | no lineal ts = %.2f s, Mp = %.1f %%, max|x| = %.1f mm | max|x_nl - x_lin| = %.2f mm\n', ...
        pruebas{i,1}, Ms{1}.ts, Ms{1}.Mp, Ms{1}.max_abs_x_plato, Ms{2}.ts, Ms{2}.Mp, Ms{2}.max_abs_x_plato, max(abs(d)));
    escribir_csv(fullfile(dirRes, sprintf('D6_lineal_vs_no_lineal_%s.csv', pruebas{i,1})), ...
        {'t_s','xh_lineal_mm','xh_no_lineal_mm','dif_mm','th_lineal_deg','th_no_lineal_deg'}, ...
        [Rs{1}.k_tcap(1:n) Rs{1}.k_xh(1:n,1) Rs{2}.k_xh(1:n,1) d rad2deg(Rs{1}.k_th(1:n,1)) rad2deg(Rs{2}.k_th(1:n,1))]);
    tabla(end+1,:) = {sprintf('D6_%s_lineal', pruebas{i,1}), 1, Ms{1}};
end

%% Tabla de metricas
cols = {'caso','eje','x0_mm','r_mm','tr_s','ts_s','Mp_pct','ess_mm','max_abs_xhat_mm','max_abs_x_plato_mm', ...
        'th_min_deg','th_max_deg','pct_saturado','t_saturado_s','std_th_ss_deg'};
fid = fopen(fullfile(dirRes,'D1_metricas.csv'),'w');
fprintf(fid, '%s', cols{1});  fprintf(fid, ',%s', cols{2:end});  fprintf(fid, '\n');
for i = 1:size(tabla,1)
    M = tabla{i,3};
    v = [tabla{i,2} M.x0 M.r M.tr M.ts M.Mp M.ess M.max_abs_xhat M.max_abs_x_plato ...
         M.th_min_deg M.th_max_deg M.pct_saturado M.t_saturado M.std_th_ss_deg];
    fprintf(fid, '%s', tabla{i,1});  fprintf(fid, ',%.6g', v);  fprintf(fid, '\n');
end
fclose(fid);

save(fullfile(dirRes,'D1_resultados.mat'), 'resultados', 'tabla', 'C', 'P', 'Rq');
fprintf('\nResultados en %s\n', dirRes);
fprintf('FIN D1\n');
