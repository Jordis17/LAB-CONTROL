%% ETAPA E - SCRIPT 1: LA PREPARACION NO ALTERO EL COMPORTAMIENTO DEL MIL
% Comprueba, muestra a muestra, que Controller_BoP.slx calcula exactamente lo
% mismo que el controlador evaluado en el MIL (Etapa D).
%
% Metodo (lazo abierto, sin planta):
%   1. Se simulan con el MIL (bop_mil_simular) los casos D1 (requisitos),
%      D2 (empujon con saturacion), D3 (desnivel, integrador activo) y D4
%      (dos ejes), con anti-windup y saturacion como en el modelo.
%   2. De cada caso y eje se toman las entradas que recibio el controlador en
%      cada cuadro (r, x_hat, v_hat, habilitado) y sus salidas (th_cmd, I, saturado).
%   3. Parte A (no requiere Simulink): las mismas entradas se pasan por
%      ley_control_BoP_bloque.m, la funcion que va dentro del bloque.
%   4. Parte B: las mismas entradas se pasan por Controller_BoP.slx con sim().
%   5. Se compara cada salida: max|dif|, RMSE e igualdad exacta.
% Criterio PASS: max|dif| <= 1e-12 en th_cmd e I, y cero diferencias en saturado.
%
% Requisitos: C1_controlador.mat (Etapa C) y Controller_BoP.slx (E0).
% Salidas (resultados/): E1_consola.txt, E1_equivalencia.csv (resumen),
%   E1_caso_<caso>_eje<e>.csv (series), E1_resultados.mat

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaC'), fullfile(raiz,'etapaC','funciones'), fullfile(raiz,'etapaD','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'E1_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA E - E1_verificar_equivalencia_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('Version: %s\n', version);
tol = 1e-12;

S = load(fullfile(raiz,'etapaC','resultados','C1_controlador.mat'));
C = S.Ctrl;
P = A0_parametros_BoP();
base = bop_mil_config(P, C);
base.kalman_sigma_a = C.kalman_sigma_a;  base.kalman_sigma_m = C.kalman_sigma_m;
base.omega_n_servo = C.omega_n_servo;

%% 1. Casos MIL (mismas condiciones que etapaD/D1_MIL_BoP)
casos = struct('nombre',{},'cfg',{},'ejes',{});
c = base;  c.x0 = [100; 0];  c.T_fin = 6.5;
casos(end+1) = struct('nombre','D1_requisitos','cfg',c,'ejes',1);
c = base;  c.v0 = [420; 0];  c.th_dist = [deg2rad(1); 0];  c.t_espera = 0;  c.T_fin = 6;
casos(end+1) = struct('nombre','D2_sat_con_AW','cfg',c,'ejes',1);
c = base;  c.th_dist = [deg2rad(1); 0];  c.t_espera = 0;  c.T_fin = 10;
casos(end+1) = struct('nombre','D3_desnivel','cfg',c,'ejes',1);
c = base;  c.x0 = [80; -60];  c.r = @(t) [50; 50]*(t >= 4.5);  c.T_fin = 9;
casos(end+1) = struct('nombre','D4_dos_ejes','cfg',c,'ejes',[1 2]);

pruebas = struct('caso',{},'eje',{},'t_espera',{},'r',{},'xh',{},'vh',{},'hab',{}, ...
                 'th',{},'I',{},'sat',{});
for i = 1:numel(casos)
    R = bop_mil_simular(casos(i).cfg);
    for e = casos(i).ejes
        k = numel(pruebas) + 1;
        pruebas(k).caso = casos(i).nombre;  pruebas(k).eje = e;
        pruebas(k).t_espera = casos(i).cfg.t_espera;
        pruebas(k).r  = R.k_r(:,e);   pruebas(k).xh = R.k_xh(:,e);  pruebas(k).vh = R.k_vh(:,e);
        pruebas(k).hab = R.k_tcap >= casos(i).cfg.t_espera - 1e-9;
        pruebas(k).th = R.k_th(:,e);  pruebas(k).I = R.k_I(:,e);    pruebas(k).sat = R.k_sat(:,e);
        fprintf('Caso %-14s eje %d: %d cuadros, saturado en %d, habilitado desde el cuadro %d\n', ...
            casos(i).nombre, e, numel(R.k_tcap), sum(R.k_sat(:,e)), find(pruebas(k).hab,1));
    end
end

%% 2. Parte A: funcion del bloque fuera de Simulink
fprintf('\n=== Parte A: ley_control_BoP_bloque.m (fuera de Simulink) vs MIL ===\n');
resA = zeros(numel(pruebas), 6);
for k = 1:numel(pruebas)
    clear ley_control_BoP_bloque            % reinicia las variables persistentes
    p = pruebas(k);  n = numel(p.r);
    th = zeros(n,1);  I = th;  sat = false(n,1);
    for j = 1:n
        [th(j), I(j), sat(j)] = ley_control_BoP_bloque(p.r(j), p.xh(j), p.vh(j), p.hab(j), ...
            C.Kp, C.Ki, C.Kd, C.Ts, C.th_lim, C.e_clip, C.v_int, C.Nq);
    end
    resA(k,:) = [max(abs(th - p.th)) rmse_v(th - p.th) isequal(th, p.th) ...
                 max(abs(I - p.I)) rmse_v(I - p.I) sum(sat ~= p.sat)];
    fprintf('  %-14s eje %d: th max|dif| = %.3g, igual = %d | I max|dif| = %.3g | saturado distinto en %d\n', ...
        p.caso, p.eje, resA(k,1), resA(k,3), resA(k,4), resA(k,6));
end
okA = all(resA(:,1) <= tol & resA(:,4) <= tol & resA(:,6) == 0);
fprintf('  Parte A: %s\n', pasa_falla(okA));

%% 3. Parte B: Controller_BoP.slx
fprintf('\n=== Parte B: Controller_BoP.slx (sim) vs MIL ===\n');
okB = false;  txtB = 'NO EJECUTADA';  resB = NaN(numel(pruebas), 6);  series = cell(numel(pruebas),1);
if exist('OCTAVE_VERSION','builtin') || ~license('test','Simulink')
    fprintf('  Simulink no disponible en esta instalacion: se omite la Parte B.\n');
else
    mdl = 'Controller_BoP';
    init_Controller_BoP();
    load_system(fullfile(carpeta,[mdl '.slx']));
    Ts = evalin('base','Ts_ctrl');
    for k = 1:numel(pruebas)
        p = pruebas(k);  n = numel(p.r);
        t = (0:n-1)'*Ts;
        ds = Simulink.SimulationData.Dataset;
        ds = ds.addElement(timeseries(p.r,  t), 'r_mm');
        ds = ds.addElement(timeseries(p.xh, t), 'x_hat_mm');
        ds = ds.addElement(timeseries(p.vh, t), 'v_hat_mm_s');
        ds = ds.addElement(timeseries(logical(p.hab), t), 'habilitado');
        in = Simulink.SimulationInput(mdl);
        in = in.setExternalInput(ds);
        in = in.setModelParameter('StopTime', sprintf('%.17g', t(end)));   % setExternalInput ya habilita la entrada externa
        out = sim(in);
        y = out.yout;
        th  = squeeze(double(y.getElement(1).Values.Data));
        I   = squeeze(double(y.getElement(2).Values.Data));
        sat = squeeze(logical(y.getElement(3).Values.Data));
        if numel(th) ~= n
            error('E1:Muestras','%s eje %d: el modelo devolvio %d muestras y el MIL %d.', p.caso, p.eje, numel(th), n);
        end
        resB(k,:) = [max(abs(th - p.th)) rmse_v(th - p.th) isequal(th, p.th) ...
                     max(abs(I - p.I)) rmse_v(I - p.I) sum(sat ~= p.sat)];
        fprintf('  %-14s eje %d: th max|dif| = %.3g, RMSE = %.3g, igual = %d | I max|dif| = %.3g | saturado distinto en %d\n', ...
            p.caso, p.eje, resB(k,1), resB(k,2), resB(k,3), resB(k,4), resB(k,6));
        series{k} = [(0:n-1)' t p.r p.xh p.vh double(p.hab) p.th th th - p.th p.I I I - p.I double(p.sat) double(sat)];
        escribir_csv(fullfile(dirRes, sprintf('E1_caso_%s_eje%d.csv', p.caso, p.eje)), ...
            {'k','t_s','r_mm','xh_mm','vh_mm_s','habilitado','th_MIL_rad','th_SLX_rad','dif_th_rad', ...
             'I_MIL_rad','I_SLX_rad','dif_I_rad','sat_MIL','sat_SLX'}, series{k});
    end
    okB = all(resB(:,1) <= tol & resB(:,4) <= tol & resB(:,6) == 0);
    txtB = pasa_falla(okB);
    fprintf('  Parte B: %s (criterio max|dif| <= %.0e)\n', txtB, tol);
end

%% Guardado
fid = fopen(fullfile(dirRes,'E1_equivalencia.csv'),'w');
fprintf(fid, 'caso,eje,A_th_maxdif,A_th_rmse,A_th_igual,A_I_maxdif,A_I_rmse,A_sat_distintos,B_th_maxdif,B_th_rmse,B_th_igual,B_I_maxdif,B_I_rmse,B_sat_distintos\n');
for k = 1:numel(pruebas)
    fprintf(fid, '%s,%d', pruebas(k).caso, pruebas(k).eje);
    fprintf(fid, ',%.6g', [resA(k,:) resB(k,:)]);
    fprintf(fid, '\n');
end
fclose(fid);
save(fullfile(dirRes,'E1_resultados.mat'), 'resA', 'resB', 'okA', 'okB', 'txtB', 'tol');
fprintf('\nResultado: Parte A %s, Parte B %s\n', pasa_falla(okA), txtB);
fprintf('FIN E1\n');
