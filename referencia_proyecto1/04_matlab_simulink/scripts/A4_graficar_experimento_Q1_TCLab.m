function A4c_graficar_experimento_Q1_TCLab()
%GRAFICAR_EXPERIMENTO_Q1_TCLAB
% Selecciona un archivo .mat de un experimento Q1 -> T1 del TCLab
% y genera nuevamente la figura de entrada y salida.
%
% Compatible con:
%   - Experimento de escalón
%   - Experimento multinivel

%% Selección del archivo

carpetaResultados = fullfile(pwd,"Resultados_experimentos");

if ~isfolder(carpetaResultados)
    carpetaResultados = pwd;
end

[nombreArchivo,rutaArchivo] = uigetfile( ...
    fullfile(carpetaResultados,"*.mat"), ...
    "Seleccione el archivo del experimento");

if isequal(nombreArchivo,0)
    disp("Selección cancelada.")
    return
end

archivoMAT = fullfile(rutaArchivo,nombreArchivo);

%% Carga de datos

S = load(archivoMAT,"datos");

if ~isfield(S,"datos")
    error("El archivo seleccionado no contiene la variable 'datos'.")
end

datos = S.datos;

%% Variables comunes

t  = datos.Tiempo_s;
T1 = datos.T1_C;
Q1 = datos.Q1_pct;

metadatos = datos.Properties.UserData;
Tmax = metadatos.Tmax_C;

%% Identificar tipo de experimento

if isfield(metadatos,"Q1_pct")

    tipoExperimento = "escalon";

elseif isfield(metadatos,"NivelesQ1_pct")

    tipoExperimento = "multinivel";

else

    error("No se pudo identificar el tipo de experimento.")

end

%% Generación de la figura

switch tipoExperimento

    case "escalon"

        Q1_pct = metadatos.Q1_pct;
        tiempoEscalonReal = metadatos.TiempoEscalonReal_s;

        nombreFigura = compose("Escalón Q1 - %.0f %%",Q1_pct);

        figure(Name=nombreFigura)
        tiledlayout(2,1)

        % Salida
        nexttile
        plot(t,T1,LineWidth=1.3)

        if isfinite(tiempoEscalonReal)
            xline(tiempoEscalonReal,"--k","Aplicación del escalón")
        end

        yline(Tmax,"--r","Límite térmico")
        grid on
        ylabel("T_1 (°C)")
        title(compose("Respuesta térmica para Q_1 = %.0f %%",Q1_pct))

        % Entrada
        nexttile
        stairs(t,Q1,LineWidth=1.3)
        grid on
        xlabel("Tiempo (s)")
        ylabel("Q_1 (%)")
        ylim([0 max(35,1.1*Q1_pct)])


    case "multinivel"

        nivelesQ1_pct = metadatos.NivelesQ1_pct;

        figure(Name="Experimento multinivel Q1")
        tiledlayout(2,1)

        % Salida
        nexttile
        plot(t,T1,LineWidth=1.3)
        yline(Tmax,"--r","Límite térmico")
        grid on
        ylabel("T_1 (°C)")
        title("Respuesta térmica al perfil multinivel")

        % Entrada
        nexttile
        stairs(t,Q1,LineWidth=1.3)
        grid on
        xlabel("Tiempo (s)")
        ylabel("Q_1 (%)")
        ylim([0 max(55,1.1*max(nivelesQ1_pct))])

end

end