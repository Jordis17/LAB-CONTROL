%% ETAPA G - SCRIPT 0b: DIAGNOSTICO DEL PIL CON LA ESP32 (no simula)
% G0 fallo porque la configuracion de conexion PIL "Arduino Board" del paquete
% (arduinoregistry/registerpil.m) dio "Index exceeds array bounds" al revisar
% si el modelo es compatible. Ese chequeo depende de boardInfo.IsPilSupported
% de la placa elegida. Este script:
%   1. muestra registerpil.m completo;
%   2. ejecuta el chequeo de compatibilidad sobre Controller_BoP_ESP32 y, si
%      falla, imprime el error con la pila completa (archivo y linea);
%   3. muestra la informacion de la placa (boardInfo) e IsPilSupported;
%   4. compara IsPilSupported en varias placas del paquete;
%   5. busca los valores posibles de ESP32_board (variante, salio vacio).
% Requisito: haber corrido G0 (crea Controller_BoP_ESP32.slx).
% Salida: resultados/G0b_consola.txt

clearvars; clc;
carpeta = fileparts(mfilename('fullpath'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G0b_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G0b_diagnostico_PIL_ESP32   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

addpath(fullfile(fileparts(carpeta),'etapaE'));
init_Controller_BoP();
mdl = 'Controller_BoP_ESP32';
load_system(fullfile(carpeta,[mdl '.slx']));
cs = getActiveConfigSet(mdl);
ctd = get_param(cs,'CoderTargetData');
fprintf('TargetHardware = %s\n', ctd.TargetHardware);

%% 1. registerpil.m
f = which('arduinoregistry.registerpil');
fprintf('\n===== 1. %s =====\n', f);
if ~isempty(f), fprintf('%s\n', fileread(f)); end

%% 2. Chequeo de compatibilidad del registro PIL
fprintf('\n===== 2. isConfigSetCompatibleFcn sobre %s =====\n', mdl);
try
    cfg = arduinoregistry.registerpil();
    for i = 1:numel(cfg)
        fprintf('Config %d: %s\n', i, cfg(i).ConfigName);
        try
            r = cfg(i).isConfigSetCompatibleFcn(cs);
            fprintf('  compatible = %d\n', r);
        catch e
            fprintf('  ERROR:\n%s\n', e.getReport('extended','hyperlinks','off'));
        end
    end
catch e
    fprintf('No se pudo llamar registerpil:\n%s\n', e.getReport('extended','hyperlinks','off'));
end

%% 3. Informacion de la placa elegida
fprintf('\n===== 3. GetBoard(''%s'') =====\n', ctd.TargetHardware);
try
    b = codertarget.arduinobase.board.GetBoard('boardName', ctd.TargetHardware);
    fprintf('clase: %s, numel: %d\n', class(b), numel(b));
    if ~isempty(b)
        disp(b(1));
        if isprop(b(1),'boardInfo'), disp(b(1).boardInfo); end
    end
catch e
    fprintf('ERROR:\n%s\n', e.getReport('extended','hyperlinks','off'));
end

%% 4. IsPilSupported en varias placas
fprintf('\n===== 4. IsPilSupported por placa =====\n');
placas = {'Arduino Due','Arduino Mega 2560','Arduino Uno','Arduino Nano 33 IoT', ...
          'ESP32-WROOM (Arduino Compatible)','ESP32-WROVER (Arduino Compatible)', ...
          'Raspberry Pi Pico (Arduino Compatible)','Teensy 4.1 (Arduino Compatible)'};
for i = 1:numel(placas)
    try
        b = codertarget.arduinobase.board.GetBoard('boardName', placas{i});
        v = '(sin boardInfo)';
        if ~isempty(b) && isprop(b(1),'boardInfo')
            v = '(sin IsPilSupported)';
            if isprop(b(1).boardInfo,'IsPilSupported'), v = mat2str(b(1).boardInfo.IsPilSupported); end
        end
        fprintf('  %-42s %s\n', placas{i}, v);
    catch e
        fprintf('  %-42s ERROR: %s\n', placas{i}, e.message);
    end
end

%% 5. Valores posibles de ESP32_board
fprintf('\n===== 5. Donde se define ESP32_board =====\n');
raiz = matlabshared.supportpkg.getSupportPackageRoot;
[~, t] = system(sprintf('grep -rIn -e "ESP32_board" "%s" 2>/dev/null | head -30', raiz));
fprintf('%s\n', t);
[~, t] = system(sprintf('grep -rIn -i -e "IsPilSupported" "%s" 2>/dev/null | head -30', raiz));
fprintf('Donde aparece IsPilSupported:\n%s\n', t);
fprintf('FIN G0b\n');
