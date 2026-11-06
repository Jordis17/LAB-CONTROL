%% ETAPA G - SCRIPT 3: PREPARAR EL PIL EN LA ESP32 (ruta propia)
% El PIL de Simulink no se puede usar con la ESP32 (G0, G0b, G0c; ver
% LEEME_etapaG.md). Este script arma la ruta propia:
%   1. Genera el codigo C de Controller_BoP_ESP32.slx (la copia de G0: mismo
%      algoritmo y parametros, placa ESP32) con Embedded Coder, solo codigo.
%   2. Compara ese codigo con el de la Etapa E (etapaE/codigo_generado), salvo
%      el nombre del modelo y los comentarios.
%   3. Copia el codigo al sketch pil_esp32/bop_pil_esp32 (que solo hace de
%      puente serie: recibe entradas, llama _step, devuelve salidas).
%   4. Compila con el arduino-cli del paquete de Arduino (toolchain Xtensa de
%      la ESP32, FQBN esp32:esp32:esp32) y graba la ESP32.
% Requisitos: haber corrido G0 (crea Controller_BoP_ESP32.slx); ESP32 en el
% puerto y nada mas usandolo.
% Salida: resultados/G3_consola.txt

clearvars; close all; clc;
puerto = '/dev/ttyUSB0';
fqbn   = 'esp32:esp32:esp32';

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(carpeta,'funciones'), fullfile(raiz,'etapaE'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G3_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G3_preparar_PIL_ESP32_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

%% 1. Codigo generado de la copia para la ESP32
mdl = 'Controller_BoP_ESP32';
archivo = fullfile(carpeta, [mdl '.slx']);
if ~isfile(archivo), error('G3:SinModelo', 'Falta %s: corran primero G0.', archivo); end
init_Controller_BoP();
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(archivo);
fprintf('Placa: %s | %s | %s\n', get_param(mdl,'HardwareBoard'), get_param(mdl,'SystemTargetFile'), ...
    get_param(mdl,'CodeInterfacePackaging'));
set_param(mdl, 'GenCodeOnly', 'on');      % solo codigo: la carga la hace arduino-cli
dirBuild = fullfile(carpeta,'build');
if ~isfolder(dirBuild), mkdir(dirBuild); end
Simulink.fileGenControl('set', 'CodeGenFolder', dirBuild, 'CacheFolder', dirBuild, 'createDir', true);
restaurar = onCleanup(@() Simulink.fileGenControl('reset'));
dirAntes = pwd;  cd(dirBuild);  volver = onCleanup(@() cd(dirAntes));
slbuild(mdl);
cd(dirAntes);
close_system(mdl, 0);                     % sin guardar: GenCodeOnly no queda en el modelo
dirCod = fullfile(dirBuild, [mdl '_ert_rtw']);

%% 2. Comparacion con el codigo de la Etapa E
% Se comparan por separado: (a) el conjunto de #include (el orden puede
% cambiar con la placa) y (b) el resto del codigo, sin comentarios ni el
% nombre del modelo.
tA = strrep(fileread(fullfile(dirCod,[mdl '.c'])), mdl, 'Controller_BoP');
tB = fileread(fullfile(raiz,'etapaE','codigo_generado','Controller_BoP.c'));
incA = sort(regexp(tA, '#include\s*[<"][^>"]+[>"]', 'match'));
incB = sort(regexp(tB, '#include\s*[<"][^>"]+[>"]', 'match'));
norm = @(t) strtrim(regexprep(regexprep(regexprep(regexprep(t, '/\*.*?\*/', ''), '//[^\n]*', ''), ...
    '#include\s*[<"][^>"]+[>"]', ''), '\s+', ' '));
a = norm(tA);  b = norm(tB);
fprintf('\nControlador ESP32 vs Etapa E (Controller_BoP.c):\n');
fprintf('  mismos #include (sin importar el orden): %s\n', pasa_falla(isequal(incA, incB)));
fprintf('  mismo codigo (sin comentarios, includes ni nombre del modelo): %s\n', pasa_falla(strcmp(a, b)));
if ~strcmp(a, b)
    n = min(numel(a), numel(b));  i = find(a(1:n) ~= b(1:n), 1);
    if isempty(i), i = n; end
    fprintf('  Primeros caracteres distintos:\n  ESP32 : ...%s...\n  EtapaE: ...%s...\n', ...
        a(max(1,i-80):min(end,i+160)), b(max(1,i-80):min(end,i+160)));
end
h = fileread(fullfile(dirCod,[mdl '.h']));
p = regexp(h, 'extern void Controller_BoP_ESP32_(step|initialize)\([^;]*;', 'match');
fprintf('Prototipos:\n  %s\n', strjoin(regexprep(p, '\s+', ' '), '\n  '));

%% 3. Copia al sketch
dirSk = fullfile(carpeta,'pil_esp32','bop_pil_esp32');
viejos = [dir(fullfile(dirSk,'*.c')); dir(fullfile(dirSk,'*.h'))];
for i = 1:numel(viejos), delete(fullfile(dirSk, viejos(i).name)); end
arch = [dir(fullfile(dirCod,'*.c')); dir(fullfile(dirCod,'*.h'))];
arch = arch(~strcmp({arch.name}, 'ert_main.c'));      % el main de ejemplo no se usa
for i = 1:numel(arch), copyfile(fullfile(dirCod, arch(i).name), dirSk, 'f'); end
compartido = fullfile(dirBuild,'slprj','ert','_sharedutils');
if isfolder(compartido)
    a2 = [dir(fullfile(compartido,'*.c')); dir(fullfile(compartido,'*.h'))];
    for i = 1:numel(a2), copyfile(fullfile(compartido, a2(i).name), dirSk, 'f'); end
end
% Si el codigo generado para la placa incluye el encabezado de recursos del
% paquete (solo lo usa el main del paquete), se deja uno vacio: el sketch no
% usa esos recursos.
todo = '';
for i = 1:numel(arch), todo = [todo fileread(fullfile(dirSk, arch(i).name))]; end %#ok<AGROW>
if contains(todo, 'MW_target_hardware_resources.h') && ~isfile(fullfile(dirSk,'MW_target_hardware_resources.h'))
    fid = fopen(fullfile(dirSk,'MW_target_hardware_resources.h'),'w');
    fprintf(fid, '/* Vacio a proposito: el sketch PIL no usa los recursos de hardware del paquete. */\n');
    fclose(fid);
    fprintf('AVISO: el codigo incluye MW_target_hardware_resources.h; se agrego uno vacio al sketch.\n');
end
lista = dir(fullfile(dirSk,'*.*'));
fprintf('\nSketch %s:\n  %s\n', dirSk, strjoin({lista(~[lista.isdir]).name}, ', '));

%% 4. Compilar y grabar con arduino-cli
sp = matlabshared.supportpkg.getSupportPackageRoot;
aCLI = fullfile(sp, '3P.instrset', 'arduinoide.instrset', 'aCLI');
cli = fullfile(aCLI, 'arduino-cli');
cfg = fullfile(aCLI, 'arduino-cli.yaml');
dirBin = fullfile(dirBuild, 'bop_pil_esp32_bin');
cmdC = sprintf('"%s" compile --config-file "%s" --fqbn %s --build-path "%s" "%s" 2>&1', cli, cfg, fqbn, dirBin, dirSk);
fprintf('\n%s\n', cmdC);
[st, out] = system(cmdC);  fprintf('%s\n', out);
if st ~= 0 && contains(out, "No module named 'serial'")
    error('G3:pyserial', ['Compilo, pero esptool.py (Python) necesita pyserial para armar la imagen. ' ...
        'En una terminal: sudo apt install python3-serial   y repitan G3.']);
end
if st ~= 0, error('G3:Compilar', 'arduino-cli compile fallo (codigo %d). Manden la consola completa.', st); end
cmdU = sprintf('"%s" upload --config-file "%s" --fqbn %s -p %s --input-dir "%s" "%s" 2>&1', cli, cfg, fqbn, puerto, dirBin, dirSk);
fprintf('\n%s\n', cmdU);
[st, out] = system(cmdU);  fprintf('%s\n', out);
if st ~= 0, error('G3:Grabar', 'arduino-cli upload fallo (codigo %d). Si dice "Connecting...", mantengan BOOT apretado y repitan.', st); end

%% 5. Prueba de comunicacion
s = g_pil_abrir(puerto);
[th, I, sat, ciclos] = g_pil_paso(s, 0, 0, 10, 0, true);
fprintf('Paso de prueba (eje X, r = 0, x = 10 mm, v = 0): th = %.17g rad, I = %.17g, sat = %d, %d ciclos (%.1f us)\n', ...
    th, I, sat, ciclos, ciclos/240);
clear s
fprintf('\nG3 listo: la ESP32 tiene el controlador generado. Siguiente: G4.\nFIN G3\n');
