%% ACTIVIDAD 1: SIMULACION DEL MODELO NO LINEAL DE LA TCLab
% Este script simula la temperatura T1 cuando el calentador Q1 se mantiene
% en 50 %. El modelo se obtiene mediante un balance de energia:
%
%   m*cp*dT/dt = U*A*(Ta - T) ...
%              + emisividad*sigma*A*(Tinf^4 - T^4) ...
%              + alpha*Q
%
% IMPORTANTE: las temperaturas se expresan en kelvin dentro del modelo,
% especialmente en el termino de radiacion.

clearvars; close all; clc;

%% 1. Condiciones de la simulacion
% Sustituya este valor por la temperatura ambiente medida al inicio de la
% practica.
Tamb_C = 24.5;             % Temperatura ambiente medida [degC]

Q = 50.0;                  % Entrada constante del calentador [%]
t_final = 1200;            % Duracion de la simulacion [s]
tspan = [0 t_final];

% Se supone que la temperatura del aire y la temperatura radiativa efectiva
% del entorno son iguales a la temperatura ambiente medida.
Ta_K = Tamb_C + 273.15;    % Temperatura del aire [K]
Tinf_K = Ta_K;             % Temperatura radiativa del entorno [K]
T0_K = Ta_K;               % Condicion inicial [K]

%% 2. Parametros nominales del modelo
m = 0.004;                 % Masa termica efectiva [kg]
cp = 500;                  % Calor especifico [J/(kg K)]
A = 1.2e-3;                % Area efectiva de transferencia [m^2]
U = 5;                     % Coeficiente global [W/(m^2 K)]
emisividad = 0.9;          % Emisividad [-]
sigmaSB = 5.67e-8;         % Constante de Stefan-Boltzmann [W/(m^2 K^4)]
alpha = 0.01;              % Conversion de Q a potencia termica [W/%]

%% 3. Modelo no lineal y simulacion
% Q se mantiene constante, pero se conserva como argumento para que la
% ecuacion pueda modificarse facilmente en actividades posteriores.
modelo = @(t,T) ( ...
      U*A*(Ta_K - T) ...
    + emisividad*sigmaSB*A*(Tinf_K^4 - T^4) ...
    + alpha*Q )/(m*cp);

opciones = odeset('RelTol',1e-8,'AbsTol',1e-10);
[t,T_K] = ode45(modelo,tspan,T0_K,opciones);

T_C = T_K - 273.15;        % Temperatura para presentacion [degC]
Q_t = Q*ones(size(t));      % Entrada aplicada durante la simulacion [%]

%% 4. Temperatura de equilibrio predicha
% En equilibrio dT/dt = 0. Se resuelve numericamente el balance de potencia.
balance = @(T) ...
      U*A*(Ta_K - T) ...
    + emisividad*sigmaSB*A*(Tinf_K^4 - T^4) ...
    + alpha*Q;

T_eq_K = fzero(balance,[Ta_K, Ta_K + 150]);
T_eq_C = T_eq_K - 273.15;

fprintf('\nMODELO NO LINEAL DE LA TCLab\n');
fprintf('Temperatura ambiente:       %8.3f degC\n',Tamb_C);
fprintf('Entrada del calentador:     %8.3f %%\n',Q);
fprintf('Temperatura final simulada: %8.3f degC\n',T_C(end));
fprintf('Temperatura de equilibrio:  %8.3f degC\n',T_eq_C);
fprintf('Diferencia final-equilibrio: %7.4f degC\n\n', ...
    T_C(end)-T_eq_C);

%% 5. Tasas de transferencia de calor
% Se representan como perdidas positivas desde la TCLab hacia el entorno.
q_conv_W = U*A*(T_K - Ta_K);
q_rad_W = emisividad*sigmaSB*A*(T_K.^4 - Tinf_K^4);
q_cal_W = alpha*Q_t;
q_total_perdida_W = q_conv_W + q_rad_W;

%% 6. Graficas de Q(t) y T(t)
figure('Color','w','Name','Entrada y temperatura');

subplot(2,1,1);
plot(t,Q_t,'LineWidth',1.6);
grid on;
xlabel('Tiempo [s]');
ylabel('Q_1 [%]');
title('Entrada del calentador');
ylim([0 1.15*Q]);

subplot(2,1,2);
plot(t,T_C,'LineWidth',1.6);
hold on;
yline(T_eq_C,'--','T_{eq}','LineWidth',1.3, ...
    'LabelHorizontalAlignment','left');
grid on;
xlabel('Tiempo [s]');
ylabel('T_1 [degC]');
title('Temperatura predicha por el modelo no lineal');

%% 7. Graficas separadas de conveccion y radiacion
figure('Color','w','Name','Transferencia de calor');

subplot(2,1,1);
plot(t,q_conv_W,'LineWidth',1.6);
grid on;
xlabel('Tiempo [s]');
ylabel('q_{conv} [W]');
title('Perdida de calor por conveccion');

subplot(2,1,2);
plot(t,q_rad_W,'LineWidth',1.6);
grid on;
xlabel('Tiempo [s]');
ylabel('q_{rad} [W]');
title('Perdida de calor por radiacion');

%% 8. Comprobacion del balance de potencia
figure('Color','w','Name','Balance de potencia');
plot(t,q_cal_W,'LineWidth',1.6);
hold on;
plot(t,q_conv_W,'--','LineWidth',1.5);
plot(t,q_rad_W,'-.','LineWidth',1.5);
plot(t,q_total_perdida_W,':','LineWidth',2.0);
grid on;
xlabel('Tiempo [s]');
ylabel('Potencia termica [W]');
title('Potencia suministrada y perdidas termicas');
legend('Calentador','Conveccion','Radiacion','Perdidas totales', ...
    'Location','best');

%% 9. Preguntas para el analisis de incertidumbre
% a) Cuales parametros son propiedades fisicas conocidas con mayor certeza?
% b) Cuales parametros son efectivos o dependen del montaje y del ambiente?
% c) Como cambiaria T_eq si U, emisividad, A o alpha fueran mayores?
% d) Como afectarian m y cp la rapidez de la respuesta? Cambiarian T_eq?
%
% Sugerencia: modifique un parametro a la vez en +/-10 % y compare las
% respuestas. No ajuste los parametros para forzar coincidencia con los datos
% experimentales; esa calibracion se abordara durante la identificacion.
