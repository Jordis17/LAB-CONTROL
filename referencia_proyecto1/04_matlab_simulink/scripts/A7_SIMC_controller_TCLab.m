%% Actividad 7: Diseno del controlador PI mediante SIMC
% Este script calcula los parametros de un controlador PI continuo a partir
% del modelo FOPDT nominal seleccionado despues de la validacion cruzada.

clearvars; close all; clc;

%% 1. Identificacion del modelo nominal
% Sustituya estos datos por los correspondientes a la unidad TCLab utilizada
% y al modelo seleccionado despues de la validacion cruzada.

codigoTCLab = "TCLab01";
origenModelo = "escalon";     % "escalon" o "multinivel"

K     = 0.979353;               % Ganancia estatica [degC/%]
tau   = 179.112;              % Constante de tiempo [s]
theta = 7.996;               % Tiempo muerto [s]

%% 2. Comprobacion de los parametros

if any(~isfinite([K tau theta])) || any([K tau theta] <= 0)
    error("Los parametros deben satisfacer K > 0, tau > 0 y theta > 0.");
end

if ~ismember(origenModelo, ["escalon" "multinivel"])
    error('origenModelo debe ser "escalon" o "multinivel".');
end

% Modelo FOPDT nominal en variables de desviacion:
%
%       DeltaT1(s)          K exp(-theta*s)
% Gp = ----------- = --------------------------
%       DeltaQ1(s)              tau*s + 1

Gp = tf(K, [tau 1], "InputDelay", theta);

%% 3. Sintonia del controlador PI mediante SIMC
% tau_c = theta   produce una respuesta mas rapida.
% tau_c > theta   produce una respuesta mas suave y robusta.
% En esta practica se utiliza tau_c = 2*theta.

tau_c = 2*theta;              % Tiempo de respuesta deseado [s]

Kp = tau/(K*(tau_c + theta)); % Ganancia proporcional [%/degC]
Ti = min(tau, ...
    4*(tau_c + theta));       % Tiempo integral [s]
Ki = Kp/Ti;                   % Ganancia integral [%/(degC*s)]

if any(~isfinite([tau_c Kp Ti Ki])) || ...
        any([tau_c Kp Ti Ki] <= 0)
    error("La sintonia SIMC produjo parametros no validos.");
end

% Forma paralela continua:
%
%             Ki
% Gc(s) = Kp + --
%              s

Gc = tf([Kp Ki], [1 0]);

%% 4. Presentacion de los resultados

fprintf("\nMODELO NOMINAL FOPDT\n");
fprintf("Unidad TCLab:       %s\n", codigoTCLab);
fprintf("Datos de origen:    %s\n", origenModelo);
fprintf("K     = %10.6f degC/%%\n", K);
fprintf("tau   = %10.3f s\n", tau);
fprintf("theta = %10.3f s\n", theta);

fprintf("\nCONTROLADOR PI MEDIANTE SIMC\n");
fprintf("tau_c = %10.3f s\n", tau_c);
fprintf("Kp    = %10.6f %%/degC\n", Kp);
fprintf("Ti    = %10.3f s\n", Ti);
fprintf("Ki    = %10.6f %%/(degC*s)\n", Ki);

%% 5. Guardado de los resultados

carpetaResultados = "Resultados_control";

if ~isfolder(carpetaResultados)
    mkdir(carpetaResultados);
end

marcaTiempo = string(datetime("now", ...
    "Format", "yyyyMMdd_HHmmss"));

nombreArchivo = "PI_SIMC_" + codigoTCLab + ...
    "_" + marcaTiempo + ".mat";

rutaMAT = fullfile(carpetaResultados, nombreArchivo);

save(rutaMAT, ...
    "codigoTCLab", "origenModelo", ...
    "K", "tau", "theta", ...
    "tau_c", "Kp", "Ti", "Ki", ...
    "Gp", "Gc");

fprintf("\nResultados guardados en:\n%s\n", rutaMAT);
