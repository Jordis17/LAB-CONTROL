function datos = A4b_experimento_multinivel_Q1_TCLab(puerto)
%EXPERIMENTO_MULTINIVEL_Q1_TCLAB Registra la respuesta a varios niveles de Q1.
% Almacenamiento: únicamente .mat en Resultados_experimentos.
%
% El experimento considera el sistema SISO Q1 -> T1. El programa solamente
% aplica el perfil, adquiere, guarda y muestra los datos; no realiza
% identificación ni análisis de la respuesta.
%
% Perfil programado:
%   Q1 (%)      0    20    40    10    50    30     0
%   Duración  120   500   500   500   500   500   900 s
%
% Ejemplo:
%   datos = experimento_multinivel_Q1_TCLab("COM8");

arguments
    puerto (1,1) string = "COM8"
end

%% Perfil y parámetros del experimento

nivelesQ1_pct = [0 20 40 10 50 30 0];
duraciones_s  = [120 500 500 500 500 500 900];

if numel(nivelesQ1_pct) ~= numel(duraciones_s)
    error("TCLab:PerfilInvalido", ...
        "Cada nivel de Q1 debe tener una duración asociada.")
end

if any(~isfinite(nivelesQ1_pct)) || ...
        any(nivelesQ1_pct < 0 | nivelesQ1_pct > 90)
    error("TCLab:PerfilInvalido", ...
        "Los niveles de Q1 deben estar entre 0 y 90 %%.")
end

if any(~isfinite(duraciones_s)) || any(duraciones_s <= 0)
    error("TCLab:PerfilInvalido", ...
        "Todas las duraciones deben ser positivas y finitas.")
end

Ts        = 1;      % s
nPromedio = 10;     % Lecturas de tensión por muestra

% Límites de seguridad y validación de T1
Tmax       = 90;    % °C: corte térmico
TminSensor = -40;   % °C: límite inferior plausible del TMP36
TmaxSensor = 125;   % °C: límite superior plausible del TMP36

numeroEtapas   = numel(nivelesQ1_pct);
finalesEtapa_s = cumsum(duraciones_s);
duracionTotal  = finalesEtapa_s(end);

perfil = table((1:numeroEtapas)',nivelesQ1_pct',duraciones_s', ...
    finalesEtapa_s', ...
    VariableNames=["Etapa","Q1_pct","Duracion_s","Fin_s"]);

% Carpeta para almacenar los resultados experimentales.
carpetaResultados = fullfile(pwd,"Resultados_experimentos");

if ~isfolder(carpetaResultados)
    mkdir(carpetaResultados)
    fprintf("Carpeta creada: %s\n",carpetaResultados)
end

fechaInicio = datetime("now");
marcaTiempo = string(datetime("now",Format="yyyyMMdd_HHmmss"));
nombreBase  = "multinivel_Q1_" + marcaTiempo;
rutaMAT     = string(fullfile(carpetaResultados,nombreBase + ".mat"));

%% Conexión y protección

a = arduino(puerto,"Leonardo");

% Mantener este objeto activo garantiza el apagado al terminar la función,
% ante un error o ante una interrupción manual.
proteccion = onCleanup(@() apagarSalidas(a)); %#ok<NASGU>

apagarSalidas(a);

%% Preasignación

nMuestrasMax = floor(duracionTotal/Ts) + 1;

t      = zeros(nMuestrasMax,1);
etapa  = zeros(nMuestrasMax,1);
T1     = NaN(nMuestrasMax,1);
Q1     = zeros(nMuestrasMax,1);
PWM    = zeros(nMuestrasMax,1);
estado = strings(nMuestrasMax,1);

tiemposCambioReal_s = NaN(numeroEtapas,1);

corteTermico       = false;
falloSensor         = false;
motivoFinalizacion = "Duración programada completada";

fprintf("Experimento multinivel iniciado\n")
fprintf("Sistema SISO: Q1 -> T1\n")
fprintf("Duración programada: %.0f s (%.1f min)\n", ...
        duracionTotal,duracionTotal/60)
fprintf("Periodo de muestreo: %.1f s\n",Ts)
fprintf("Límite térmico: %.1f °C\n\n",Tmax)
disp(perfil)

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

    % La desigualdad estricta hace que cada cambio ocurra exactamente al
    % comienzo de la etapa siguiente. La muestra en la duración total
    % permanece en la última etapa.
    indiceEtapa = find(tiempoProgramado < finalesEtapa_s,1,"first");

    if isempty(indiceEtapa)
        indiceEtapa = numeroEtapas;
    end

    etapa(k)  = indiceEtapa;
    Q1(k)     = nivelesQ1_pct(indiceEtapa);
    PWM(k)    = Q1(k)/100;
    estado(k) = compose("Etapa %d",indiceEtapa);

    % Aplicar la entrada antes de adquirir T1.
    writePWMDutyCycle(a,"D3",PWM(k));  % Q1
    writePWMDutyCycle(a,"D5",0);       % Q2 siempre apagado
    writePWMDutyCycle(a,"D9",0);       % LED apagado

    % Registrar el instante real asociado con la entrada de esta fila.
    t(k) = toc(reloj);

    if k == 1 || etapa(k) ~= etapa(k-1)
        tiemposCambioReal_s(indiceEtapa) = t(k);
    end

    % Lectura de T1.
    T1(k) = leerTemperatura(a,"A0",nPromedio);

    % Validación básica del sensor T1.
    lecturaInvalida = ~isfinite(T1(k)) || ...
                      T1(k) < TminSensor || T1(k) > TmaxSensor;

    if lecturaInvalida
        falloSensor         = true;
        motivoFinalizacion = "Lectura de sensor inválida";
        estado(k)           = "Fallo de sensor";
        apagarSalidas(a);
        finalizar = true;

    elseif T1(k) >= Tmax
        corteTermico       = true;
        motivoFinalizacion = "Corte térmico";
        estado(k)          = "Corte térmico";
        apagarSalidas(a);
        finalizar = true;
    end

    % Q1(k) y PWM(k) conservan la entrada aplicada durante esta medición,
    % incluso si inmediatamente después se produjo un apagado de seguridad.
    fprintf( ...
        "t=%7.1f s | Etapa=%d | Q1=%3.0f %% | T1=%6.2f °C\n", ...
        t(k),etapa(k),Q1(k),T1(k));
end

%% Apagado, organización y almacenamiento

apagarSalidas(a);

% Eliminar posiciones no utilizadas.
t      = t(1:k);
etapa  = etapa(1:k);
estado = estado(1:k);
Q1     = Q1(1:k);
PWM    = PWM(1:k);
T1     = T1(1:k);

datos = table(t,etapa,estado,Q1,PWM,T1, ...
    VariableNames=[ ...
        "Tiempo_s","Etapa","Estado","Q1_pct","PWM","T1_C"]);

metadatos = struct( ...
    "FechaInicio",fechaInicio, ...
    "Puerto",puerto, ...
    "Placa","Leonardo", ...
    "Sistema","Q1 -> T1", ...
    "Ts_s",Ts, ...
    "NumeroPromedios",nPromedio, ...
    "NivelesQ1_pct",nivelesQ1_pct, ...
    "Duraciones_s",duraciones_s, ...
    "DuracionProgramada_s",duracionTotal, ...
    "TiemposCambioReal_s",tiemposCambioReal_s, ...
    "Tmax_C",Tmax, ...
    "CorteTermico",corteTermico, ...
    "FalloSensor",falloSensor, ...
    "MotivoFinalizacion",motivoFinalizacion, ...
    "ArchivoMAT",rutaMAT);

datos.Properties.Description = ...
    "Datos sin procesar del sistema SISO Q1 -> T1 con entrada multinivel";
datos.Properties.UserData = metadatos;

% El archivo MAT conserva la tabla, el perfil y todos los metadatos.
save(rutaMAT,"datos")

fprintf("\nExperimento finalizado\n")
fprintf("Motivo: %s\n",motivoFinalizacion)
fprintf("Muestras registradas: %d\n",height(datos))
fprintf("Duración registrada: %.1f s\n",t(end))
fprintf("Archivo MAT: %s\n",rutaMAT)
fprintf("Todas las salidas quedaron apagadas.\n")

%% Visualización de los datos adquiridos

figure(Name="Experimento multinivel Q1")
tiledlayout(2,1)

nexttile
plot(t,T1,LineWidth=1.3)
yline(Tmax,"--r","Límite térmico")
grid on
ylabel("T_1 (°C)")
title("Respuesta térmica al perfil multinivel")

nexttile
stairs(t,Q1,LineWidth=1.3)
grid on
xlabel("Tiempo (s)")
ylabel("Q_1 (%)")
ylim([0 max(55,1.1*max(nivelesQ1_pct))])

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
