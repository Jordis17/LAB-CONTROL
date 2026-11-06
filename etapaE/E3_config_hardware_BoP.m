%% ETAPA E - SCRIPT 3: CONFIGURACION DE HARDWARE PARA SIL (Y PIL)
% El SIL compila el codigo del controlador en la PC (x86-64, 64 bits) y
% Simulink lo rechaza si la configuracion de hardware de produccion no es
% compatible (error de F1, 2026-11-06):
%   ProdBitPerLong 32 (PC: 64), ProdIntDivRoundTo Undefined (PC: Zero),
%   ProdEndianess Unspecified (PC: LittleEndian).
% Este script cambia SOLO la configuracion de generacion de codigo de
% Controller_BoP.slx, no el algoritmo:
%   - ProdEndianess = LittleEndian   (la ESP32, Xtensa LX6, es little-endian)
%   - ProdIntDivRoundTo = Zero       (division entera de C99: hacia cero)
%   - PortableWordSizes = on         (el mismo codigo compila en la PC para SIL
%                                     aunque el destino sea de 32 bits)
% Los dos primeros son ademas las advertencias 2 y 3 del Code Generation Advisor.
%
% DESPUES de correrlo hay que repetir E1 (equivalencia con el MIL) y E2
% (codigo e inspeccion), porque el modelo de referencia cambio de version.
% Salidas: Controller_BoP.slx (guardado), resultados/E3_consola.txt

clearvars; close all; clc;
carpeta = fileparts(mfilename('fullpath'));
addpath(carpeta);
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'E3_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA E - E3_config_hardware_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

mdl = 'Controller_BoP';
init_Controller_BoP();
load_system(fullfile(carpeta,[mdl '.slx']));
cambios = {'ProdEndianess','LittleEndian'; 'ProdIntDivRoundTo','Zero'; 'PortableWordSizes','on'};
fprintf('Version del modelo antes: %s\n', get_param(mdl,'ModelVersion'));
for i = 1:size(cambios,1)
    antes = get_param(mdl, cambios{i,1});
    set_param(mdl, cambios{i,1}, cambios{i,2});
    fprintf('  %-18s %-12s -> %s\n', cambios{i,1}, antes, get_param(mdl, cambios{i,1}));
end
save_system(mdl);
fprintf('Version del modelo despues: %s\n', get_param(mdl,'ModelVersion'));
fprintf('Guardado. Repetir ahora E1_verificar_equivalencia_BoP y E2_generar_codigo_BoP.\nFIN E3\n');
