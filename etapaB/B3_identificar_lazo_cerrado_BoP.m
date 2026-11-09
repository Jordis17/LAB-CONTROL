%% ETAPA B - SCRIPT 3: IDENTIFICACION EN LAZO CERRADO (logs con telemetria)
% Usa los logs de main_vision.py corridos con el firmware
% bop_prueba_circulo_lazo, que devuelve en cada cuadro la inclinacion que la
% ESP32 mando al plato (columnas tel_* del log). Por eje (plato a angulo
% conocido en cada instante, Etapa A):
%       xdd = -c g sin(th(t - tau)) + b - f sign(xd)
%   c    rodadura EFECTIVA: incluye el error de la tabla servo->plato (en lazo
%        cerrado no se pueden separar; B1 si los separa, porque mide el angulo
%        con la app);
%   b    aceleracion constante [mm/s^2]: desnivel del plato (y friccion media);
%        se reporta tambien como desnivel equivalente asin(b/(c g)) [deg];
%   f    rozamiento de rodadura [mm/s^2] (Coulomb, con el signo de la velocidad
%        del Kalman); f / (c g) es la inclinacion minima para que la bola ruede;
%   tau  retardo desde la captura del cuadro hasta que el plato se mueve [s]
%        (calculo, serie, PWM y servo; la latencia de la camara queda fuera
%        porque el log toma el tiempo de la captura).
%
% Metodo: ventanas de 1 s con la bola detectada y lejos del borde. Con tau
% fijo, la posicion es LINEAL en c, b y en la posicion y velocidad iniciales de
% cada ventana: minimos cuadrados (corrigiendo la medicion de la camara con la
% inclinacion, b_corregir_inclinacion). tau se elige en una grilla por el menor
% error. Se descartan las ventanas con una aceleracion medida que el plato no
% puede producir (empujones con la mano, choques, falsas detecciones): ese
% criterio no depende del modelo. IDENTIFICACION con los logs marcados "ident";
% VALIDACION con los marcados "valid" (datos distintos): con x0 y v0 estimados
% en los primeros N_IC cuadros de cada ventana se predice el resto SIN
% reajustar c, b ni tau, y se reportan
% RMSE, MAE, sesgo, R2, FIT y la estructura del residuo, para el modelo
% identificado y para el nominal (c = 5/7, b = 0, tau = 75 ms).
%
% Datos: datos_prototipo/etapaB/lazo_cerrado.csv con columnas
%   archivo,uso,observaciones     (uso: ident o valid)
% y los logs en datos_prototipo/etapaB/.
% Salidas (resultados/): B3_consola.txt, B3_tau.csv, B3_modelos.csv,
%   B3_validacion.csv, B3_resultados.mat, B3_tau.png

clearvars; close all; clc;
SIGNO_VIS = [1 1];           % igual que en el firmware (x_plato = signo * x_vision)
W = 1.0;                     % s por ventana
BORDE = 110;                 % mm: se descartan ventanas con la bola mas afuera (choque con el borde)
A_MAX = 2500;                % mm/s^2: aceleracion medida (segunda diferencia de x_raw) que el plato
                             % no puede producir (c g sin 11 deg ~ 1400): mano, choque o falsa deteccion
N_IC = 6;                    % cuadros al inicio de cada ventana de validacion para estimar x0 y v0
MOV_MIN = 15;                % mm: recorrido minimo de la bola en la ventana (en algun eje); con la
                             % bola quieta c no se puede estimar (log 2026-11-09: daba c < 0 en Y)
taus = -0.040:0.010:0.500;   % s, grilla del retardo (puede ser algo negativo: la orden
                             % se aplica antes de que la PC reciba la telemetria)
dtf = 1e-3;                  % s, paso de integracion

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'B3_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA B - B3_identificar_lazo_cerrado_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
P = A0_parametros_BoP();

%% 1. Logs y ventanas
dirDat = getenv('B3_DATOS');          % (solo para pruebas con datos sinteticos)
if isempty(dirDat), dirDat = fullfile(raiz,'datos_prototipo','etapaB'); end
lista = fullfile(dirDat,'lazo_cerrado.csv');
fid = fopen(lista);  if fid < 0, error('B3:Lista','Falta %s', lista); end
fgetl(fid);  E = struct('archivo',{},'uso',{});
while true
    l = fgetl(fid);  if ~ischar(l), break; end
    c = strsplit(strtrim(l), ',');  if numel(c) < 2 || isempty(c{1}), continue; end
    E(end+1).archivo = strtrim(c{1});  E(end).uso = lower(strtrim(c{2})); %#ok<SAGROW>
end
fclose(fid);
D = struct('L',{},'th',{},'uso',{},'win',{},'nombre',{});
fprintf('\nLogs:\n');
for i = 1:numel(E)
    L = leer_log_vision(fullfile(dirDat, E(i).archivo));
    if ~isfield(L,'tel_thx') || all(isnan(L.tel_thx))
        fprintf('  %-32s SIN telemetria (firmware sin tel_*): se descarta\n', E(i).archivo);  continue
    end
    [th, atraso, coinc] = b3_alinear_telemetria(L);
    t = L.t - L.t(1);
    nw = round(W/median(diff(t)));
    % aceleracion medida por segunda diferencia (independiente del modelo), sobre
    % la posicion corregida por la inclinacion: cuando el plato gira rapido la
    % camara ve moverse la bola aunque no se mueva sobre el plato (paralaje).
    % Inclinacion aproximada en cada cuadro: la ultima orden recibida.
    thc = deg2rad(th);  thc(isnan(thc)) = 0;
    xc = b_corregir_inclinacion(SIGNO_VIS(1)*L.x_raw, thc(:,1), P);
    yc = b_corregir_inclinacion(SIGNO_VIS(2)*L.y_raw, thc(:,2), P);
    acc = zeros(L.n, 1);
    for q = 2:L.n-1
        h1 = t(q) - t(q-1);  h2 = t(q+1) - t(q);
        ax = 2*((xc(q+1)-xc(q))/h2 - (xc(q)-xc(q-1))/h1)/(h1+h2);
        ay = 2*((yc(q+1)-yc(q))/h2 - (yc(q)-yc(q-1))/h1)/(h1+h2);
        acc(q) = max(abs(ax), abs(ay));
    end
    acc(isnan(acc)) = Inf;
    n_mano = sum(acc(2:end-1) > A_MAX);
    win = zeros(0,2);  k = 1;
    while k + nw - 1 <= L.n - 3
        r = k:(k+nw-1);
        ok = all(L.detectada(r) == 1) && all(~isnan(th(max(1,r(1)-12):r(end),1))) && ...
             all(abs(L.x_raw(r)) < BORDE) && all(abs(L.y_raw(r)) < BORDE);
        if ok && any(acc(max(2,r(1)-2):r(end)) > A_MAX), ok = false; end
        if ok && max(max(L.x_raw(r)) - min(L.x_raw(r)), max(L.y_raw(r)) - min(L.y_raw(r))) < MOV_MIN, ok = false; end
        if ok, win(end+1,:) = [r(1) r(end)]; k = k + nw; else, k = k + 1; end %#ok<AGROW>
    end
    D(end+1) = struct('L',L,'th',th,'uso',E(i).uso,'win',win,'nombre',E(i).archivo); %#ok<SAGROW>
    fprintf('  %-32s %-5s %5d cuadros, %d ventanas, th: %.1f a %.1f deg\n', ...
        E(i).archivo, E(i).uso, L.n, size(win,1), min(th(:)), max(th(:)));
    fprintf('    atraso de los datos con que trabajo la ESP32 (eco de x, bola en movimiento): %g cuadros (%.0f %% de ecos encontrados)\n', atraso, 100*coinc);
    if atraso > 2
        fprintf('    AVISO: la ESP32 trabajo con datos atrasados %g cuadros (~%.0f ms): problema de comunicacion, no de la planta.\n', atraso, 1000*atraso*median(diff(t)));
    end
    fprintf('    cuadros con aceleracion medida > %g mm/s^2 (mano, choque o falsa deteccion): %d; sus ventanas se descartan\n', A_MAX, n_mano);
end
id = find(strcmp({D.uso}, 'ident'));  va = find(strcmp({D.uso}, 'valid'));
if isempty(id), error('B3:SinIdent','No hay logs "ident" con telemetria.'); end
nwin = sum(arrayfun(@(d) size(D(d).win,1), id));
if nwin < 10
    fprintf(['\nDATOS INSUFICIENTES: solo %d ventanas utiles en los logs "ident" (minimo 10).\n' ...
             'Hace falta mas tiempo con la bola rodando lejos del borde (circulos, empujones suaves).\n' ...
             'No se reportan parametros para no dar numeros sin respaldo.\nFIN B3\n'], nwin);
    return
end

%% 2. Identificacion: grilla en tau, minimos cuadrados en c, b y condiciones iniciales
sse = zeros(numel(taus), 2);  par = zeros(numel(taus), 2, 3);  nobs = 0;
for it = 1:numel(taus)
    for e = 1:2
        bloques = {};
        for d = id
            L = D(d).L;  t = L.t - L.t(1);
            if e == 2, xm = L.y_raw; vk = L.vy; else, xm = L.x_raw; vk = L.vx; end
            for w = 1:size(D(d).win,1)
                [Phi, xr] = b3_regresores(t, xm, D(d).th(:,e), taus(it), D(d).win(w,1), D(d).win(w,2), P, SIGNO_VIS(e), dtf, vk);
                bloques{end+1} = {Phi, xr}; %#ok<SAGROW>
            end
        end
        nb = numel(bloques);  m = sum(cellfun(@(q) size(q{1},1), bloques));
        A = zeros(m, 3 + 2*nb);  y = zeros(m,1);  f = 0;
        for q = 1:nb
            Phi = bloques{q}{1};  r = f + (1:size(Phi,1));
            A(r,[1 2 3]) = Phi(:,[1 2 5]);  A(r, 3+2*q-1:3+2*q) = Phi(:,3:4);  y(r) = bloques{q}{2};
            f = r(end);
        end
        p = A\y;
        sse(it,e) = sum((y - A*p).^2);  par(it,e,:) = p(1:3);  nobs = m;
    end
end
% tau comun a los dos ejes (es el mismo lazo): se minimiza la suma de los SSE
% normalizados por el minimo de cada eje, para que un eje no pese mas solo por
% tener mas movimiento. Tambien se informa el optimo de cada eje por separado.
[~, ibx] = min(sse(:,1));  [~, iby] = min(sse(:,2));
[~, ib] = min(sse(:,1)/sse(ibx,1) + sse(:,2)/sse(iby,2));
tau = taus(ib);  cI = squeeze(par(ib,:,1));  bI = squeeze(par(ib,:,2));  fI = squeeze(par(ib,:,3));
fprintf('\nIdentificacion (%d muestras por eje en ventanas de %.1f s):\n', nobs, W);
fprintf('  tau = %.0f ms comun (optimo por eje: X %.0f ms, Y %.0f ms; grilla %.0f a %.0f ms)\n', ...
    1000*tau, 1000*taus(ibx), 1000*taus(iby), 1000*taus(1), 1000*taus(end));
if abs(taus(ibx) - taus(iby)) > 0.04
    fprintf('  AVISO: los ejes dan retardos distintos en mas de 40 ms: tau es poco preciso con estos datos.\n');
end
if ib == 1 || ib == numel(taus), fprintf('  AVISO: tau quedo en el extremo de la grilla.\n'); end
ej = 'XY';
for e = 1:2
    fprintf('  eje %s: c = %.4f (nominal 5/7 = %.4f), b = %+.1f mm/s^2 -> desnivel equivalente %+.2f deg, f = %.1f mm/s^2 -> inclinacion minima para rodar %.2f deg, RMSE de ajuste %.2f mm\n', ...
        ej(e), cI(e), 5/7, bI(e), rad2deg(asin(bI(e)/(cI(e)*P.g))), fI(e), rad2deg(asin(min(1, max(-1, fI(e)/(cI(e)*P.g))))), sqrt(sse(ib,e)/nobs));
end
fid = fopen(fullfile(dirRes,'B3_tau.csv'),'w');  fprintf(fid,'tau_s,sse_x,sse_y,c_x,c_y,b_x,b_y,f_x,f_y\n');
for it = 1:numel(taus), fprintf(fid,'%.3f,%.6g,%.6g,%.6g,%.6g,%.6g,%.6g,%.6g,%.6g\n', taus(it), sse(it,:), par(it,:,1), par(it,:,2), par(it,:,3)); end
fclose(fid);

%% 3. Validacion: prediccion de 1 s desde el Kalman, sin reajustar
modelos = {'identificado', cI, bI, tau, fI;  'nominal', [5 5]/7, [0 0], 0.075, [0 0]};
R = [];  Mval = {};
if isempty(va)
    fprintf('\nAVISO: no hay logs "valid": falta la validacion con datos distintos.\n');
else
    fprintf('\nValidacion (logs "valid"): x0 y v0 con los primeros %d cuadros de cada ventana y prediccion del resto (%.2f s) sin reajustar:\n', N_IC, W - N_IC/30);
    for m = 1:size(modelos,1)
        for e = 1:2
            yv = [];  yh = [];
            for d = va
                L = D(d).L;  t = L.t - L.t(1);
                if e == 1, xm = L.x_raw; vk = L.vx; else, xm = L.y_raw; vk = L.vy; end
                for w = 1:size(D(d).win,1)
                    i0 = D(d).win(w,1);
                    [Phi, xr, tr] = b3_regresores(t, xm, D(d).th(:,e), modelos{m,4}, i0, D(d).win(w,2), P, SIGNO_VIS(e), dtf, vk);
                    % x0 y v0 con los primeros N_IC cuadros (c, b y tau fijos); se predice el resto
                    cb = [modelos{m,2}(e); modelos{m,3}(e)];  fm = modelos{m,5}(e);
                    ic = Phi(1:N_IC,3:4) \ (xr(1:N_IC) - Phi(1:N_IC,1:2)*cb - Phi(1:N_IC,5)*fm);
                    pred = Phi*[cb; ic; fm];
                    q = (N_IC+1):numel(xr);
                    tr = tr(q);  xr = xr(q);  pred = pred(q);
                    yv = [yv; xr];  yh = [yh; pred]; %#ok<AGROW>
                    nr = numel(tr);
                    R = [R; repmat([d w e m], nr, 1) tr xr pred]; %#ok<AGROW>
                end
            end
            M = b_metricas_ajuste(yv, yh);  Mval{m,e} = M; %#ok<SAGROW>
            fprintf('  %-12s eje %s: RMSE %.2f mm, MAE %.2f, sesgo %+.2f, R2 %.3f, FIT %.1f %%, autocorr(1) %.2f, tendencia %+.3f mm/muestra\n', ...
                modelos{m,1}, ej(e), M.rmse, M.mae, M.sesgo, M.r2, M.fit, M.acorr1, M.tendencia);
        end
    end
    if ~isempty(R), escribir_csv(fullfile(dirRes,'B3_validacion.csv'), {'log','ventana','eje','modelo','t_s','x_med_mm','x_pred_mm'}, R); end
end
fid = fopen(fullfile(dirRes,'B3_modelos.csv'),'w');
fprintf(fid,'modelo,eje,c,b_mm_s2,desnivel_deg,tau_s,f_mm_s2\n');
for m = 1:size(modelos,1), for e = 1:2
    fprintf(fid,'%s,%s,%.6g,%.6g,%.4f,%.3f,%.6g\n', modelos{m,1}, ej(e), modelos{m,2}(e), modelos{m,3}(e), ...
        rad2deg(asin(modelos{m,3}(e)/(modelos{m,2}(e)*P.g))), modelos{m,4}, modelos{m,5}(e));
end, end
fclose(fid);
save(fullfile(dirRes,'B3_resultados.mat'), 'tau', 'cI', 'bI', 'fI', 'taus', 'sse', 'par', 'Mval', 'SIGNO_VIS', 'W');
try
    fig = figure('Visible','off');
    plot(1000*taus, sse(:,1)/sse(ib,1), 1000*taus, sse(:,2)/sse(ib,2));  grid on;
    xlabel('\tau [ms]');  ylabel('SSE / SSE minimo');  legend('X','Y');  title('B3: error de ajuste contra el retardo');
    print(fig, fullfile(dirRes,'B3_tau.png'), '-dpng', '-r120');
catch
    fprintf('(sin grafica: no hay entorno grafico)\n');
end
fprintf('\nNotas: c es la rodadura EFECTIVA (incluye la ganancia real de la tabla servo->plato).\n');
fprintf('Un c negativo en un eje indica el signo de ese eje invertido (SIGNO_VIS o INVERT_Y).\nFIN B3\n');
