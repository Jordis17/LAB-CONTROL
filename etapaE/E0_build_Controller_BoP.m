%% ETAPA E - SCRIPT 0: CONSTRUCCION DE Controller_BoP.slx
% Construye por script el modelo del controlador de UN eje, separado de la
% planta (la planta no va adentro). Los dos ejes usan el mismo modelo: el
% codigo se genera como "Reusable function" y el firmware lo instancia dos veces.
%
% Interfaz (todas por cuadro de camara, periodo Ts_ctrl):
%   Entradas: r_mm [mm] (double), x_hat_mm [mm] (double), v_hat_mm_s [mm/s] (double),
%             habilitado (boolean)
%   Salidas:  th_cmd_rad [rad] (double), I_rad [rad] (double), saturado (boolean)
% Parametros calibrables: BoP_Kp ... BoP_Nq (init_Controller_BoP, ExportedGlobal).
%
% El algoritmo es el bloque MATLAB Function "ley_control", cuyo codigo es
% ley_control_BoP_bloque.m seguido de etapaC/funciones/bop_ley_control.m
% (la misma funcion que usa el MIL).
%
% El modelo resultante es la REFERENCIA INTOCABLE de las etapas E a G.
% Este script no sobrescribe un Controller_BoP.slx existente salvo que se
% ponga forzar = true a proposito (y entonces hay que repetir E1).
%
% Uso: en MATLAB, con etapaE como carpeta actual:
%   >> E0_build_Controller_BoP
% Salidas: Controller_BoP.slx, resultados/E0_consola.txt

clearvars; close all; clc;
forzar = false;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(raiz,'etapaC','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'E0_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA E - E0_build_Controller_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

mdl = 'Controller_BoP';
archivo = fullfile(carpeta, [mdl '.slx']);
if isfile(archivo) && ~forzar
    error('E0:Existe', ['%s ya existe y es la referencia intocable. Si de verdad hay que ' ...
        'reconstruirlo, ponga forzar = true y despues repita E1 y E2.'], archivo);
end

init_Controller_BoP();
fprintf('Parametros cargados de etapaC/resultados/C1_controlador.mat (Ts_ctrl = %.6f s)\n', evalin('base','Ts_ctrl'));

if bdIsLoaded(mdl), close_system(mdl, 0); end
if isfile(archivo), delete(archivo); end
new_system(mdl);

%% Bloques
x0 = 40;  dy = 60;
entradas = {'r_mm','double'; 'x_hat_mm','double'; 'v_hat_mm_s','double'; 'habilitado','boolean'};
for i = 1:size(entradas,1)
    b = [mdl '/' entradas{i,1}];
    add_block('simulink/Sources/In1', b, 'Position', [x0, 40+(i-1)*dy, x0+30, 54+(i-1)*dy]);
    set_param(b, 'OutDataTypeStr', entradas{i,2}, 'SampleTime', 'Ts_ctrl', ...
        'PortDimensions', '1', 'Interpolate', 'off');
end

parametros = {'BoP_Kp','BoP_Ki','BoP_Kd','BoP_Ts','BoP_th_lim','BoP_e_clip','BoP_v_int','BoP_Nq'};
y0 = 40 + size(entradas,1)*dy;
for i = 1:numel(parametros)
    b = [mdl '/' parametros{i}];
    add_block('simulink/Sources/Constant', b, 'Position', [x0-20, y0+(i-1)*45, x0+70, y0+25+(i-1)*45]);
    set_param(b, 'Value', parametros{i}, 'OutDataTypeStr', 'double');
end

bf = [mdl '/ley_control'];
add_block('simulink/User-Defined Functions/MATLAB Function', bf, 'Position', [260, 40, 460, 40+12*45]);
codigo = [fileread(fullfile(carpeta,'ley_control_BoP_bloque.m')) char(10) char(10) ...
          fileread(fullfile(raiz,'etapaC','funciones','bop_ley_control.m'))];
rt = sfroot;
m = rt.find('-isa','Simulink.BlockDiagram','Name',mdl);
ch = m.find('-isa','Stateflow.EMChart','Path',bf);
if isempty(ch)
    error('E0:SinChart','No se encontro el chart del bloque MATLAB Function %s.', bf);
end
ch.Script = codigo;
puertos = get_param(bf,'Ports');
fprintf('Bloque ley_control: %d entradas, %d salidas\n', puertos(1), puertos(2));
if puertos(1) ~= 12 || puertos(2) ~= 3
    error('E0:Puertos','Se esperaban 12 entradas y 3 salidas en ley_control.');
end

salidas = {'th_cmd_rad','I_rad','saturado'};
for i = 1:numel(salidas)
    b = [mdl '/' salidas{i}];
    add_block('simulink/Sinks/Out1', b, 'Position', [560, 80+(i-1)*120, 590, 94+(i-1)*120]);
end

%% Conexiones
for i = 1:size(entradas,1)
    add_line(mdl, [entradas{i,1} '/1'], sprintf('ley_control/%d', i), 'autorouting', 'on');
end
for i = 1:numel(parametros)
    add_line(mdl, [parametros{i} '/1'], sprintf('ley_control/%d', size(entradas,1)+i), 'autorouting', 'on');
end
for i = 1:numel(salidas)
    h = add_line(mdl, sprintf('ley_control/%d', i), [salidas{i} '/1'], 'autorouting', 'on');
    set_param(h, 'Name', salidas{i});
end

%% Configuracion
set_param(mdl, 'Description', ['Controlador Ball on Plate, un eje. Ley en bop_ley_control.m ' ...
    '(Etapa C). Entradas r, x_hat, v_hat del Kalman y habilitado; salida th_cmd en rad. ' ...
    'Referencia intocable: las variantes son copias con otro nombre.']);
set_param(mdl, 'InitFcn', 'init_Controller_BoP');
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', 'Ts_ctrl', 'StopTime', '10');
set_param(mdl, 'SaveOutput', 'on', 'SaveFormat', 'Dataset', 'OutputSaveName', 'yout', ...
    'SaveTime', 'on', 'TimeSaveName', 'tout', 'ReturnWorkspaceOutputs', 'on');
set_param(mdl, 'SystemTargetFile', 'ert.tlc');
set_param(mdl, 'GenCodeOnly', 'on', 'GenerateReport', 'on', 'LaunchReport', 'off', ...
    'CodeInterfacePackaging', 'Reusable function');
try
    set_param(mdl, 'ProdHWDeviceType', 'Generic->32-bit Embedded Processor');
    % Agregado el 2026-11-06 (ver E3): necesarios para SIL en la PC y propios de la ESP32
    set_param(mdl, 'ProdEndianess', 'LittleEndian', 'ProdIntDivRoundTo', 'Zero', 'PortableWordSizes', 'on');
    fprintf('Hardware de produccion: Generic->32-bit Embedded Processor (ESP32: Xtensa LX6, 32 bits)\n');
catch err
    fprintf('AVISO: no se pudo fijar ProdHWDeviceType (%s)\n', err.message);
end
try
    set_param(mdl, 'ObjectivePriorities', {'Execution efficiency','Traceability'});
    fprintf('Objetivos del Code Generation Advisor: Execution efficiency, Traceability\n');
catch err
    fprintf('AVISO: no se pudieron fijar los objetivos de generacion (%s)\n', err.message);
end
try
    Simulink.BlockDiagram.arrangeSystem(mdl);
catch
end

save_system(mdl, archivo);
fprintf('\nModelo guardado: %s\n', archivo);

%% Resumen
fprintf('\nInterfaz:\n');
for i = 1:size(entradas,1)
    fprintf('  entrada %d: %-12s %s\n', i, entradas{i,1}, entradas{i,2});
end
for i = 1:numel(salidas)
    fprintf('  salida  %d: %s\n', i, salidas{i});
end
fprintf('Parametros (valor, workspace base):\n');
for i = 1:numel(parametros)
    p = evalin('base', parametros{i});
    fprintf('  %-11s = %.10g   %s\n', parametros{i}, p.Value, p.Description);
end
fprintf('Configuracion: %s, paso %s, %s, %s\n', get_param(mdl,'Solver'), get_param(mdl,'FixedStep'), ...
    get_param(mdl,'SystemTargetFile'), get_param(mdl,'CodeInterfacePackaging'));
fprintf('FIN E0\n');
