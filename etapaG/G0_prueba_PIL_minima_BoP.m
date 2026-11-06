%% ETAPA G - SCRIPT 0: PRUEBA PIL MINIMA EN LA ESP32
% Responde lo que CLAUDE.md dejo pendiente: ¿se puede hacer PIL con la ESP32
% usando el Simulink Support Package for Arduino Hardware?
%
% Pasos:
%   1. Revisa que el paquete de Arduino este instalado.
%   2. Copia Controller_BoP.slx (referencia intocable) como
%      Controller_BoP_ESP32.slx y en la COPIA cambia solo la placa (Hardware
%      board = ESP32). El algoritmo y los parametros no cambian.
%   3. Ejecuta la copia en modo PIL (el codigo corre EN LA ESP32; las entradas
%      llegan desde Simulink por el puerto serie) con las entradas de dos
%      ensayos del MIL: D1 (requisitos) y D2 (empujon, con 9 cuadros saturados).
%   4. Compara muestra a muestra con el MIL: max|dif|, RMSE e igualdad exacta.
% Criterio PASS: max|dif| <= 1e-12 en th_cmd e I y cero diferencias en saturado.
%
% Requisitos: ESP32 conectada por USB a esta PC (y nada mas usando el puerto:
% cerrar main_vision.py, miniterm y el Monitor Serie del IDE); el usuario en el
% grupo dialout. El paquete de Arduino instalado.
% Salidas: Controller_BoP_ESP32.slx, resultados/G0_consola.txt, G0_resultados.csv

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(raiz,'etapaE'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaC'), fullfile(raiz,'etapaC','funciones'), fullfile(raiz,'etapaD','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G0_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G0_prueba_PIL_minima_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);
tol = 1e-12;

%% 1. Paquete de soporte
try
    sp = matlabshared.supportpkg.getInstalled;
    nombres = {sp.Name};
    fprintf('Paquetes de soporte instalados:\n');
    fprintf('  - %s\n', nombres{:});
    if ~any(contains(nombres, 'Arduino'))
        error('G0:SinArduino', 'No aparece el Simulink Support Package for Arduino Hardware.');
    end
catch err
    if strcmp(err.identifier, 'G0:SinArduino'), rethrow(err); end
    fprintf('AVISO: no se pudo listar los paquetes (%s). Se sigue igual.\n', err.message);
end

%% 2. Copia para la ESP32
orig = fullfile(raiz,'etapaE','Controller_BoP.slx');
mdl = 'Controller_BoP_ESP32';
archivo = fullfile(carpeta, [mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl, 0); end
copyfile(orig, archivo, 'f');
fprintf('\nCopia: %s -> %s\n', orig, archivo);
init_Controller_BoP();
load_system(archivo);

candidatas = {'ESP32-WROOM (Arduino Compatible)', 'ESP32-WROOM-DevKitC (Arduino Compatible)', ...
              'ESP32-WROOM', 'ESP32 (Arduino Compatible)', 'ESP32'};
placa = '';
for i = 1:numel(candidatas)
    try
        set_param(mdl, 'HardwareBoard', candidatas{i});
        placa = candidatas{i};
        break
    catch
    end
end
if isempty(placa)
    error('G0:Placa', ['No se reconocio ninguna placa ESP32 (%s). Abran Controller_BoP_ESP32.slx, ' ...
        'Modeling > Model Settings > Hardware Implementation > Hardware board, y manden la lista ' ...
        'de placas que ofrece.'], strjoin(candidatas, ', '));
end
fprintf('Hardware board: %s\n', placa);
cfgs = {'ProdHWDeviceType','ProdBitPerInt','ProdBitPerLong','ProdBitPerDouble','ProdEndianess', ...
        'ProdIntDivRoundTo','SystemTargetFile','CodeInterfacePackaging'};
for i = 1:numel(cfgs)
    try
        v = get_param(mdl, cfgs{i});
        if isnumeric(v), v = num2str(v); end
        fprintf('  %-22s %s\n', cfgs{i}, v);
    catch
    end
end
set_param(mdl, 'Description', ['Copia de Controller_BoP (etapaE) solo para PIL en la ESP32. ' ...
    'Mismo algoritmo y parametros; cambia la placa en la configuracion.']);
save_system(mdl);

%% 3. Entradas de prueba (MIL)
S = load(fullfile(raiz,'etapaC','resultados','C1_controlador.mat'));
C = S.Ctrl;  P = A0_parametros_BoP();
base = bop_mil_config(P, C);
base.kalman_sigma_a = C.kalman_sigma_a;  base.kalman_sigma_m = C.kalman_sigma_m;
base.omega_n_servo = C.omega_n_servo;
casos = {'D1_requisitos', setfield(setfield(base,'x0',[100;0]),'T_fin',6.5); ...
         'D2_sat_con_AW', setfield(setfield(setfield(setfield(setfield(base,'v0',[420;0]), ...
              'th_dist',[deg2rad(1);0]),'t_espera',0),'T_fin',6),'usar_aw',true)};

%% 4. Simulacion PIL y comparacion
dirBuild = fullfile(carpeta,'build');
if ~isfolder(dirBuild), mkdir(dirBuild); end
Simulink.fileGenControl('set', 'CodeGenFolder', dirBuild, 'CacheFolder', dirBuild, 'createDir', true);
restaurar = onCleanup(@() Simulink.fileGenControl('reset'));
dirAntes = pwd;  cd(dirBuild);  volver = onCleanup(@() cd(dirAntes));

Ts = evalin('base','Ts_ctrl');
res = zeros(size(casos,1), 6);
for k = 1:size(casos,1)
    R = bop_mil_simular(casos{k,2});
    n = numel(R.k_tcap);
    t = (0:n-1)'*Ts;
    hab = R.k_tcap >= casos{k,2}.t_espera - 1e-9;
    ds = Simulink.SimulationData.Dataset;
    ds = ds.addElement(timeseries(R.k_r(:,1),  t), 'r_mm');
    ds = ds.addElement(timeseries(R.k_xh(:,1), t), 'x_hat_mm');
    ds = ds.addElement(timeseries(R.k_vh(:,1), t), 'v_hat_mm_s');
    ds = ds.addElement(timeseries(logical(hab), t), 'habilitado');
    in = Simulink.SimulationInput(mdl);
    in = in.setExternalInput(ds);
    in = in.setModelParameter('StopTime', sprintf('%.17g', t(end)), ...
                              'SimulationMode', 'processor-in-the-loop (pil)');
    fprintf('\n%s: %d cuadros, %d saturados en el MIL. Ejecutando en la ESP32 (compila y carga la primera vez)...\n', ...
        casos{k,1}, n, sum(R.k_sat(:,1)));
    out = sim(in);
    y = out.yout;
    th  = squeeze(double(y.getElement(1).Values.Data));
    I   = squeeze(double(y.getElement(2).Values.Data));
    sat = squeeze(logical(y.getElement(3).Values.Data));
    if numel(th) ~= n
        error('G0:Muestras','%s: el PIL devolvio %d muestras y el MIL %d.', casos{k,1}, numel(th), n);
    end
    dth = th - R.k_th(:,1);  dI = I - R.k_I(:,1);
    res(k,:) = [max(abs(dth)) rmse_v(dth) isequal(th, R.k_th(:,1)) max(abs(dI)) rmse_v(dI) sum(sat ~= R.k_sat(:,1))];
    fprintf('  th max|dif| = %.3g, RMSE = %.3g, igual = %d | I max|dif| = %.3g | saturado distinto en %d\n', res(k,:));
    escribir_csv(fullfile(dirRes, sprintf('G0_caso_%s.csv', casos{k,1})), ...
        {'k','t_s','r_mm','xh_mm','vh_mm_s','habilitado','th_MIL_rad','th_PIL_rad','dif_th_rad', ...
         'I_MIL_rad','I_PIL_rad','dif_I_rad','sat_MIL','sat_PIL'}, ...
        [(0:n-1)' t R.k_r(:,1) R.k_xh(:,1) R.k_vh(:,1) double(hab) R.k_th(:,1) th dth R.k_I(:,1) I dI double(R.k_sat(:,1)) double(sat)]);
end
ok = all(res(:,1) <= tol & res(:,4) <= tol & res(:,6) == 0);
fid = fopen(fullfile(dirRes,'G0_resultados.csv'),'w');
fprintf(fid, 'caso,th_maxdif,th_rmse,th_igual,I_maxdif,I_rmse,sat_distintos\n');
for k = 1:size(casos,1), fprintf(fid, '%s,%.6g,%.6g,%d,%.6g,%.6g,%d\n', casos{k,1}, res(k,:)); end
fclose(fid);
fprintf('\nPlaca: %s\nResultado de la prueba PIL minima: %s (criterio max|dif| <= %.0e)\nFIN G0\n', placa, pasa_falla(ok), tol);
