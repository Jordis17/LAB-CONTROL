%% ETAPA F - SCRIPT 0: CONSTRUCCION DEL BANCO SIL (BoP_Test_SIL.slx)
% Banco con DOS RAMAS en la misma simulacion (CLAUDE.md, Etapa F):
%   - rama Normal: Controller_BoP referenciado en modo Normal (eje X y eje Y);
%   - rama SIL:    Controller_BoP referenciado en modo Software-in-the-loop.
% Las dos ramas comparten la referencia, la habilitacion, las condiciones
% iniciales, Ts y el tiempo de simulacion. Cada rama tiene SU PROPIA copia de
% la planta (bloque MATLAB Function con planta_bop_paso), porque las acciones
% de control se calculan por separado.
%
% Ensayo (igual que el D4 del MIL): bola en (80, -60) mm; controlador
% habilitado a los 0,5 s; referencia (0, 0) y a los 4,5 s (50, 50); 9 s.
% Un Unit Delay entre el controlador y la planta representa el cuadro de
% calculo/actuacion y rompe el lazo algebraico.
%
% Requisitos: etapaC/resultados/C1_controlador.mat y etapaE/Controller_BoP.slx.
% No modifica Controller_BoP.slx (referencia intocable): solo lo referencia.
% No sobrescribe BoP_Test_SIL.slx salvo forzar = true.
% Salidas: BoP_Test_SIL.slx, funciones/planta_bop_param.m (generado),
%          resultados/F0_consola.txt

clearvars; close all; clc;
forzar = false;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(carpeta,'funciones'), fullfile(raiz,'etapaE'), ...
        fullfile(raiz,'etapaC','funciones'), fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'F0_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));
fprintf('ETAPA F - F0_build_Test_SIL_BoP   (%s)\nMATLAB %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), version);

banco = 'BoP_Test_SIL';
archivo = fullfile(carpeta, [banco '.slx']);
if isfile(archivo) && ~forzar
    error('F0:Existe', '%s ya existe. Para reconstruirlo ponga forzar = true.', archivo);
end

% Parametros: controlador (workspace base) y planta (archivo generado)
init_Controller_BoP();
S = load(fullfile(raiz,'etapaC','resultados','C1_controlador.mat'));
P = A0_parametros_BoP();
planta_bop_param_escribir(P, S.Ctrl, fullfile(carpeta,'funciones','planta_bop_param.m'));
rehash;
fprintf('Generado funciones/planta_bop_param.m (planta del banco)\n');
load_system(fullfile(raiz,'etapaE','Controller_BoP.slx'));

if bdIsLoaded(banco), close_system(banco, 0); end
if isfile(archivo), delete(archivo); end
new_system(banco);

%% Fuentes compartidas
add_block('simulink/Sources/Step', [banco '/r_x'], 'Time','4.5', 'Before','0', 'After','50', ...
    'SampleTime','Ts_ctrl', 'Position',[30 40 60 70]);
add_block('simulink/Sources/Step', [banco '/r_y'], 'Time','4.5', 'Before','0', 'After','50', ...
    'SampleTime','Ts_ctrl', 'Position',[30 120 60 150]);
add_block('simulink/Sources/Step', [banco '/hab'], 'Time','0.5', 'Before','0', 'After','1', ...
    'SampleTime','Ts_ctrl', 'Position',[30 200 60 230]);
add_block('simulink/Signal Attributes/Data Type Conversion', [banco '/hab_bool'], ...
    'OutDataTypeStr','boolean', 'Position',[100 200 140 230]);
add_line(banco, 'hab/1', 'hab_bool/1', 'autorouting','on');

codigoPlanta = sprintf(['function y = planta(th_cmd)\n' ...
    '%%#codegen\n' ...
    '%% Planta del banco: ver etapaF/funciones/planta_bop_paso.m\n' ...
    'persistent S\n' ...
    'Pp = planta_bop_param();\n' ...
    'if isempty(S)\n' ...
    '    S = planta_bop_estado0(Pp);\n' ...
    'end\n' ...
    '[y, S] = planta_bop_paso(th_cmd, S, Pp);\n' ...
    'end\n']);

ramas = {'Normal', 'Normal'; 'SIL', 'Software-in-the-loop (SIL)'};
rt = sfroot;
for b = 1:size(ramas,1)
    suf = ramas{b,1};  modo = ramas{b,2};
    y0 = 300 + (b-1)*420;
    % Planta propia de la rama
    bp = [banco '/Planta_' suf];
    add_block('simulink/User-Defined Functions/MATLAB Function', bp, 'Position',[620 y0 760 y0+80]);
    m = rt.find('-isa','Simulink.BlockDiagram','Name',banco);
    ch = m.find('-isa','Stateflow.EMChart','Path',bp);
    ch.Script = codigoPlanta;
    pp = get_param(bp,'Ports');
    if pp(1) ~= 1 || pp(2) ~= 1, error('F0:Planta','La planta de %s no quedo con 1 entrada y 1 salida.', suf); end
    add_block('simulink/Signal Routing/Demux', [banco '/Demux_' suf], 'Outputs','6', 'Position',[800 y0-20 805 y0+100]);
    add_line(banco, ['Planta_' suf '/1'], ['Demux_' suf '/1'], 'autorouting','on');
    % Controladores (eje X y eje Y)
    ejes = {'X','Y'};
    for e = 1:2
        bc = [banco '/Ctrl_' ejes{e} '_' suf];
        add_block('simulink/Ports & Subsystems/Model', bc, 'Position',[250 y0+(e-1)*170 400 y0+120+(e-1)*170]);
        set_param(bc, 'ModelName','Controller_BoP');
        set_param(bc, 'SimulationMode', modo);
        pc = get_param(bc,'Ports');
        if pc(1) ~= 4 || pc(2) ~= 3, error('F0:Ctrl','%s quedo con %d entradas y %d salidas.', bc, pc(1), pc(2)); end
        add_block('simulink/Discrete/Unit Delay', [banco '/UD_' ejes{e} '_' suf], 'InitialCondition','0', ...
            'SampleTime','Ts_ctrl', 'Position',[450 y0+10+(e-1)*170 480 y0+40+(e-1)*170]);
    end
    add_block('simulink/Signal Routing/Mux', [banco '/Mux_' suf], 'Inputs','2', 'Position',[540 y0 545 y0+80]);
    % Conexiones
    add_line(banco, 'r_x/1', ['Ctrl_X_' suf '/1'], 'autorouting','on');
    add_line(banco, ['Demux_' suf '/1'], ['Ctrl_X_' suf '/2'], 'autorouting','on');
    add_line(banco, ['Demux_' suf '/2'], ['Ctrl_X_' suf '/3'], 'autorouting','on');
    add_line(banco, 'hab_bool/1', ['Ctrl_X_' suf '/4'], 'autorouting','on');
    add_line(banco, 'r_y/1', ['Ctrl_Y_' suf '/1'], 'autorouting','on');
    add_line(banco, ['Demux_' suf '/3'], ['Ctrl_Y_' suf '/2'], 'autorouting','on');
    add_line(banco, ['Demux_' suf '/4'], ['Ctrl_Y_' suf '/3'], 'autorouting','on');
    add_line(banco, 'hab_bool/1', ['Ctrl_Y_' suf '/4'], 'autorouting','on');
    add_line(banco, ['Ctrl_X_' suf '/1'], ['UD_X_' suf '/1'], 'autorouting','on');
    add_line(banco, ['Ctrl_Y_' suf '/1'], ['UD_Y_' suf '/1'], 'autorouting','on');
    add_line(banco, ['UD_X_' suf '/1'], ['Mux_' suf '/1'], 'autorouting','on');
    add_line(banco, ['UD_Y_' suf '/1'], ['Mux_' suf '/2'], 'autorouting','on');
    add_line(banco, ['Mux_' suf '/1'], ['Planta_' suf '/1'], 'autorouting','on');
    % Registro (To Workspace, timeseries)
    reg = { ['Ctrl_X_' suf '/1'], 'thx';  ['Ctrl_Y_' suf '/1'], 'thy';
            ['Ctrl_X_' suf '/2'], 'Ix';   ['Ctrl_Y_' suf '/2'], 'Iy';
            ['Ctrl_X_' suf '/3'], 'satx'; ['Ctrl_Y_' suf '/3'], 'saty';
            ['Demux_' suf '/1'],  'xhx';  ['Demux_' suf '/3'],  'xhy';
            ['Demux_' suf '/5'],  'x';    ['Demux_' suf '/6'],  'y' };
    for k = 1:size(reg,1)
        nombre = [suf '_' reg{k,2}];
        add_block('simulink/Sinks/To Workspace', [banco '/tw_' nombre], 'VariableName', nombre, ...
            'SaveFormat','Timeseries', 'SampleTime','-1', ...
            'Position',[900 y0-40+k*35 990 y0-20+k*35]);
        add_line(banco, reg{k,1}, ['tw_' nombre '/1'], 'autorouting','on');
    end
    fprintf('Rama %-6s: Ctrl_X_%s y Ctrl_Y_%s en modo "%s", planta propia Planta_%s\n', suf, suf, suf, modo, suf);
end

%% Configuracion del banco
set_param(banco, 'SolverType','Fixed-step', 'Solver','FixedStepDiscrete', 'FixedStep','Ts_ctrl', ...
    'StopTime','9', 'InitFcn','init_Controller_BoP', 'ReturnWorkspaceOutputs','on');
set_param(banco, 'Description', ['Banco SIL Ball on Plate: ramas Normal y SIL de Controller_BoP ' ...
    '(ejes X e Y), cada una con su planta (planta_bop_paso). Ensayo D4.']);
try, Simulink.BlockDiagram.arrangeSystem(banco); catch, end
save_system(banco, archivo);
fprintf('\nBanco guardado: %s\nFIN F0\n', archivo);
