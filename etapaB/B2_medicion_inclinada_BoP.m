%% ETAPA B - SCRIPT 2: MEDICION DE LA CAMARA CON EL PLATO INCLINADO (ENSAYOS B2)
% Ensayo B2 (instructivo, Parte 4.3): bola quieta apoyada contra un borde; se
% baja ese lado del plato a varios angulos (la bola no se mueve sobre el
% plato) y se registra con main_vision.py --no-serial.
%
% La Etapa A predice que la camara ve una posicion distinta aunque la bola no
% se mueva sobre el plato (bop_medicion; a primer orden Xm = x - h*th). Este
% script:
%   1. Promedia la posicion medida en cada ensayo.
%   2. Compara el cambio medido respecto del ensayo con el plato horizontal
%      contra el que predice el modelo con la altura de diseno (h_sup = 49 mm).
%   3. Identifica h_sup (altura de la cara superior del plato sobre el centro
%      de la junta, el dato geometrico mas incierto) por minimos cuadrados.
%
% Posicion de la bola contra el borde, en el marco del plato: 150 - 3 - 20 = 127 mm.
% Signo: con la bola contra el borde +X, ese lado baja, asi que th < 0.
% Datos: datos_prototipo/etapaB/ensayos.csv (filas B2) y sus CSV.
% Salidas (resultados/): B2_consola.txt, B2_ensayos.csv, B2_resultados.mat

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'B2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA B - B2_medicion_inclinada_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
P = A0_parametros_BoP();
dirDatos = fullfile(raiz,'datos_prototipo','etapaB');
if ~isempty(getenv('BOP_DATOS_ETAPAB')), dirDatos = getenv('BOP_DATOS_ETAPAB'); end   % solo para pruebas del script
E = leer_ensayos(fullfile(dirDatos,'ensayos.csv'));
E = E(strcmp({E.ensayo},'B2'));
fprintf('Ensayos B2: %d\n', numel(E));
if isempty(E), error('B2:SinEnsayos','No hay filas B2 en ensayos.csv.'); end
x_borde = 127;

%% 1. Posicion media de cada ensayo
T = NaN(numel(E), 7);   % eje(1=X) borde(+1/-1) th[rad con signo] Xm_media std n detectadas
for i = 1:numel(E)
    L = leer_log_vision(fullfile(dirDatos, E(i).archivo));
    if strcmp(E(i).eje,'X'), p = L.x_raw; else, p = L.y_raw; end
    p = p(~isnan(p));
    sb = 1 - 2*(E(i).borde(1) == '-');
    th = -sb*deg2rad(abs(E(i).th_app_deg));
    T(i,:) = [strcmp(E(i).eje,'X') sb th mean(p) std(p) numel(p) E(i).comando_deg];
    fprintf('  %-34s eje %s borde %s  th = %+6.2f deg  Xm = %8.2f mm (std %.2f, n = %d)\n', E(i).archivo, ...
        E(i).eje, E(i).borde, rad2deg(th), mean(p), std(p), numel(p));
end

%% 2-3. Cambio respecto del plato horizontal e identificacion de h_sup
fprintf('\n=== Cambio de la medicion respecto del ensayo con menor inclinacion de cada borde ===\n');
grupos = unique(T(:,1:2), 'rows');
filas = [];
for gI = 1:size(grupos,1)
    sel = find(T(:,1) == grupos(gI,1) & T(:,2) == grupos(gI,2));
    [~, iref] = min(abs(T(sel,3)));  ref = sel(iref);
    for k = sel(:)'
        if k == ref, continue; end
        filas(end+1,:) = [k ref T(k,3) T(ref,3) grupos(gI,2) T(k,4) - T(ref,4)]; %#ok<AGROW>
    end
end
if isempty(filas), error('B2:SinPares','Cada borde necesita al menos dos angulos.'); end
pred = @(hs, th, sb) b_prediccion_borde(hs, th, sb*x_borde, P);
dpred = @(hs) arrayfun(@(j) pred(hs, filas(j,3), filas(j,5)) - pred(hs, filas(j,4), filas(j,5)), (1:size(filas,1))');
J = @(hs) sum((filas(:,6) - dpred(hs)).^2);
hs_id = fminbnd(J, 0, 120);
d49 = dpred(P.h_sup);  dId = dpred(hs_id);
fprintf('  ensayo   th[deg]  th_ref[deg]  dXm medido  dXm modelo(h_sup=%.0f)  dXm modelo(h_sup=%.1f)\n', P.h_sup, hs_id);
for j = 1:size(filas,1)
    fprintf('  %4d   %7.2f   %8.2f   %9.2f   %14.2f   %18.2f\n', filas(j,1), rad2deg(filas(j,3)), ...
        rad2deg(filas(j,4)), filas(j,6), d49(j), dId(j));
end
fprintf('\n  h_sup identificado = %.1f mm (diseno: %.1f mm)\n', hs_id, P.h_sup);
fprintf('  RMS del error: con diseno %.2f mm, con h_sup identificado %.2f mm (%d pares)\n', ...
    sqrt(mean((filas(:,6)-d49).^2)), sqrt(mean((filas(:,6)-dId).^2)), size(filas,1));
fprintf('  Si el error con h_sup identificado sigue grande o tiene patron con el angulo, el modelo\n');
fprintf('  de medicion no explica los datos (camara no centrada, pivote desplazado, calibracion).\n');

escribir_csv(fullfile(dirRes,'B2_ensayos.csv'), ...
    {'fila','fila_ref','th_deg','th_ref_deg','borde','dXm_medido_mm','dXm_modelo_diseno_mm','dXm_modelo_ident_mm'}, ...
    [filas(:,1:2) rad2deg(filas(:,3:4)) filas(:,5:6) d49 dId]);
B2.T = T;  B2.pares = filas;  B2.h_sup_ident = hs_id;  B2.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
save(fullfile(dirRes,'B2_resultados.mat'), 'B2');
fprintf('FIN B2\n');
