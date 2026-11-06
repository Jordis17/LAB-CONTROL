%% ETAPA G - SCRIPT 5: BANCO PIL EN LAZO CERRADO (ramas Normal y PIL)
% Mismo ensayo que el banco SIL (Etapa F): ejes X e Y, bola en (80, -60) mm,
% habilitado a los 0,5 s, referencia (0, 0) y a los 4,5 s (50, 50); 9 s;
% Ts = 1/30 s; un cuadro de retardo (Unit Delay) entre controlador y planta.
%   - rama Normal: la ley de control del modelo (bop_ley_control con la misma
%     envoltura que el bloque de Controller_BoP, ley_control_BoP_bloque),
%     ejecutada en MATLAB. E1 mostro que es identica bit a bit al modelo.
%   - rama PIL: el codigo generado ejecutandose en la ESP32 (dos instancias).
% Cada rama tiene SU PROPIA planta (planta_bop_paso, la del banco SIL), porque
% las acciones de control se calculan por separado. Comparten referencia,
% habilitacion, condicion inicial, Ts, ruido y duracion.
% Control de coherencia: la rama Normal de este banco debe reproducir la rama
% Normal del banco SIL de Simulink (etapaF/resultados/F1_comparacion.csv).
% Requisitos: G3, ESP32 conectada, puerto libre.
% Salidas: resultados/G5_consola.txt, G5_comparacion.csv, G5_metricas.csv,
%          G5_resultados.mat, G5_diferencias.png

clearvars; close all; clc;
puerto = '/dev/ttyUSB0';
f_cpu = 240e6;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(carpeta,'funciones'), fullfile(raiz,'etapaF','funciones'), fullfile(raiz,'etapaE'), ...
        fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), fullfile(raiz,'etapaC','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G5_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G5_PIL_lazo_cerrado_ESP32_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);
tol = 1e-12;

init_Controller_BoP();
par = cellfun(@(s) evalin('base', [s '.Value']), {'BoP_Kp','BoP_Ki','BoP_Kd','BoP_Ts','BoP_th_lim', ...
              'BoP_e_clip','BoP_v_int','BoP_Nq'});
Ts = par(4);
Pp = planta_bop_param();
n = round(9/Ts) + 1;                      % 0 ... 9 s (271 muestras, igual que F1)
t = (0:n-1)'*Ts;
k_ref = round(4.5/Ts);  k_hab = round(0.5/Ts);

sp = g_pil_abrir(puerto);
g_pil_reiniciar(sp);

nombres = {'thx','thy','Ix','Iy','satx','saty','xhx','xhy','x','y'};
D.Normal = zeros(n,10);  D.PIL = zeros(n,10);
cic = zeros(n,2);
for rama = {'Normal','PIL'}
    Sp = planta_bop_estado0(Pp);          % planta propia de la rama
    u = [0; 0];                           % salida del Unit Delay
    Ie = [0 0];  nq = [0 0];              % estado del controlador (rama Normal)
    for k = 1:n
        [y, Sp] = planta_bop_paso(u, Sp, Pp);
        r = 50*((k-1) >= k_ref);  hab = (k-1) >= k_hab;
        xh = [y(1) y(3)];  vh = [y(2) y(4)];
        th = [0 0];  I = [0 0];  sat = [false false];
        for e = 1:2
            if strcmp(rama{1}, 'Normal')
                if hab
                    [th(e), Ie(e), nq(e), ~, sat(e), ~] = bop_ley_control(xh(e), vh(e), r, Ie(e), nq(e), ...
                        par(1), par(2), par(3), par(4), par(5), par(6), par(7), par(8), true, true);
                else
                    th(e) = 0;  Ie(e) = 0;  nq(e) = 0;  sat(e) = false;
                end
                I(e) = Ie(e);
            else
                [th(e), I(e), sat(e), cic(k,e)] = g_pil_paso(sp, e-1, r, xh(e), vh(e), hab);
            end
        end
        D.(rama{1})(k,:) = [th I double(sat) xh y(5) y(6)];
        u = th(:);
    end
end

clear sp   % cierra el puerto

%% Comparacion muestra a muestra
fprintf('\nSenal   max|PIL-Normal|   RMSE        iguales\n');
M = zeros(10,3);
cab = {'t_s'};  datos = t;
for j = 1:10
    d = D.PIL(:,j) - D.Normal(:,j);
    M(j,:) = [max(abs(d)) rmse_v(d) sum(D.PIL(:,j) == D.Normal(:,j))];
    fprintf('%-6s  %-16.3g  %-10.3g  %d/%d\n', nombres{j}, M(j,1), M(j,2), M(j,3), n);
    cab = [cab, {['Normal_' nombres{j}], ['PIL_' nombres{j}], ['dif_' nombres{j}]}]; %#ok<AGROW>
    datos = [datos D.Normal(:,j) D.PIL(:,j) d]; %#ok<AGROW>
end
okCtrl = all(M(1:4,1) <= tol) && all(M(5:6,1) == 0);

%% Coherencia con el banco SIL de Simulink (rama Normal de F1)
F = readmatrix(fullfile(raiz,'etapaF','resultados','F1_comparacion.csv'));
colF = [2 5 8 11 14 17 20 23 26 29];      % Normal_thx ... Normal_y en F1_comparacion.csv
if size(F,1) == n
    dF = abs(D.Normal - F(:,colF));
    escala = max(abs(F(:,colF)), [], 1);  escala(escala == 0) = 1;
    rel = max(dF, [], 1) ./ escala;
    fprintf('\nRama Normal de este banco vs rama Normal del banco SIL (F1, CSV con 10 cifras):\n');
    fprintf('  max|dif| relativo por senal: %s\n', mat2str(rel, 3));
    fprintf('  Coherencia con F1: %s (criterio: < 1e-8 relativo, limitado por las 10 cifras del CSV)\n', pasa_falla(all(rel < 1e-8)));
else
    fprintf('\nAVISO: F1_comparacion.csv tiene %d filas y este banco %d.\n', size(F,1), n);
end

fprintf('\nTiempo de _step en la ESP32: max %.1f us (%.4f %% de Ts), mediana %.1f us\n', ...
    max(cic(:))/f_cpu*1e6, 100*max(cic(:))/f_cpu/Ts, median(cic(:))/f_cpu*1e6);
fprintf('Recorrido de la rama PIL: bola de (%.1f, %.1f) a (%.1f, %.1f) mm a los 4,4 s y (%.1f, %.1f) mm a los 9 s\n', ...
    D.PIL(1,9), D.PIL(1,10), D.PIL(k_ref-2,9), D.PIL(k_ref-2,10), D.PIL(end,9), D.PIL(end,10));

escribir_csv(fullfile(dirRes,'G5_comparacion.csv'), cab, datos);
fid = fopen(fullfile(dirRes,'G5_metricas.csv'),'w');
fprintf(fid, 'senal,max_abs_dif,rmse,iguales,n\n');
for j = 1:10, fprintf(fid, '%s,%.6g,%.6g,%d,%d\n', nombres{j}, M(j,:), n); end
fclose(fid);
save(fullfile(dirRes,'G5_resultados.mat'), 'D', 'M', 'nombres', 't', 'cic', 'okCtrl', 'tol');

fig = figure('Visible','off','Position',[100 100 900 600]);
for j = 1:4
    subplot(2,2,j);  stairs(t, D.PIL(:,j) - D.Normal(:,j));  grid on;
    title(['PIL - Normal: ' nombres{j}]);  xlabel('t [s]');  ylabel('rad');
end
exportgraphics(fig, fullfile(dirRes,'G5_diferencias.png'), 'Resolution', 150);
fprintf('\nCriterio (max|dif| <= %.0e en th e I, 0 en saturado): %s\nFIN G5\n', tol, pasa_falla(okCtrl));
