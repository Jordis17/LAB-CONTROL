%% ETAPA B - SCRIPT 1: IDENTIFICACION DE LA RODADURA (ENSAYOS B1)
% Ensayo B1 (instructivo, Parte 4): plato inclinado a un angulo fijo con el
% sketch prueba_servos, bola soltada desde el reposo, main_vision.py --no-serial
% registrando. Con el plato fijo, la Etapa A da
%       xdd = -c*g*sin(th)                       (sin friccion)
%       xdd = -c*g*sin(th) - f*sign(xd)          (con friccion de rodadura f)
% asi que cada ensayo da una aceleracion constante. En magnitud (la bola
% siempre rueda cuesta abajo):  |a| = c*g*|sin th| - f.
%
% Pasos:
%   1. Para cada ensayo se toma el tramo de rodadura libre (b_segmento_rodadura),
%      se corrige el efecto de la inclinacion sobre la camara
%      (b_corregir_inclinacion, modelo de medicion de la Etapa A) y se ajusta
%      una parabola: de ahi sale la aceleracion a.
%   2. IDENTIFICACION con las repeticiones 1 y 2: minimos cuadrados de
%      |a| = c*g*|sin th| - f. Dos modelos candidatos: M1 (solo c, f = 0) y
%      M2 (c y f).
%   3. VALIDACION con la repeticion 3 (datos que no se usaron para identificar):
%      se predice la trayectoria con cada modelo desde las condiciones iniciales
%      medidas y se reportan RMSE, MAE, sesgo, R2, FIT y la estructura temporal
%      del residuo. Tambien se evalua el valor nominal c = 5/7.
%   4. El modelo nominal se elige por la validacion (no se promedian modelos).
%
% Datos: datos_prototipo/etapaB/ensayos.csv (ver funciones/leer_ensayos.m) y los
% CSV de main_vision.py en la misma carpeta.
% Salidas (resultados/): B1_consola.txt, B1_ensayos.csv, B1_modelos.csv,
%   B1_validacion_modelo<m>_<archivo>.csv (m: 1 nominal, 2 M1, 3 M2), B1_resultados.mat

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'B1_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA B - B1_identificar_rodadura_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('Version: %s\n', version);

P = A0_parametros_BoP();
dirDatos = fullfile(raiz,'datos_prototipo','etapaB');
if ~isempty(getenv('BOP_DATOS_ETAPAB')), dirDatos = getenv('BOP_DATOS_ETAPAB'); end   % solo para pruebas del script
E = leer_ensayos(fullfile(dirDatos,'ensayos.csv'));
E = E(strcmp({E.ensayo},'B1'));
fprintf('Ensayos B1 en ensayos.csv: %d\n', numel(E));
if isempty(E), error('B1:SinEnsayos','No hay filas B1 en ensayos.csv.'); end

% Criterios fijos del tramo de rodadura
x_lim = 115;      % mm: no usar puntos a menos de ~12 mm del borde (127)
n_salto = 3;      % cuadros descartados tras la suelta
g = P.g;

%% 1. Aceleracion de cada ensayo
fprintf('\n=== 1. Aceleracion por ensayo (tramo de rodadura libre, corregido por inclinacion) ===\n');
fprintf('  archivo                              eje rep  cmd  |th|[deg]  n   a_cruda[mm/s2]  a_corr[mm/s2]  rms[mm]\n');
T = [];  seg = cell(numel(E),1);
for i = 1:numel(E)
    L = leer_log_vision(fullfile(dirDatos, E(i).archivo));
    if strcmp(E(i).eje,'X'), p = L.x_raw; else, p = L.y_raw; end
    S = b_segmento_rodadura(L.t, p, x_lim, n_salto);
    if ~S.ok
        fprintf('  %-36s %s   %d  DESCARTADO: %s\n', E(i).archivo, E(i).eje, E(i).repeticion, S.motivo);
        continue
    end
    thm = deg2rad(abs(E(i).th_app_deg));
    th = -S.sentido*thm;                       % cuesta abajo: la bola va hacia -sign(th)
    x = b_corregir_inclinacion(S.p, th, P);
    A = [ones(size(S.tau)) S.tau 0.5*S.tau.^2];
    cf = A \ x;
    S.x = x;  S.th = th;  S.a_corr = cf(3);  S.x0 = cf(1);  S.v0 = cf(2);
    S.rms_corr = sqrt(mean((x - A*cf).^2));
    seg{i} = S;
    T(end+1,:) = [i (E(i).eje=='X') E(i).repeticion E(i).comando_deg rad2deg(thm) numel(S.idx) S.a S.a_corr S.rms_corr]; %#ok<AGROW>
    fprintf('  %-36s %s   %d  %4.0f  %8.2f  %3d  %12.1f  %12.1f  %8.3f\n', E(i).archivo, E(i).eje, ...
        E(i).repeticion, E(i).comando_deg, rad2deg(thm), numel(S.idx), S.a, S.a_corr, S.rms_corr);
end
if size(T,1) < 2, error('B1:Pocos','Menos de 2 ensayos validos.'); end

%% 2. Identificacion (repeticiones 1 y 2)
fprintf('\n=== 2. Identificacion con las repeticiones 1 y 2 ===\n');
idI = T(:,3) <= 2;  idV = T(:,3) >= 3;
gs = g*sin(deg2rad(T(:,5)));
aa = abs(T(:,8));
nI = sum(idI);
fprintf('  Ensayos de identificacion: %d; de validacion: %d\n', nI, sum(idV));
if nI < 2, error('B1:PocosIdent','Hacen falta al menos 2 ensayos con repeticion 1 o 2.'); end
c_M1 = gs(idI) \ aa(idI);                                  % M1: |a| = c g |sin th|
coefM2 = [gs(idI) -ones(nI,1)] \ aa(idI);                  % M2: |a| = c g |sin th| - f
c_M2 = coefM2(1);  f_M2 = coefM2(2);
fprintf('  M1 (sin friccion):  c = %.4f\n', c_M1);
if numel(unique(round(10*T(idI,5))/10)) >= 2
    fprintf('  M2 (con friccion):  c = %.4f,  f = %.1f mm/s^2\n', c_M2, f_M2);
else
    fprintf('  M2 no identificable: hace falta mas de un angulo distinto.\n');
    c_M2 = NaN;  f_M2 = NaN;
end
fprintf('  Nominal (esfera maciza): c = %.4f;  rango esperado por el relleno: 0,685 a 0,714\n', 5/7);
fprintf('  c por ensayo con M1 (|a|/(g|sin th|)) - si cambia con el angulo, falta la friccion:\n');
ejes = 'YX';
for k = find(idI)'
    fprintf('    %s rep %d, |th| = %5.2f deg: c = %.4f\n', ejes(T(k,2)+1), T(k,3), T(k,5), aa(k)/gs(k));
end

%% 3. Validacion (repeticion 3)
fprintf('\n=== 3. Validacion con la repeticion 3 (datos no usados para identificar) ===\n');
modelos = {'nominal 5/7', 5/7, 0; 'M1', c_M1, 0; 'M2', c_M2, f_M2};
Mv = NaN(size(modelos,1), 7);
if ~any(idV)
    fprintf('  No hay ensayos con repeticion 3: la validacion queda pendiente.\n');
else
    for m = 1:size(modelos,1)
        if isnan(modelos{m,2}), continue; end
        e_all = [];  y_all = [];  yh_all = [];
        for k = find(idV)'
            S = seg{T(k,1)};
            a_pred = -sign(S.th)*(modelos{m,2}*g*abs(sin(S.th)) - modelos{m,3});
            % x0 y v0 de los primeros 6 puntos, descontando la aceleracion que predice
            % el mismo modelo (una recta sobre puntos que ya aceleran sesga v0)
            n0 = min(6, numel(S.tau));
            pf = [ones(n0,1) S.tau(1:n0)] \ (S.x(1:n0) - 0.5*a_pred*S.tau(1:n0).^2);
            xh = pf(1) + pf(2)*S.tau + 0.5*a_pred*S.tau.^2;
            y_all = [y_all; S.x];  yh_all = [yh_all; xh]; %#ok<AGROW>
            escribir_csv(fullfile(dirRes, sprintf('B1_validacion_modelo%d_%s.csv', m, ...
                strrep(E(T(k,1)).archivo,'.csv',''))), {'tau_s','x_med_mm','x_mod_mm','residuo_mm'}, ...
                [S.tau S.x xh S.x - xh]);
        end
        Mm = b_metricas_ajuste(y_all, yh_all);
        Mv(m,:) = [Mm.rmse Mm.mae Mm.sesgo Mm.r2 Mm.fit Mm.acorr1 Mm.tendencia];
        fprintf('  %-12s c = %.4f f = %5.1f | RMSE %.2f mm, MAE %.2f mm, sesgo %+.2f mm, R2 %.4f, FIT %.1f %%, autocorr(1) %.2f, tendencia %+.3f mm/muestra\n', ...
            modelos{m,1}, modelos{m,2}, modelos{m,3}, Mv(m,:));
    end
    fprintf('  Lectura del residuo: autocorrelacion cercana a 1 o tendencia distinta de 0 indican\n');
    fprintf('  que al modelo le falta algo (friccion, angulo mal medido, plato que se mueve).\n');
end

%% Guardado
escribir_csv(fullfile(dirRes,'B1_ensayos.csv'), ...
    {'fila_ensayos','eje_1X_0Y','repeticion','comando_deg','th_abs_deg','n_puntos','a_cruda_mm_s2','a_corr_mm_s2','rms_ajuste_mm'}, T);
escribir_csv(fullfile(dirRes,'B1_modelos.csv'), ...
    {'modelo_1nom_2M1_3M2','c','f_mm_s2','rmse_mm','mae_mm','sesgo_mm','r2','fit_pct','acorr1','tendencia_mm_muestra'}, ...
    [(1:3)' cell2mat(modelos(:,2:3)) Mv]);
B1.T = T;  B1.c_M1 = c_M1;  B1.c_M2 = c_M2;  B1.f_M2 = f_M2;  B1.validacion = Mv;
B1.modelos = modelos;  B1.x_lim = x_lim;  B1.n_salto = n_salto;
B1.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
save(fullfile(dirRes,'B1_resultados.mat'), 'B1');
fprintf('\nResultados en %s\nFIN B1\n', dirRes);
