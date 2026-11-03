function datos = A4a_experimento_escalon_Q1_TCLab(puerto,escalon)
%EXPERIMENTO_ESCALON_Q1_TCLAB Registra la respuesta del TCLab a un escalón.
% Almacenamiento: únicamente .mat en Resultados_experimentos.
%
% El experimento considera el sistema SISO Q1 -> T1. Q1 representa
% directamente el porcentaje del ciclo de trabajo PWM y se limita a un
% máximo del 90 %. El programa solamente aplica la entrada, adquiere,
% guarda y muestra los datos; no realiza identificación ni análisis.
%
% Ejemplo:
%   datos = A4a_experimento_escalon_Q1_TCLab("COM8",50);

arguments
    puerto  (1,1) string = "COM8"
    escalon (1,1) double {mustBeFinite, ...
                          mustBeGreaterThan(escalon,0), ...
                          mustBeLessThanOrEqual(escalon,90)} = 50
end

%% Parámetros del experimento

Q1_pct = escalon;       % Ciclo de trabajo solicitado (%)
PWM_Q1 = Q1_pct/100;    % Argumento de writePWMDutyCycle (0 a 1)

tiempoReposo        = 60;     % s
tiempoCalentamiento = 1800;   % s
Ts                  = 1;      % s
nPromedio           = 10;     % Lecturas de tensión por muestra

% Límites de seguridad y validación de T1
Tmax       = 90;     % °C: corte térmico
TminSensor = -40;    % °C: límite inferior plausible del TMP36
TmaxSensor = 125;    % °C: límite superior plausible del TMP36

% Carpeta para almacenar los resultados experimentales.
carpetaResultados = fullfile(pwd,"Resultados_experimentos");

if ~isfolder(carpetaResultados)
    mkdir(carpetaResultados)
    fprintf("Carpeta creada: %s\n",carpetaResultados)
end

fechaInicio = datetime("now");
marcaTiempo = string(datetime("now",Format="yyyyMMdd_HHmmss"));
nombreBase  = compose("escalon_Q1_%02.0f_%s",Q1_pct,marcaTiempo);
rutaMAT     = string(fullfile(carpetaResultados,nombreBase + ".mat"));

%% Conexión y protección

a = arduino(puerto,"Leonardo");

% Mantener este objeto activo garantiza el apagado al terminar la función,
% ante un error o ante una interrupción manual.
proteccion = onCleanup(@() apagarSalidas(a)); %#ok<NASGU>

apagarSalidas(a);

%% Preasignación

duracionTotal = tiempoReposo + tiempoCalentamiento;
nMuestrasMax  = floor(duracionTotal/Ts) + 1;

t    = zeros(nMuestrasMax,1);
T1   = NaN(nMuestrasMax,1);
Q1   = zeros(nMuestrasMax,1);
PWM  = zeros(nMuestrasMax,1);
fase = strings(nMuestrasMax,1);

corteTermico       = false;
falloSensor         = false;
motivoFinalizacion = "Duración programada completada";
tiempoEscalonReal  = NaN;

fprintf("Experimento de escalón iniciado\n")
fprintf("Sistema SISO: Q1 -> T1\n")
fprintf("Q1: 0 -> %.0f %% | PWM: %.2f\n",Q1_pct,PWM_Q1)
fprintf("Reposo: %.0f s | Calentamiento: %.0f s\n", ...
        tiempoReposo,tiempoCalentamiento)
fprintf("Límite térmico: %.1f °C\n\n",Tmax)

%% Adquisición

reloj     = tic;
k         = 0;
finalizar = false;

while ~finalizar && k < nMuestrasMax

    k = k + 1;
    tiempoProgramado = (k-1)*Ts;

    % Esperar el instante programado sin acumular el error de pause.
    espera = tiempoProgramado - toc(reloj);

    if espera > 0
        pause(espera)
    end

    % Determinar y aplicar la entrada antes de adquirir T1.
    if tiempoProgramado < tiempoReposo
        fase(k) = "Reposo";
        Q1(k)   = 0;
        PWM(k)  = 0;
    else
        fase(k) = "Calentamiento";
        Q1(k)   = Q1_pct;
        PWM(k)  = PWM_Q1;
    end

    writePWMDutyCycle(a,"D3",PWM(k));  % Q1
    writePWMDutyCycle(a,"D5",0);       % Q2 siempre apagado
    writePWMDutyCycle(a,"D9",0);       % LED apagado

    % Registrar el instante real asociado con la entrada de esta fila.
    t(k) = toc(reloj);

    if isnan(tiempoEscalonReal) && Q1(k) > 0
        tiempoEscalonReal = t(k);
    end

    % Lectura de T1.
    T1(k) = leerTemperatura(a,"A0",nPromedio);

    % Validación básica del sensor T1.
    lecturaInvalida = ~isfinite(T1(k)) || ...
                      T1(k) < TminSensor || T1(k) > TmaxSensor;

    if lecturaInvalida
        falloSensor         = true;
        motivoFinalizacion = "Lectura de sensor inválida";
        fase(k)             = "Fallo de sensor";
        apagarSalidas(a);
        finalizar = true;

    elseif T1(k) >= Tmax
        corteTermico       = true;
        motivoFinalizacion = "Corte térmico";
        fase(k)            = "Corte térmico";
        apagarSalidas(a);
        finalizar = true;
    end

    % Q1(k) y PWM(k) conservan la entrada aplicada durante esta medición,
    % incluso si inmediatamente después se produjo un apagado de seguridad.
    fprintf( ...
        "t=%7.1f s | %-16s | Q1=%3.0f %% | T1=%6.2f °C\n", ...
        t(k),fase(k),Q1(k),T1(k));
end

%% Apagado, organización y almacenamiento

apagarSalidas(a);

% Eliminar posiciones no utilizadas.
t    = t(1:k);
fase = fase(1:k);
Q1   = Q1(1:k);
PWM  = PWM(1:k);
T1   = T1(1:k);

datos = table(t,fase,Q1,PWM,T1, ...
    VariableNames=["Tiempo_s","Fase","Q1_pct","PWM","T1_C"]);

metadatos = struct( ...
    "FechaInicio",fechaInicio, ...
    "Puerto",puerto, ...
    "Placa","Leonardo", ...
    "Sistema","Q1 -> T1", ...
    "Ts_s",Ts, ...
    "NumeroPromedios",nPromedio, ...
    "Q1_pct",Q1_pct, ...
    "PWM_Q1",PWM_Q1, ...
    "TiempoReposo_s",tiempoReposo, ...
    "TiempoCalentamiento_s",tiempoCalentamiento, ...
    "TiempoEscalonReal_s",tiempoEscalonReal, ...
    "Tmax_C",Tmax, ...
    "CorteTermico",corteTermico, ...
    "FalloSensor",falloSensor, ...
    "MotivoFinalizacion",motivoFinalizacion, ...
    "ArchivoMAT",rutaMAT);

datos.Properties.Description = ...
    "Datos sin procesar del sistema SISO Q1 -> T1 ante un escalón";

datos.Properties.UserData = metadatos;

% El archivo MAT conserva la tabla y sus metadatos.
save(rutaMAT,"datos")

fprintf("\nExperimento finalizado\n")
fprintf("Motivo: %s\n",motivoFinalizacion)
fprintf("Muestras registradas: %d\n",height(datos))
fprintf("Duración registrada: %.1f s\n",t(end))
fprintf("Archivo MAT: %s\n",rutaMAT)
fprintf("Todas las salidas quedaron apagadas.\n")

%% Visualización de los datos adquiridos

nombreFigura = compose("Escalón Q1 - %.0f %%",Q1_pct);
figure(Name=nombreFigura)

tiledlayout(2,1)

nexttile
plot(t,T1,LineWidth=1.3)

if isfinite(tiempoEscalonReal)
    xline(tiempoEscalonReal,"--k","Aplicación del escalón")
end

yline(Tmax,"--r","Límite térmico")
grid on
ylabel("T_1 (°C)")
title(compose("Respuesta térmica para Q_1 = %.0f %%",Q1_pct))

nexttile
stairs(t,Q1,LineWidth=1.3)
grid on
xlabel("Tiempo (s)")
ylabel("Q_1 (%)")
ylim([0 max(35,1.1*Q1_pct)])

end


function T = leerTemperatura(a,pin,n)
%LEERTEMPERATURA Promedia n lecturas del TMP36 y convierte a °C.

V = zeros(n,1);

for i = 1:n
    V(i) = readVoltage(a,pin);
end

T = (mean(V)-0.5)*100;

end


function apagarSalidas(a)
%APAGARSALIDAS Lleva a cero los calentadores y el LED del TCLab.

try
    writePWMDutyCycle(a,"D3",0);
    writePWMDutyCycle(a,"D5",0);
    writePWMDutyCycle(a,"D9",0);
catch ME
    warning("TCLab:ApagadoNoConfirmado", ...
        "No fue posible confirmar el apagado de las salidas: %s", ...
        ME.message)
end

end
