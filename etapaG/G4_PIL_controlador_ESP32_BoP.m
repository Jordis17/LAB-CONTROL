%% ETAPA G - SCRIPT 4: PIL DEL CONTROLADOR SOLO (ESP32 vs MIL)
% Equivale a la prueba minima de G0, por la ruta propia: las entradas del
% controlador en dos ensayos del MIL (D1 requisitos y D2 empujon, con 9
% cuadros saturados) se mandan cuadro por cuadro a la ESP32, que ejecuta el
% codigo generado (Controller_BoP_ESP32_step), y se compara con el MIL.
% Criterio PASS: max|dif| <= 1e-12 en th_cmd e I, y cero diferencias en saturado.
% Tambien registra cuantos ciclos de CPU tarda cada llamada a _step.
% Requisitos: G3 (sketch cargado), ESP32 conectada y el puerto libre.
% Salidas: resultados/G4_consola.txt, G4_resultados.csv, G4_caso_*.csv

clearvars; close all; clc;
puerto = '/dev/ttyUSB0';
f_cpu = 240e6;                          % ESP32_CPUFrequency de la placa (G0c)

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(carpeta,'funciones'), fullfile(raiz,'etapaE'), fullfile(raiz,'etapaA'), ...
        fullfile(raiz,'etapaA','funciones'), fullfile(raiz,'etapaC'), fullfile(raiz,'etapaC','funciones'), ...
        fullfile(raiz,'etapaD','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G4_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G4_PIL_controlador_ESP32_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);
tol = 1e-12;

% Mismos ensayos que G0 y E1
S = load(fullfile(raiz,'etapaC','resultados','C1_controlador.mat'));
C = S.Ctrl;  P = A0_parametros_BoP();
base = bop_mil_config(P, C);
base.kalman_sigma_a = C.kalman_sigma_a;  base.kalman_sigma_m = C.kalman_sigma_m;
base.omega_n_servo = C.omega_n_servo;
casos = {'D1_requisitos', setfield(setfield(base,'x0',[100;0]),'T_fin',6.5); ...
         'D2_sat_con_AW', setfield(setfield(setfield(setfield(setfield(base,'v0',[420;0]), ...
              'th_dist',[deg2rad(1);0]),'t_espera',0),'T_fin',6),'usar_aw',true)};
init_Controller_BoP();
Ts = evalin('base','Ts_ctrl');

sp = g_pil_abrir(puerto);
res = zeros(size(casos,1), 6);  todosCiclos = [];
for k = 1:size(casos,1)
    R = bop_mil_simular(casos{k,2});
    n = numel(R.k_tcap);  t = (0:n-1)'*Ts;
    hab = R.k_tcap >= casos{k,2}.t_espera - 1e-9;
    g_pil_reiniciar(sp);
    th = zeros(n,1);  I = zeros(n,1);  sat = false(n,1);  cic = zeros(n,1);
    for i = 1:n
        [th(i), I(i), sat(i), cic(i)] = g_pil_paso(sp, 0, R.k_r(i,1), R.k_xh(i,1), R.k_vh(i,1), hab(i));
    end
    dth = th - R.k_th(:,1);  dI = I - R.k_I(:,1);
    res(k,:) = [max(abs(dth)) rmse_v(dth) isequal(th, R.k_th(:,1)) max(abs(dI)) rmse_v(dI) sum(sat ~= R.k_sat(:,1))];
    fprintf('\n%s: %d cuadros, %d saturados en el MIL, %d en la ESP32\n', casos{k,1}, n, sum(R.k_sat(:,1)), sum(sat));
    fprintf('  th max|dif| = %.3g, RMSE = %.3g, igual = %d | I max|dif| = %.3g | saturado distinto en %d\n', res(k,:));
    fprintf('  _step en la ESP32: %d a %d ciclos (%.1f a %.1f us), mediana %.1f us\n', ...
        min(cic), max(cic), min(cic)/f_cpu*1e6, max(cic)/f_cpu*1e6, median(cic)/f_cpu*1e6);
    todosCiclos = [todosCiclos; cic]; %#ok<AGROW>
    escribir_csv(fullfile(dirRes, sprintf('G4_caso_%s.csv', casos{k,1})), ...
        {'k','t_s','r_mm','xh_mm','vh_mm_s','habilitado','th_MIL_rad','th_PIL_rad','dif_th_rad', ...
         'I_MIL_rad','I_PIL_rad','dif_I_rad','sat_MIL','sat_PIL','ciclos_step'}, ...
        [(0:n-1)' t R.k_r(:,1) R.k_xh(:,1) R.k_vh(:,1) double(hab) R.k_th(:,1) th dth R.k_I(:,1) I dI ...
         double(R.k_sat(:,1)) double(sat) cic]);
end
ok = all(res(:,1) <= tol & res(:,4) <= tol & res(:,6) == 0);
fid = fopen(fullfile(dirRes,'G4_resultados.csv'),'w');
fprintf(fid, 'caso,th_maxdif,th_rmse,th_igual,I_maxdif,I_rmse,sat_distintos\n');
for k = 1:size(casos,1), fprintf(fid, '%s,%.6g,%.6g,%d,%.6g,%.6g,%d\n', casos{k,1}, res(k,:)); end
fclose(fid);
fprintf('\nTiempo de _step en la ESP32 (todas las llamadas): max %.1f us = %.4f %% de Ts\n', ...
    max(todosCiclos)/f_cpu*1e6, 100*max(todosCiclos)/f_cpu/Ts);
clear sp   % cierra el puerto
fprintf('Resultado PIL del controlador (ESP32 vs MIL): %s (criterio max|dif| <= %.0e)\nFIN G4\n', pasa_falla(ok), tol);
