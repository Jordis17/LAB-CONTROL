%% ETAPA G - SCRIPT 2: SIMULACION DEL BANCO PIL Y COMPARACION NORMAL vs PIL
% Generado a partir de etapaF/F1_comparar_Normal_SIL_BoP.m. La rama PIL corre el
% controlador EN LA ESP32 (Simulink le manda las entradas y recibe las salidas por
% el puerto serie en cada paso); la planta sigue simulada en la PC.
% Simula BoP_Test_PIL.slx (G1) y compara MUESTRA A MUESTRA las dos ramas.
% Para cada senal reporta el maximo absoluto de la diferencia, el RMSE y si
% son exactamente iguales. Diferencias = senal_PIL - senal_Normal.
%
% Senales del controlador (lo que verifica PIL): th_cmd, I y saturado de
% cada eje. Senales de la planta (consecuencia): posicion estimada y real.
% Criterio PASS: max|dif| <= 1e-12 en th e I, cero diferencias en saturado.
%
% La generacion se hace dentro de etapaG/build. La ESP32 debe estar conectada y el
% puerto libre (cerrar main_vision.py, miniterm y el Monitor Serie).
% Salidas (resultados/): G2_consola.txt, G2_metricas.csv,
%   G2_comparacion.csv (series por muestra), G2_resultados.mat

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(raiz,'etapaF','funciones'), fullfile(raiz,'etapaE'), ...
        fullfile(raiz,'etapaC','funciones'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G2_comparar_Normal_PIL_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

banco = 'BoP_Test_PIL';
tol = 1e-12;

dirBuild = fullfile(carpeta,'build');
if ~isfolder(dirBuild), mkdir(dirBuild); end
Simulink.fileGenControl('set', 'CodeGenFolder', dirBuild, 'CacheFolder', dirBuild, 'createDir', true);
restaurar = onCleanup(@() Simulink.fileGenControl('reset'));
dirAntes = pwd;  cd(dirBuild);  volver = onCleanup(@() cd(dirAntes));

init_Controller_BoP();
load_system(fullfile(raiz,'etapaE','Controller_BoP.slx'));
load_system(fullfile(carpeta,'Controller_BoP_ESP32.slx'));
load_system(fullfile(carpeta,[banco '.slx']));
for b = {'Ctrl_X_Normal','Ctrl_Y_Normal','Ctrl_X_PIL','Ctrl_Y_PIL'}
    fprintf('  %-14s modo: %s\n', b{1}, get_param([banco '/' b{1}], 'SimulationMode'));
end
fprintf('Simulando (la primera vez compila y carga el codigo en la ESP32)...\n');
tic;
out = sim(banco);
fprintf('Duracion de la simulacion PIL: %.1f s\n', toc);

senales = {'thx','rad'; 'thy','rad'; 'Ix','rad'; 'Iy','rad'; 'satx','-'; 'saty','-'; ...
           'xhx','mm'; 'xhy','mm'; 'x','mm'; 'y','mm'};
fprintf('\n  senal   unidad   max|PIL-Normal|      RMSE      iguales/total\n');
M = zeros(size(senales,1), 4);
serie = [];  cab = {'t_s'};
for k = 1:size(senales,1)
    tsN = out.get(['Normal_' senales{k,1}]);  tsS = out.get(['PIL_' senales{k,1}]);
    a = double(squeeze(tsN.Data));  s = double(squeeze(tsS.Data));
    if numel(a) ~= numel(s), error('G2:Largo','%s: %d muestras en Normal y %d en PIL.', senales{k,1}, numel(a), numel(s)); end
    d = s - a;
    M(k,:) = [max(abs(d)) sqrt(mean(d.^2)) sum(d == 0) numel(d)];
    fprintf('  %-6s  %-6s   %14.3g   %12.3g   %6d/%d\n', senales{k,1}, senales{k,2}, M(k,:));
    if isempty(serie), serie = tsN.Time(:); end
    serie = [serie a s d]; %#ok<AGROW>
    cab = [cab, {['Normal_' senales{k,1}], ['PIL_' senales{k,1}], ['dif_' senales{k,1}]}]; %#ok<AGROW>
end
okCtrl = all(M(1:4,1) <= tol) && all(M(5:6,1) == 0);
fprintf('\nCriterio (th e I: max|dif| <= %.0e; saturado: 0 diferencias): %s\n', tol, pasa_falla(okCtrl));
fprintf('Senales de la planta: max|dif| x = %.3g mm, y = %.3g mm\n', M(9,1), M(10,1));

escribir_csv(fullfile(dirRes,'G2_comparacion.csv'), cab, serie);
fid = fopen(fullfile(dirRes,'G2_metricas.csv'),'w');
fprintf(fid, 'senal,unidad,max_abs_dif,rmse,iguales,total\n');
for k = 1:size(senales,1)
    fprintf(fid, '%s,%s,%.6g,%.6g,%d,%d\n', senales{k,1}, senales{k,2}, M(k,:));
end
fclose(fid);
save(fullfile(dirRes,'G2_resultados.mat'), 'M', 'senales', 'okCtrl', 'tol');
fprintf('FIN G2\n');
