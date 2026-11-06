%% ETAPA E - SCRIPT 2: GENERACION E INSPECCION DEL CODIGO
% Genera el codigo C de Controller_BoP.slx con Embedded Coder (ert.tlc,
% Reusable function, hardware generico de 32 bits) y revisa automaticamente
% que el codigo conserve lo que exige la Etapa E:
%   interfaz, estado interno, parametros calibrables, saturacion, logica del
%   integrador (clamping, integracion condicional, recorte), tipos de dato y
%   AUSENCIA de la planta.
%
% ANTES de correr este script: Code Generation Advisor (ver LEEME_etapaE.md,
% seccion 3). Criterio: cero Fail; las advertencias se revisan y se
% justifican; NO usar "Fix All" ni modificaciones automaticas.
%
% Requisitos: Embedded Coder, Controller_BoP.slx (E0), E1 en PASS.
% Salidas: codigo_generado/ (copia de .c/.h y el reporte html),
%          resultados/E2_consola.txt, resultados/E2_inspeccion.csv

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(carpeta, fullfile(raiz,'etapaC','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'E2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA E - E2_generar_codigo_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

mdl = 'Controller_BoP';
init_Controller_BoP();
load_system(fullfile(carpeta,[mdl '.slx']));

%% 1. Generacion
dirBuild = fullfile(carpeta,'build');
if ~isfolder(dirBuild), mkdir(dirBuild); end
Simulink.fileGenControl('set', 'CodeGenFolder', dirBuild, 'CacheFolder', dirBuild, 'createDir', true);
restaurar = onCleanup(@() Simulink.fileGenControl('reset'));
fprintf('Configuracion de generacion:\n');
cfgs = {'SystemTargetFile','CodeInterfacePackaging','ProdHWDeviceType','ProdBitPerInt', ...
        'ProdBitPerDouble','ProdEndianess','ObjectivePriorities','Solver','FixedStep'};
for i = 1:numel(cfgs)
    try
        v = get_param(mdl, cfgs{i});
        if iscell(v), v = strjoin(v, ', '); end
        if isnumeric(v), v = num2str(v); end
        fprintf('  %-24s %s\n', cfgs{i}, v);
    catch
    end
end
viejo = fullfile(carpeta, [mdl '_ert_rtw']);
if isfolder(viejo)
    fprintf('AVISO: existe %s de una generacion anterior (fuera de build/).\n', viejo);
    fprintf('       No se usa; se puede borrar junto con etapaE/slprj si existe.\n');
end
% Se genera desde dentro de build/ para que la carpeta actual y la de
% generacion coincidan (MATLAB rechaza generar si la carpeta actual tiene
% codigo generado y CodeGenFolder apunta a otra).
dirAntes = pwd;
cd(dirBuild);
volver = onCleanup(@() cd(dirAntes));
slbuild(mdl);
dirCod = fullfile(dirBuild, [mdl '_ert_rtw']);
fprintf('Codigo generado en %s\n', dirCod);

%% 2. Copia a codigo_generado/
dirCopia = fullfile(carpeta,'codigo_generado');
if ~isfolder(dirCopia), mkdir(dirCopia); end
arch = [dir(fullfile(dirCod,'*.c')); dir(fullfile(dirCod,'*.h'))];
for i = 1:numel(arch)
    copyfile(fullfile(dirCod, arch(i).name), dirCopia);
end
compartido = fullfile(dirBuild,'slprj','ert','_sharedutils');
if isfolder(compartido)
    a2 = [dir(fullfile(compartido,'*.c')); dir(fullfile(compartido,'*.h'))];
    for i = 1:numel(a2), copyfile(fullfile(compartido, a2(i).name), dirCopia); end
end
if isfolder(fullfile(dirCod,'html'))
    copyfile(fullfile(dirCod,'html'), fullfile(dirCopia,'html'));
end
lista = dir(fullfile(dirCopia,'*.*'));
fprintf('Copiados a codigo_generado/: %s\n', strjoin({lista(~[lista.isdir]).name}, ', '));

%% 3. Inspeccion automatica
txtC = fileread(fullfile(dirCod, [mdl '.c']));
txtH = fileread(fullfile(dirCod, [mdl '.h']));
todo = [txtC char(10) txtH];
chequeos = {
  'Funcion de paso (reusable, con estado como argumento)', [mdl '_step\s*\('];
  'Funcion de inicializacion',                             [mdl '_initialize\s*\('];
  'Parametro BoP_Kp como global calibrable',               'BoP_Kp';
  'Parametro BoP_Ki',                                      'BoP_Ki';
  'Parametro BoP_Kd',                                      'BoP_Kd';
  'Parametro BoP_Ts',                                      'BoP_Ts';
  'Saturacion con BoP_th_lim',                             'BoP_th_lim';
  'Recorte del error con BoP_e_clip',                      'BoP_e_clip';
  'Umbral de bola quieta BoP_v_int',                       'BoP_v_int';
  'Cuadros BoP_Nq',                                        'BoP_Nq';
  'Estado interno (DWork) del integrador / contador',      'DW';
  'Entrada booleana habilitado',                           'habilitado';
  'Salida th_cmd_rad',                                     'th_cmd_rad';
  'Tipo double (real_T)',                                  'real_T';
  'Tipo booleano (boolean_T)',                             'boolean_T' };
ausentes = {
  'Sin funciones trigonometricas (no hay planta ni cinematica)', '\<(sin|cos|acos|atan2)\s*\(';
  'Sin restos del modelo de la planta',                          '(bop_aceleracion|bop_medicion|c_rod|9810)' };
fid = fopen(fullfile(dirRes,'E2_inspeccion.csv'),'w');
fprintf(fid, 'chequeo,esperado,encontrado,ocurrencias,resultado\n');
okTodo = true;
fprintf('\nInspeccion del codigo (%s.c y %s.h):\n', mdl, mdl);
for i = 1:size(chequeos,1)
    n = numel(regexp(todo, chequeos{i,2}, 'match'));
    ok = n > 0;  okTodo = okTodo && ok;
    fprintf('  [%s] %-58s (%d)\n', pasa_falla(ok), chequeos{i,1}, n);
    fprintf(fid, '"%s",presente,%d,%d,%s\n', chequeos{i,1}, ok, n, pasa_falla(ok));
end
for i = 1:size(ausentes,1)
    n = numel(regexp(txtC, ausentes{i,2}, 'match'));
    ok = n == 0;  okTodo = okTodo && ok;
    fprintf('  [%s] %-58s (%d)\n', pasa_falla(ok), ausentes{i,1}, n);
    fprintf(fid, '"%s",ausente,%d,%d,%s\n', ausentes{i,1}, ~ok, n, pasa_falla(ok));
end
fclose(fid);

% Fragmentos para la tabla de correspondencia modelo <-> codigo
fprintf('\nLineas de %s.c que mencionan los parametros o el estado (para la tabla modelo <-> codigo):\n', mdl);
lineas = regexp(txtC, '\n', 'split');
for i = 1:numel(lineas)
    if ~isempty(regexp(lineas{i}, '(BoP_|DW|->|_step|_initialize|habilitado|th_cmd)', 'once'))
        fprintf('  %4d: %s\n', i, strtrim(lineas{i}));
    end
end
fprintf('\nInspeccion automatica: %s\n', pasa_falla(okTodo));
fprintf('Pendiente manual: revisar el reporte html (codigo_generado/html) y completar la\n');
fprintf('tabla de correspondencia modelo <-> codigo con estas lineas.\n');
fprintf('FIN E2\n');
