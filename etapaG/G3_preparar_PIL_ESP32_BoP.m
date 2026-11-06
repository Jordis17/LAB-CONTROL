%% ETAPA G - SCRIPT 3: PREPARAR EL PIL EN LA ESP32 (ruta propia)
% El PIL de Simulink no se puede usar con la ESP32 (G0, G0b, G0c; ver
% LEEME_etapaG.md). Este script arma la ruta propia:
%   1. Copia al sketch pil_esp32/bop_pil_esp32 EXACTAMENTE el codigo de
%      etapaE/codigo_generado (el verificado en SIL, Etapa F), sin ert_main.c,
%      y comprueba que las copias sean identicas byte a byte. El sketch solo
%      hace de puente serie: recibe entradas, llama _step y devuelve salidas.
%   2. Compila con el arduino-cli del paquete de Arduino (toolchain Xtensa de
%      la ESP32, FQBN esp32:esp32:esp32) y graba la ESP32.
%   3. Prueba la comunicacion con un paso.
% Por que no se usa el codigo generado con la placa ESP32 (Controller_BoP_ESP32):
% no es identico al verificado en SIL (tiene una variable temporal mas) y
% depende de encabezados de Simulink (rtw_continuous.h). Ver LEEME_etapaG.md.
% Requisitos: ESP32 en el puerto y nada mas usandolo; pyserial instalado
% (sudo apt install python3-serial).
% Salida: resultados/G3_consola.txt

clearvars; close all; clc;
puerto = '/dev/ttyUSB0';
fqbn   = 'esp32:esp32:esp32';

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(carpeta,'funciones'), fullfile(raiz,'etapaE'));  % pasa_falla
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'G3_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);  limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA G - G3_preparar_PIL_ESP32_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

%% 1. Copia del codigo verificado en SIL al sketch
dirCod = fullfile(raiz,'etapaE','codigo_generado');
dirSk = fullfile(carpeta,'pil_esp32','bop_pil_esp32');
viejos = [dir(fullfile(dirSk,'*.c')); dir(fullfile(dirSk,'*.h'))];
for i = 1:numel(viejos), delete(fullfile(dirSk, viejos(i).name)); end
arch = [dir(fullfile(dirCod,'*.c')); dir(fullfile(dirCod,'*.h'))];
arch = arch(~strcmp({arch.name}, 'ert_main.c'));      % el main de ejemplo no se usa
identicos = true;
fprintf('Codigo copiado de %s:\n', dirCod);
for i = 1:numel(arch)
    o = fullfile(dirCod, arch(i).name);  d = fullfile(dirSk, arch(i).name);
    copyfile(o, d, 'f');
    fo = fopen(o);  bo = fread(fo, Inf, 'uint8=>uint8');  fclose(fo);
    fd = fopen(d);  bd = fread(fd, Inf, 'uint8=>uint8');  fclose(fd);
    igual = isequal(bo, bd);  identicos = identicos && igual;
    fprintf('  %-26s %6d bytes  identico: %s\n', arch(i).name, numel(bo), pasa_falla(igual));
end
if ~identicos, error('G3:Copia', 'La copia del codigo no es identica.'); end
h = fileread(fullfile(dirSk,'Controller_BoP.h'));
p = regexp(h, 'extern void Controller_BoP_(step|initialize)\([^;]*;', 'match');
fprintf('Prototipos:\n  %s\n', strjoin(regexprep(p, '\s+', ' '), '\n  '));
dirBuild = fullfile(carpeta,'build');
if ~isfolder(dirBuild), mkdir(dirBuild); end

%% 2. Compilar y grabar con arduino-cli
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

%% 3. Prueba de comunicacion
s = g_pil_abrir(puerto);
[th, I, sat, ciclos] = g_pil_paso(s, 0, 0, 10, 0, true);
fprintf('Paso de prueba (eje X, r = 0, x = 10 mm, v = 0): th = %.17g rad, I = %.17g, sat = %d, %d ciclos (%.1f us)\n', ...
    th, I, sat, ciclos, ciclos/240);
clear s
fprintf('\nG3 listo: la ESP32 tiene el controlador generado. Siguiente: G4.\nFIN G3\n');
