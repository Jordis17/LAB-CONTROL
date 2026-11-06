%% ETAPA G - SCRIPT 0c: DIAGNOSTICO 2 DEL PIL CON LA ESP32 (no simula)
% G0b mostro que codertarget.arduinobase.board.GetBoard falla con "Index
% exceeds array bounds" para las ESP32 (y no para Due/Mega/Uno/Teensy, que
% tienen IsPilSupported = true). Este script busca si existe una clase de
% placa ESP32 con informacion de PIL y como esta hecha la conexion PIL del
% paquete, para decidir si se puede reutilizar o hay que escribir una propia.
% Salida: resultados/G0c_consola.txt

clearvars; clc;
carpeta = fileparts(mfilename('fullpath'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G0c_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G0c_diagnostico_PIL_ESP32   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
raiz = matlabshared.supportpkg.getSupportPackageRoot;

%% 0. Variante de la ESP32 y GetBoard despues de elegirla
addpath(fullfile(carpeta,'funciones'), fullfile(fileparts(carpeta),'etapaE'));
init_Controller_BoP();
mdl = 'Controller_BoP_ESP32';
load_system(fullfile(carpeta,[mdl '.slx']));
set_param(0, 'CurrentSystem', mdl);
mostrar('codertarget.arduinobase.registry.getESP32SupportedBoards');
g_variante_esp32(mdl, 'ESP32-WROOM', 'Dev Module');
try
    b = codertarget.arduinobase.board.GetBoard('boardName', 'ESP32-WROOM (Arduino Compatible)');
    fprintf('GetBoard despues de elegir la variante: OK (%s)\n', class(b));
    if isprop(b,'boardInfo'), disp(b.boardInfo); end
    if isprop(b,'boardInfo') && isprop(b.boardInfo,'IsPilSupported')
        fprintf('IsPilSupported = %s\n', mat2str(b.boardInfo.IsPilSupported));
    end
catch e
    fprintf('GetBoard despues de elegir la variante: ERROR\n%s\n', e.getReport('extended','hyperlinks','off'));
end

%% 1. GetBoard y las clases de placas
mostrar('codertarget.arduinobase.board.GetBoard');
for p = {'codertarget.arduinobase.board', 'codertarget.arduinotarget.board', 'codertarget.esp32.board'}
    m = meta.package.fromName(p{1});
    if isempty(m), fprintf('\nPaquete %s: no existe\n', p{1}); continue; end
    fprintf('\nClases en %s:\n', p{1});
    fprintf('  %s\n', m.ClassList.Name);
    fprintf('Funciones: %s\n', strjoin({m.FunctionList.Name}, ', '));
end
[~, t] = system(sprintf('find "%s" -ipath "*board*" -iname "*esp32*" 2>/dev/null | head -40', raiz));
fprintf('\nArchivos de placa con ESP32 en el nombre:\n%s\n', t);

%% 2. Nombres alternativos en GetBoard
fprintf('\nGetBoard con otros nombres:\n');
for n = {'ESP32-WROOM','ESP32','ESP32 Dev Module','esp32','ESP32WROOM','ESP32-WROOM-DevKitC'}
    try
        b = codertarget.arduinobase.board.GetBoard('boardName', n{1});
        fprintf('  %-22s -> %s (numel %d)\n', n{1}, class(b), numel(b));
    catch e
        fprintf('  %-22s -> ERROR: %s\n', n{1}, e.message);
    end
end

%% 3. La conexion PIL del paquete
mostrar('codertarget.arduinotarget.pil.ConnectivityConfig');
m = meta.package.fromName('codertarget.arduinotarget.pil');
if ~isempty(m)
    fprintf('\nClases en codertarget.arduinotarget.pil: %s\n', strjoin({m.ClassList.Name}, ', '));
    for i = 1:numel(m.ClassList), mostrar(m.ClassList(i).Name); end
end

%% 4. rtiostream del lado de la placa (lo que corre en la ESP32 para PIL)
[~, t] = system(sprintf('grep -rIl -i -e "rtIOStreamOpen" "%s" 2>/dev/null | head -30', raiz));
fprintf('\nArchivos con rtIOStreamOpen:\n%s\n', t);

%% 5. Toolchain ESP32 y herramientas de carga
mostrar('arduinoregistry.registertoolchain');
[~, t] = system(sprintf('find "%s" -iname "esptool*" 2>/dev/null | head -10', raiz));
fprintf('\nesptool:\n%s\n', t);
[~, t] = system(sprintf('find "%s" -iname "arduino-cli*" 2>/dev/null | head -5', raiz));
fprintf('arduino-cli:\n%s\n', t);
fprintf('FIN G0c\n');

function mostrar(nombre)
    w = which(nombre);
    fprintf('\n----- which %s: %s -----\n', nombre, w);
    if ~isempty(w) && endsWith(w, '.m'), fprintf('%s\n', fileread(w)); end
end
