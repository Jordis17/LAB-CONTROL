%% A10_comparar_Normal_SIL.m
% Comparacion back-to-back entre las ejecuciones Normal y SIL del controlador.
%
% Requiere las siguientes variables, generadas por bloques To Workspace con
% Save format = Timeseries:
%   Q1_Normal, T1_Normal, Q1_SIL, T1_SIL
%
% El script puede ejecutarse manualmente o desde el callback StopFcn de
% TCLab_Test.slx. No modifica las senales originales.

fprintf('\n============================================================\n');
fprintf(' Comparacion back-to-back Normal--SIL\n');
fprintf('============================================================\n');

%% 1. Recuperar y validar las senales requeridas
A10_names = {'Q1_Normal','T1_Normal','Q1_SIL','T1_SIL'};
A10_sig = cell(size(A10_names));

for A10_k = 1:numel(A10_names)
    A10_name = A10_names{A10_k};

    if evalin('base', sprintf("exist('%s','var')", A10_name)) ~= 1
        error('A10:MissingVariable', ...
            ['No se encontro la variable %s en el Base Workspace. ' ...
             'Compruebe los bloques To Workspace antes de continuar.'], ...
            A10_name);
    end

    A10_sig{A10_k} = evalin('base', A10_name);

    if ~isa(A10_sig{A10_k}, 'timeseries')
        error('A10:InvalidType', ...
            ['La variable %s debe ser un objeto timeseries. ' ...
             'Configure Save format = Timeseries en su bloque To Workspace.'], ...
            A10_name);
    end
end

A10_Q1N = A10_sig{1};
A10_T1N = A10_sig{2};
A10_Q1S = A10_sig{3};
A10_T1S = A10_sig{4};

%% 2. Extraer tiempo y datos
A10_t_Q1N = A10_Q1N.Time(:);
A10_t_T1N = A10_T1N.Time(:);
A10_t_Q1S = A10_Q1S.Time(:);
A10_t_T1S = A10_T1S.Time(:);

A10_qN = A10_Q1N.Data(:);
A10_TN = A10_T1N.Data(:);
A10_qS = A10_Q1S.Data(:);
A10_TS = A10_T1S.Data(:);

% Cada senal debe ser escalar: una muestra de datos por instante de tiempo.
if numel(A10_qN) ~= numel(A10_t_Q1N) || ...
   numel(A10_TN) ~= numel(A10_t_T1N) || ...
   numel(A10_qS) ~= numel(A10_t_Q1S) || ...
   numel(A10_TS) ~= numel(A10_t_T1S)
    error('A10:InvalidDimensions', ...
        'Las senales deben ser escalares y contener una muestra por instante de tiempo.');
end

%% 3. Comprobar compatibilidad temporal
if ~isequal(A10_t_Q1N, A10_t_T1N, A10_t_Q1S, A10_t_T1S)
    error('A10:TimeMismatch', ...
        'Los vectores de tiempo de las cuatro senales no son identicos.');
end

A10_t = A10_t_Q1N;
A10_N = numel(A10_t);

if A10_N ~= 1801
    error('A10:UnexpectedSampleCount', ...
        'Se esperaban 1801 muestras y se obtuvieron %d.', A10_N);
end

if A10_t(1) ~= 0 || A10_t(end) ~= 1800
    error('A10:UnexpectedTimeInterval', ...
        'Se esperaba un intervalo de simulacion entre 0 s y 1800 s.');
end

%% 4. Diferencias muestra a muestra
A10_dQ1 = A10_qS - A10_qN;
A10_dT1 = A10_TS - A10_TN;

[A10_maxQ1, A10_idxQ1] = max(abs(A10_dQ1));
[A10_maxT1, A10_idxT1] = max(abs(A10_dT1));

A10_rmseQ1 = sqrt(mean(A10_dQ1.^2));
A10_rmseT1 = sqrt(mean(A10_dT1.^2));

A10_exactQ1 = isequal(A10_qN, A10_qS);
A10_exactT1 = isequal(A10_TN, A10_TS);
A10_PASS = A10_exactQ1 && A10_exactT1;

%% 5. Mostrar resultados numericos
fprintf('\nIntegridad de los datos:\n');
fprintf('  Numero de muestras              : %d\n', A10_N);
fprintf('  Intervalo de tiempo             : %.0f s a %.0f s\n', A10_t(1), A10_t(end));
fprintf('  Vectores de tiempo identicos    : SI\n');

fprintf('\nQ1 (SIL - Normal):\n');
fprintf('  Maximo absoluto                 : %.16g\n', A10_maxQ1);
fprintf('  Instante del maximo             : %.16g s\n', A10_t(A10_idxQ1));
fprintf('  RMSE                            : %.16g\n', A10_rmseQ1);
fprintf('  Igualdad exacta                 : %s\n', A10_yesno(A10_exactQ1));

fprintf('\nT1 (SIL - Normal):\n');
fprintf('  Maximo absoluto                 : %.16g\n', A10_maxT1);
fprintf('  Instante del maximo             : %.16g s\n', A10_t(A10_idxT1));
fprintf('  RMSE                            : %.16g\n', A10_rmseT1);
fprintf('  Igualdad exacta                 : %s\n', A10_yesno(A10_exactT1));

if A10_PASS
    fprintf('\nRESULTADO GLOBAL: PASS\n');
    fprintf('Las ejecuciones Normal y SIL coinciden exactamente muestra a muestra.\n');
else
    fprintf('\nRESULTADO GLOBAL: FAIL\n');
    fprintf('Se detectaron diferencias entre las ejecuciones Normal y SIL.\n');
end
fprintf('============================================================\n\n');

%% 6. Comparacion grafica de las respuestas
figure('Name','Comparacion Normal--SIL','NumberTitle','off');
tiledlayout(2,1);

nexttile;
plot(A10_t, A10_qN, 'LineWidth', 1.2);
hold on;
plot(A10_t, A10_qS, '--', 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('Q_1 (%)');
title('Senal de control');
legend('Normal','SIL','Location','best');

nexttile;
plot(A10_t, A10_TN, 'LineWidth', 1.2);
hold on;
plot(A10_t, A10_TS, '--', 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('T_1 (^{\circ}C)');
title('Temperatura');
legend('Normal','SIL','Location','best');

%% 7. Graficas de las diferencias SIL - Normal
figure('Name','Diferencias SIL--Normal','NumberTitle','off');
tiledlayout(2,1);

nexttile;
plot(A10_t, A10_dQ1, 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('\Delta Q_1 (%)');
title('\Delta Q_1 = Q_{1,SIL} - Q_{1,Normal}');

nexttile;
plot(A10_t, A10_dT1, 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('\Delta T_1 (^{\circ}C)');
title('\Delta T_1 = T_{1,SIL} - T_{1,Normal}');

%% 8. Guardar resumen en el Base Workspace
A10_Resultados_Normal_SIL = struct( ...
    'N', A10_N, ...
    't_inicio', A10_t(1), ...
    't_final', A10_t(end), ...
    'max_abs_Q1', A10_maxQ1, ...
    't_max_Q1', A10_t(A10_idxQ1), ...
    'RMSE_Q1', A10_rmseQ1, ...
    'igualdad_exacta_Q1', A10_exactQ1, ...
    'max_abs_T1', A10_maxT1, ...
    't_max_T1', A10_t(A10_idxT1), ...
    'RMSE_T1', A10_rmseT1, ...
    'igualdad_exacta_T1', A10_exactT1, ...
    'PASS', A10_PASS);

assignin('base','A10_Resultados_Normal_SIL',A10_Resultados_Normal_SIL);

%% Funcion local auxiliar
function txt = A10_yesno(value)
if value
    txt = 'SI';
else
    txt = 'NO';
end
end
