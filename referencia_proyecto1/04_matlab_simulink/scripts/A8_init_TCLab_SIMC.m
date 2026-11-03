%% Inicializacion del modelo MIL del TCLab en Simulink
% Controlador PI sintonizado mediante SIMC/IMC.
% Ejecute este script antes de abrir o simular el modelo de Simulink.

%% Modelo FOPDT identificado
%                    K
% Gp(s) = ---------------------- exp(-theta*s)
%               tau*s + 1

codigoTCLab = "TCLab01";
origenModelo = "escalon";     % "escalon" o "multinivel"

K     = 0.979353;               % Ganancia estatica [degC/%]
tau   = 179.112;              % Constante de tiempo [s]
theta = 8;               % Tiempo muerto [s]

% Se conservan por separado la dinámica y el retardo puro. Esto permite
% representar el retardo explícitamente mediante Integer Delay en Simulink.
Gp_sin_retardo = tf(K, [tau 1]);

Gp = Gp_sin_retardo;
Gp.InputDelay = theta;

%% Tiempo de muestreo y modelo discreto

Ts = 1;                    % Tiempo de muestreo [s]

% Discretizacion mediante retenedor de orden cero. El retardo físico no se
% incluye aqui porque se implementara como un bloque independiente.
Gp_d = c2d(Gp_sin_retardo, Ts, 'zoh');

% Coeficientes para el bloque Discrete Transfer Fcn.
[num_Gp_d, den_Gp_d] = tfdata(Gp_d, 'v');

% El retardo se implementara mediante un bloque Integer Delay.
% El retardo se representa mediante un numero entero de muestras.
N_delay = round(theta/Ts);

theta_d = round(N_delay*Ts);

fprintf('Retardo identificado       = %.3f s\n', theta);
fprintf('Retardo discreto utilizado = %.3f s (%d muestras)\n', ...
    theta_d, N_delay);

% Modelo discreto completo, útil para comprobaciones en MATLAB. En un
% sistema discreto, InputDelay se expresa como un numero de muestras.
Gp_d_completo = Gp_d;
Gp_d_completo.InputDelay = N_delay;

%% Condiciones de operación y restricciones

T_amb = 24;                % Temperatura ambiente inicial [degC]
T_ref = 60;                % Referencia inicial [degC]

T_ref_min = 50;            % Referencia mínima permitida [degC]
T_ref_max = 70;            % Referencia máxima permitida [degC]

Q_min = 0;                 % Potencia mínima [%]
Q_max = 90;                % Potencia máxima [%]
T_max = 90;                % Límite de seguridad [degC]

assert(T_ref >= T_ref_min && T_ref <= T_ref_max, ...
    'T_ref debe estar entre T_ref_min y T_ref_max.');

%% Sintonizacion PI mediante SIMC/IMC

% tau_c = theta   : respuesta rápida y más agresiva.
% tau_c = 2*theta : respuesta más conservadora.
tau_c = 2*theta;

Kp_SIMC = tau/(K*(tau_c + theta));
Ti_SIMC = min(tau, 4*(tau_c + theta));
Ki_SIMC = Kp_SIMC/Ti_SIMC;

% Controlador continuo, util para inspeccion y comparaciones.
C_SIMC = pid(Kp_SIMC, Ki_SIMC);

% Discretizacion explicita del PI. Para este controlador, ZOH produce la
% misma actualizacion del integrador Forward Euler usada en el script:
%
% I[k+1] = I[k] + Ki*Ts*e[k]
C_SIMC_d = c2d(C_SIMC, Ts, 'zoh');

assert(strcmp(C_SIMC_d.IFormula, 'ForwardEuler'), ...
    'La discretizacion del PI no produjo el integrador Forward Euler.');

% Coeficientes disponibles para inspeccion o verificacion.
[num_C_SIMC_d, den_C_SIMC_d] = tfdata(C_SIMC_d, 'v');

% Para reproducir C_SIMC_d en el bloque Discrete PID Controller:
%   Controller:          PI
%   Form:                Parallel
%   Time domain:         Discrete-time
%   Integrator method:   Forward Euler
%   Sample time:         Ts
%   Initial condition:   0
Kd_SIMC = 0;
I0_SIMC = 0;

%% Parametros de simulacion

t_final = 1800;            % Tiempo final de simulacion [s]

% Requisitos usados para evaluar el caso fisicamente realizable.
ts_max = 600;               % Tiempo de establecimiento maximo [s]
OS_max = 5;                 % Sobreimpulso maximo [%]

%% Resumen

fprintf('\nModelo FOPDT del TCLab\n');
fprintf('K       = %.6f degC/%%\n', K);
fprintf('tau     = %.3f s\n', tau);
fprintf('theta   = %.3f s (%d muestras)\n', theta, N_delay);
fprintf('Ts      = %.3f s\n', Ts);

disp('Planta discreta sin retardo:');
Gp_d

disp('Planta discreta completa:');
Gp_d_completo

fprintf('\nControlador PI SIMC/IMC\n');
fprintf('tau_c   = %.3f s\n', tau_c);
fprintf('Kp      = %.6f %%/degC\n', Kp_SIMC);
fprintf('Ti      = %.3f s\n', Ti_SIMC);
fprintf('Ki      = %.6f %%/(degC*s)\n', Ki_SIMC);

disp('Controlador PI discreto:');
C_SIMC_d

fprintf('\nCondiciones de simulacion\n');
fprintf('T_amb   = %.2f degC\n', T_amb);
fprintf('T_ref   = %.2f degC\n', T_ref);
fprintf('Q1      = [%.0f, %.0f] %%\n', Q_min, Q_max);
fprintf('t_final = %.0f s\n\n', t_final);
