%% A11_comparar_Normal_PIL.m
% Comparacion back-to-back entre las ejecuciones Normal y PIL del controlador.
%
% Requiere las siguientes variables, generadas por bloques To Workspace con
% Save format = Timeseries:
%   Q1_Normal, T1_Normal, Q1_PIL, T1_PIL
%
% Ejecute este script manualmente despues de completar Run SIL/PIL en
% TCLab_Test_PIL.slx. No modifica las senales originales.

fprintf('\n============================================================\n');
fprintf(' Comparacion back-to-back Normal--PIL\n');
fprintf('============================================================\n');

%% 1. Recuperar y validar las senales requeridas
A11_names = {'Q1_Normal','T1_Normal','Q1_PIL','T1_PIL'};
A11_sig = cell(size(A11_names));

for A11_k = 1:numel(A11_names)
    A11_name = A11_names{A11_k};

    if evalin('base', sprintf("exist('%s','var')", A11_name)) ~= 1
        error('A11:MissingVariable', ...
            ['No se encontro la variable %s en el Base Workspace. ' ...
             'Compruebe los bloques To Workspace antes de continuar.'], ...
            A11_name);
    end

    A11_sig{A11_k} = evalin('base', A11_name);

    if ~isa(A11_sig{A11_k}, 'timeseries')
        error('A11:InvalidType', ...
            ['La variable %s debe ser un objeto timeseries. ' ...
             'Configure Save format = Timeseries en su bloque To Workspace.'], ...
            A11_name);
    end
end

A11_Q1N = A11_sig{1};
A11_T1N = A11_sig{2};
A11_Q1P = A11_sig{3};
A11_T1P = A11_sig{4};

%% 2. Extraer tiempo y datos
A11_t_Q1N = A11_Q1N.Time(:);
A11_t_T1N = A11_T1N.Time(:);
A11_t_Q1P = A11_Q1P.Time(:);
A11_t_T1P = A11_T1P.Time(:);

A11_qN = A11_Q1N.Data(:);
A11_TN = A11_T1N.Data(:);
A11_qP = A11_Q1P.Data(:);
A11_TP = A11_T1P.Data(:);

% Cada senal debe ser escalar: una muestra de datos por instante de tiempo.
if numel(A11_qN) ~= numel(A11_t_Q1N) || ...
   numel(A11_TN) ~= numel(A11_t_T1N) || ...
   numel(A11_qP) ~= numel(A11_t_Q1P) || ...
   numel(A11_TP) ~= numel(A11_t_T1P)
    error('A11:InvalidDimensions', ...
        'Las senales deben ser escalares y contener una muestra por instante de tiempo.');
end

if any(~isfinite(A11_qN)) || any(~isfinite(A11_TN)) || ...
   any(~isfinite(A11_qP)) || any(~isfinite(A11_TP))
    error('A11:NonFiniteData', ...
        'Se detectaron valores NaN o Inf en las senales registradas.');
end

%% 3. Comprobar compatibilidad temporal
if ~isequal(A11_t_Q1N, A11_t_T1N, A11_t_Q1P, A11_t_T1P)
    error('A11:TimeMismatch', ...
        'Los vectores de tiempo de las cuatro senales no son identicos.');
end

A11_t = A11_t_Q1N;
A11_N = numel(A11_t);

if A11_N ~= 1801
    error('A11:UnexpectedSampleCount', ...
        'Se esperaban 1801 muestras y se obtuvieron %d.', A11_N);
end

if A11_t(1) ~= 0 || A11_t(end) ~= 1800
    error('A11:UnexpectedTimeInterval', ...
        'Se esperaba un intervalo de simulacion entre 0 s y 1800 s.');
end

%% 4. Diferencias muestra a muestra
A11_dQ1 = A11_qP - A11_qN;
A11_dT1 = A11_TP - A11_TN;

[A11_maxQ1, A11_idxQ1] = max(abs(A11_dQ1));
[A11_maxT1, A11_idxT1] = max(abs(A11_dT1));

A11_rmseQ1 = sqrt(mean(A11_dQ1.^2));
A11_rmseT1 = sqrt(mean(A11_dT1.^2));

A11_exactQ1 = isequal(A11_qN, A11_qP);
A11_exactT1 = isequal(A11_TN, A11_TP);
A11_PASS = A11_exactQ1 && A11_exactT1;

% Criterio deliberadamente estricto para este banco: igualdad exacta.
% El script tambien reporta maximo absoluto y RMSE para documentar cualquier
% diferencia numerica que aparezca en otra ejecucion o configuracion.

%% 5. Mostrar resultados numericos
fprintf('\nIntegridad de los datos:\n');
fprintf('  Numero de muestras              : %d\n', A11_N);
fprintf('  Intervalo de tiempo             : %.0f s a %.0f s\n', A11_t(1), A11_t(end));
fprintf('  Vectores de tiempo identicos    : SI\n');

fprintf('\nQ1 (PIL - Normal):\n');
fprintf('  Maximo absoluto                 : %.16g\n', A11_maxQ1);
fprintf('  Instante del maximo             : %.16g s\n', A11_t(A11_idxQ1));
fprintf('  RMSE                            : %.16g\n', A11_rmseQ1);
fprintf('  Igualdad exacta                 : %s\n', A11_yesno(A11_exactQ1));

fprintf('\nT1 (PIL - Normal):\n');
fprintf('  Maximo absoluto                 : %.16g\n', A11_maxT1);
fprintf('  Instante del maximo             : %.16g s\n', A11_t(A11_idxT1));
fprintf('  RMSE                            : %.16g\n', A11_rmseT1);
fprintf('  Igualdad exacta                 : %s\n', A11_yesno(A11_exactT1));

if A11_PASS
    fprintf('\nRESULTADO GLOBAL: PASS\n');
    fprintf('Las ejecuciones Normal y PIL coinciden exactamente muestra a muestra.\n');
else
    fprintf('\nRESULTADO GLOBAL: FAIL\n');
    fprintf('Se detectaron diferencias entre las ejecuciones Normal y PIL.\n');
end
fprintf('============================================================\n\n');

%% 6. Comparacion grafica de las respuestas
figure('Name','Comparacion Normal--PIL','NumberTitle','off');
tiledlayout(2,1);

nexttile;
plot(A11_t, A11_qN, 'LineWidth', 1.2);
hold on;
plot(A11_t, A11_qP, '--', 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('Q_1 (%)');
title('Senal de control');
legend('Normal','PIL','Location','best');

nexttile;
plot(A11_t, A11_TN, 'LineWidth', 1.2);
hold on;
plot(A11_t, A11_TP, '--', 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('T_1 (^{\circ}C)');
title('Temperatura');
legend('Normal','PIL','Location','best');

%% 7. Graficas de las diferencias PIL - Normal
figure('Name','Diferencias PIL--Normal','NumberTitle','off');
tiledlayout(2,1);

nexttile;
plot(A11_t, A11_dQ1, 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('\Delta Q_1 (%)');
title('\Delta Q_1 = Q_{1,PIL} - Q_{1,Normal}');

nexttile;
plot(A11_t, A11_dT1, 'LineWidth', 1.2);
grid on;
xlabel('Tiempo (s)');
ylabel('\Delta T_1 (^{\circ}C)');
title('\Delta T_1 = T_{1,PIL} - T_{1,Normal}');

%% 8. Guardar resumen en el Base Workspace
A11_Resultados_Normal_PIL = struct( ...
    'N', A11_N, ...
    't_inicio', A11_t(1), ...
    't_final', A11_t(end), ...
    'max_abs_Q1', A11_maxQ1, ...
    't_max_Q1', A11_t(A11_idxQ1), ...
    'RMSE_Q1', A11_rmseQ1, ...
    'igualdad_exacta_Q1', A11_exactQ1, ...
    'max_abs_T1', A11_maxT1, ...
    't_max_T1', A11_t(A11_idxT1), ...
    'RMSE_T1', A11_rmseT1, ...
    'igualdad_exacta_T1', A11_exactT1, ...
    'PASS', A11_PASS);

assignin('base','A11_Resultados_Normal_PIL',A11_Resultados_Normal_PIL);

%% Funcion local auxiliar
function txt = A11_yesno(value)
if value
    txt = 'SI';
else
    txt = 'NO';
end
end
