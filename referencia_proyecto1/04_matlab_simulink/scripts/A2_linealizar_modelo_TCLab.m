%% ACTIVIDAD 2: LINEALIZACION DEL MODELO DE LA TCLab EN Q = 50 POR CIENTO
% Este script:
%   1. Calcula la temperatura de equilibrio Tbar para Qbar = 50 %.
%   2. Evalua los coeficientes gamma y beta del modelo lineal.
%   3. Calcula la ganancia estatica K y la constante de tiempo tau.
%   4. Construye la funcion de transferencia DeltaT(s)/DeltaQ(s).
%   5. Compara los modelos no lineal y lineal para una perturbación pequeña.
%   6. Repite la comparación para una perturbación de mayor amplitud.
%
% Modelo no lineal:
%
%   m*cp*dT/dt = U*A*(Ta - T) ...
%              + emisividad*sigmaSB*A*(Tinf^4 - T^4) ...
%              + alpha*Q
%
% Modelo lineal en variables de desviacion:
%
%   d(DeltaT)/dt = gamma*DeltaT + beta*DeltaQ
%
% IMPORTANTE: todas las temperaturas se expresan en kelvin dentro de las
% ecuaciones. Una diferencia de temperatura tiene el mismo valor numérico
% en kelvin y en grados Celsius.

clearvars; close all; clc;

%% 1. Condiciones de operacion y casos de comparacion
% Sustituya este valor por la temperatura ambiente medida al inicio de la
% practica.
Tamb_C = 25.0;             % Temperatura ambiente medida [degC]

Qbar = 50.0;               % Entrada en el punto de operacion [%]
dQ_pequeno = 5.0;          % Perturbacion pequena respecto a Qbar [%]
dQ_grande = 40.0;          % Perturbacion de mayor amplitud [%]

t_escalon = 200;           % Instante de aplicacion del cambio [s]
t_final = 1200;            % Duracion total de cada simulacion [s]
t_eval = (0:1:t_final)';   % Instantes para presentar los resultados [s]

% Se supone que la temperatura del aire y la temperatura radiativa efectiva
% del entorno son iguales a la temperatura ambiente medida.
Ta_K = Tamb_C + 273.15;    % Temperatura del aire [K]
Tinf_K = Ta_K;             % Temperatura radiativa del entorno [K]

%% 2. Parametros nominales del modelo
m = 0.004;                 % Masa termica efectiva [kg]
cp = 500;                  % Calor especifico [J/(kg K)]
A = 1.2e-3;                % Area efectiva de transferencia [m^2]
U = 5;                     % Coeficiente global [W/(m^2 K)]
emisividad = 0.9;          % Emisividad [-]
sigmaSB = 5.67e-8;         % Constante de Stefan-Boltzmann [W/(m^2 K^4)]
alpha = 0.01;              % Conversion de Q a potencia termica [W/%]

%% 3. Punto de operacion: calculo de Tbar
% En equilibrio, dT/dt = 0. La temperatura Tbar se obtiene resolviendo el
% balance de potencia para Q = Qbar.
balance_Qbar = @(T) ...
      U*A*(Ta_K - T) ...
    + emisividad*sigmaSB*A*(Tinf_K^4 - T^4) ...
    + alpha*Qbar;

Tbar_K = fzero(balance_Qbar,[Ta_K, Ta_K + 150]);
Tbar_C = Tbar_K - 273.15;

%% 4. Coeficientes del modelo lineal
% gamma = df/dT y beta = df/dQ, evaluados en (Tbar,Qbar).
gamma = -(U*A + 4*emisividad*sigmaSB*A*Tbar_K^3)/(m*cp); % [1/s]
beta = alpha/(m*cp);                                     % [K/(porcentaje s)]

% Forma estandar de primer orden: G(s) = K/(tau*s + 1).
tau = -1/gamma;             % Constante de tiempo [s]
K = -beta/gamma;            % Ganancia estatica [degC/%]

% La construccion de G requiere Control System Toolbox.
G = tf(K,[tau 1]);
G.InputName = 'Delta Q';
G.OutputName = 'Delta T';

fprintf('\nLINEALIZACION DEL MODELO DE LA TCLab\n');
fprintf('Punto de operacion:\n');
fprintf('  Qbar  = %10.4f %%\n',Qbar);
fprintf('  Tbar  = %10.4f degC\n',Tbar_C);
fprintf('  Tbar  = %10.4f K\n\n',Tbar_K);

fprintf('Parametros del modelo lineal:\n');
fprintf('  gamma = %12.6e 1/s\n',gamma);
fprintf('  beta  = %12.6e degC/(%% s)\n',beta);
fprintf('  tau   = %10.4f s\n',tau);
fprintf('  K     = %10.6f degC/%%\n\n',K);

fprintf('Funcion de transferencia en variables de desviacion:\n');
fprintf('                %.4f\n',K);
fprintf('  G(s) = ---------------------  [degC/%%]\n');
fprintf('          %.4f s + 1\n\n',tau);
% disp(G);

%% 5. Simulacion de las dos perturbaciones
dQ_casos = [dQ_pequeno, dQ_grande];
nombres = {'Perturbacion pequena','Perturbacion de mayor amplitud'};

resultados = table('Size',[numel(dQ_casos),7], ...
    'VariableTypes',repmat({'double'},1,7), ...
    'VariableNames',{'DeltaQ_pct','Qfinal_pct','TeqNL_degC', ...
    'TeqLin_degC','ErrorEq_degC','ErrorMax_degC','RMSE_degC'});

opciones = odeset('RelTol',1e-8,'AbsTol',1e-10);

for i = 1:numel(dQ_casos)
    dQ = dQ_casos(i);
    Qfinal = Qbar + dQ;

    if Qfinal < 0 || Qfinal > 100
        error('El caso %d produce Q = %.2f %%, fuera del intervalo [0,100].', ...
            i,Qfinal);
    end

    % Entrada absoluta y perturbacion respecto al punto de operacion.
    Q_fun = @(t) Qbar + dQ*(t >= t_escalon);
    dQ_fun = @(t) dQ*(t >= t_escalon);

    % Modelo no lineal en temperatura absoluta [K].
    modelo_nl = @(t,T) ( ...
          U*A*(Ta_K - T) ...
        + emisividad*sigmaSB*A*(Tinf_K^4 - T^4) ...
        + alpha*Q_fun(t) )/(m*cp);

    % Modelo lineal en la variable de desviacion DeltaT [K o degC].
    modelo_lin = @(t,dT) gamma*dT + beta*dQ_fun(t);

    [t,Tnl_K] = ode45(modelo_nl,t_eval,Tbar_K,opciones);
    [~,dTlin] = ode45(modelo_lin,t_eval,0,opciones);

    Tnl_C = Tnl_K - 273.15;
    Tlin_C = Tbar_C + dTlin;
    Q_t = Qbar + dQ*(t >= t_escalon);
    error_C = Tlin_C - Tnl_C;

    % Equilibrios de ambos modelos despues del cambio de entrada.
    balance_final = @(T) ...
          U*A*(Ta_K - T) ...
        + emisividad*sigmaSB*A*(Tinf_K^4 - T^4) ...
        + alpha*Qfinal;
    Teq_nl_K = fzero(balance_final,[Ta_K, Ta_K + 200]);
    Teq_nl_C = Teq_nl_K - 273.15;
    Teq_lin_C = Tbar_C + K*dQ;

    % Metricas calculadas desde el instante en que se aplica el escalon.
    idx = t >= t_escalon;
    error_max = max(abs(error_C(idx)));
    rmse = sqrt(mean(error_C(idx).^2));

    resultados{i,:} = [dQ,Qfinal,Teq_nl_C,Teq_lin_C, ...
        Teq_lin_C-Teq_nl_C,error_max,rmse];

    %% 6. Graficas de comparacion
    figure('Color','w','Name',nombres{i});

    subplot(3,1,1);
    stairs(t,Q_t,'LineWidth',1.6);
    grid on;
    ylabel('Q_1 [%]');
    title(sprintf('%s: \\DeltaQ = %+.1f %%',nombres{i},dQ));
    ylim([min(Qbar,Qfinal)-5, max(Qbar,Qfinal)+5]);

    subplot(3,1,2);
    plot(t,Tnl_C,'LineWidth',1.7);
    hold on;
    plot(t,Tlin_C,'--','LineWidth',1.7);
    yline(Tbar_C,':','Tbar','LineWidth',1.1);
    grid on;
    ylabel('T_1 [degC]');
    legend('Modelo no lineal','Modelo lineal','Punto de operacion', ...
        'Location','best');
    title('Comparacion de temperaturas absolutas');

    subplot(3,1,3);
    plot(t,error_C,'LineWidth',1.6);
    yline(0,'k:');
    grid on;
    xlabel('Tiempo [s]');
    ylabel('T_{lin}-T_{nl} [degC]');
    title('Error debido a la aproximacion lineal');
end

%% 7. Resumen numerico
fprintf('\nCOMPARACION DE LOS MODELOS\n');
disp(resultados);

fprintf('Interpretacion:\n');
fprintf(['Para cambios pequenos, los terminos de orden superior omitidos en la ', ...
    'linealizacion tienen poca influencia y ambos modelos son similares.\n']);
fprintf(['Al aumentar |DeltaQ|, la temperatura se aleja de Tbar y la perdida ', ...
    'radiativa depende de T^4. Por ello, el error del modelo lineal crece.\n\n']);

%% 8. Preguntas para el informe
% a) Cuales son las unidades de gamma, beta, K y tau?
% b) Por que G(s) relaciona DeltaT con DeltaQ y no T con Q?
% c) Compare el error maximo y el RMSE de los dos casos.
% d) El modelo lineal sobreestima o subestima la temperatura? Explique la
%    respuesta a partir del termino de radiacion.
% e) Repita la simulacion con una perturbacion negativa. La precision del
%    modelo lineal es simetrica alrededor del punto de operacion?
