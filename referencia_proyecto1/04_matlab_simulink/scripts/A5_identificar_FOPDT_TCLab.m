function resultado = A5_identificar_FOPDT_TCLab(archivoMAT)
%IDENTIFICAR_FOPDT_TCLAB Identifica un modelo FOPDT a partir de datos del TCLab.
%
% El modelo identificado, expresado en variables de desviacion, es
%
%                 Delta T1(s)       K exp(-theta s)
%       G(s) = ------------------ = ----------------
%                 Delta Q1(s)          tau s + 1
%
% donde Q1 se expresa en porcentaje. Por tanto, K tiene unidades de
% grados Celsius por punto porcentual de Q1.
%
% La funcion acepta los archivos MAT producidos tanto por el experimento
% de escalon como por el experimento multinivel. La tabla debe contener
% las variables Tiempo_s, Q1_pct y T1_C; cualquier otra variable se ignora.
%
% Uso con un archivo especificado:
%   modeloMultinivel = A5_identificar_FOPDT_TCLab( ...
%       "Resultados_experimentos/multinivel_Q1_20260801_084154.mat");
%   modeloEscalon = A5_identificar_FOPDT_TCLab( ...
%       "Resultados_experimentos/escalon_Q1_50_20260801_100851.mat");
%
% Uso con selector de archivos:
%   modelo = A5_identificar_FOPDT_TCLab();
%
% La identificacion minimiza la suma de errores cuadrados. Para cada valor
% candidato del retardo se optimiza tau con FMINBND y se calcula el valor
% optimo de K por minimos cuadrados. No requiere Optimization Toolbox.

arguments
    archivoMAT (1,1) string = ""
end

%% Seleccion y carga del archivo

if strlength(archivoMAT) == 0
    carpetaInicial = fullfile(pwd,"Resultados_experimentos");

    if ~isfolder(carpetaInicial)
        carpetaInicial = pwd;
    end

    [nombreArchivo,carpetaArchivo] = uigetfile( ...
        fullfile(carpetaInicial,"*.mat"), ...
        "Seleccione los resultados experimentales");

    if isequal(nombreArchivo,0)
        error("TCLab:SeleccionCancelada", ...
            "No se selecciono ningun archivo.")
    end

    archivoMAT = string(fullfile(carpetaArchivo,nombreArchivo));
end

if ~isfile(archivoMAT)
    error("TCLab:ArchivoNoEncontrado", ...
        "No se encontro el archivo: %s",archivoMAT)
end

contenido = load(archivoMAT);
datos     = extraerTablaExperimental(contenido);

%% Extraccion y validacion de las senales SISO

nombresRequeridos = ["Tiempo_s","Q1_pct","T1_C"];
nombresDisponibles = string(datos.Properties.VariableNames);

if ~all(ismember(nombresRequeridos,nombresDisponibles))
    faltantes = nombresRequeridos(~ismember( ...
        nombresRequeridos,nombresDisponibles));
    error("TCLab:VariablesFaltantes", ...
        "Faltan las variables requeridas: %s",join(faltantes,", "))
end

t = double(datos.Tiempo_s(:));
u = double(datos.Q1_pct(:));
y = double(datos.T1_C(:));

filasValidas = isfinite(t) & isfinite(u) & isfinite(y);

if ~all(filasValidas)
    warning("TCLab:FilasInvalidas", ...
        "Se eliminaron %d filas con datos no finitos.",sum(~filasValidas))
    t = t(filasValidas);
    u = u(filasValidas);
    y = y(filasValidas);
end

if numel(t) < 20
    error("TCLab:DatosInsuficientes", ...
        "Se requieren al menos 20 muestras validas para identificar el modelo.")
end

t = t-t(1);

if any(diff(t) <= 0)
    error("TCLab:TiempoInvalido", ...
        "Tiempo_s debe ser estrictamente creciente.")
end

toleranciaEntrada = max(1e-9,1e-6*max(1,max(abs(u))));
indiceCambio = find(abs(diff(u)) > toleranciaEntrada,1,"first")+1;

if isempty(indiceCambio)
    error("TCLab:EntradaConstante", ...
        "Q1_pct no contiene ningun cambio de nivel.")
end

indicesIniciales = 1:indiceCambio-1;

if numel(indicesIniciales) < 5
    error("TCLab:PeriodoInicialInsuficiente", ...
        "Se requieren al menos cinco muestras antes del primer cambio de Q1.")
end

u0 = median(u(indicesIniciales));
y0 = mean(y(indicesIniciales));

%% Limites de busqueda

dtMediano    = median(diff(t));
duracion_s   = t(end)-t(1);
tauMin_s     = max(dtMediano,0.1);
tauMax_s     = max(2*duracion_s,10*tauMin_s);
thetaMax_s   = min(300,0.25*duracion_s);
pasoTheta_s  = dtMediano;

thetaCandidatos_s = 0:pasoTheta_s:thetaMax_s;

if thetaCandidatos_s(end) < thetaMax_s
    thetaCandidatos_s(end+1) = thetaMax_s;
end

%% Optimizacion de K, tau y theta

opciones = optimset( ...
    "Display","off", ...
    "TolX",1e-6, ...
    "MaxIter",300, ...
    "MaxFunEvals",600);

mejorSSE   = Inf;
mejorK     = NaN;
mejorTau   = NaN;
mejorTheta = NaN;
mejorZ     = [];

logTauMin = log(tauMin_s);
logTauMax = log(tauMax_s);

for theta = thetaCandidatos_s
    objetivoTau = @(logTau) evaluarSSE( ...
        t,u,y,u0,y0,exp(logTau),theta);

    logTauOptimo = fminbnd( ...
        objetivoTau,logTauMin,logTauMax,opciones);

    tau = exp(logTauOptimo);
    [SSE,K,z] = evaluarSSE(t,u,y,u0,y0,tau,theta);

    if SSE < mejorSSE
        mejorSSE   = SSE;
        mejorK     = K;
        mejorTau   = tau;
        mejorTheta = theta;
        mejorZ     = z;
    end
end

K     = mejorK;
tau   = mejorTau;
theta = mejorTheta;
yModelo = y0+K*mejorZ;
residuo = y-yModelo;

%% Metricas y funcion de transferencia

SSE    = sum(residuo.^2);
RMSE_C = sqrt(mean(residuo.^2));
MAE_C  = mean(abs(residuo));

SST = sum((y-mean(y)).^2);

if SST > 0
    R2 = 1-SSE/SST;
else
    R2 = NaN;
end

denominadorAjuste = norm(y-mean(y));

if denominadorAjuste > 0
    ajuste_pct = 100*(1-norm(residuo)/denominadorAjuste);
else
    ajuste_pct = NaN;
end

if exist("tf","file") == 2
    G = tf(K,[tau 1],"InputDelay",theta);
else
    G = [];
    warning("TCLab:ControlSystemToolboxNoDisponible", ...
        ["No se pudo construir el objeto tf. Los parametros del modelo " ...
         "si fueron identificados."])
end

%% Organizacion de los resultados

resultado = struct;
resultado.Archivo = archivoMAT;
resultado.Modelo  = "FOPDT";
resultado.G       = G;
resultado.Parametros = table(K,tau,theta, ...
    VariableNames=["K_C_por_pct","Tau_s","Theta_s"]);
resultado.CondicionInicial = table(u0,y0,t(indiceCambio), ...
    VariableNames=["Q1_inicial_pct","T1_inicial_C","PrimerCambio_s"]);
resultado.Metricas = table(RMSE_C,MAE_C,R2,ajuste_pct,SSE, ...
    VariableNames=["RMSE_C","MAE_C","R2","Ajuste_pct","SSE"]);
resultado.Datos = table(t,u,y,yModelo,residuo, ...
    VariableNames=[ ...
        "Tiempo_s","Q1_pct","T1_experimental_C", ...
        "T1_modelo_C","Residuo_C"]);
resultado.Configuracion = struct( ...
    "TauMin_s",tauMin_s, ...
    "TauMax_s",tauMax_s, ...
    "ThetaMax_s",thetaMax_s, ...
    "ResolucionTheta_s",pasoTheta_s, ...
    "NumeroMuestras",numel(t));

%% Presentacion de resultados

fprintf("\nModelo FOPDT identificado\n")
fprintf("Archivo: %s\n",archivoMAT)
fprintf("K     = %.6f degC/%%\n",K)
fprintf("tau   = %.3f s\n",tau)
fprintf("theta = %.3f s\n",theta)
fprintf("RMSE  = %.4f degC\n",RMSE_C)
fprintf("R^2   = %.5f\n",R2)
fprintf("Ajuste = %.2f %%\n\n",ajuste_pct)

[~,nombreSinRuta,extension] = fileparts(archivoMAT);
nombreMostrado = nombreSinRuta+extension;

figura = figure( ...
    Name="Identificacion FOPDT - "+nombreSinRuta, ...
    Color="w");

distribucion = tiledlayout(figura,3,1, ...
    TileSpacing="compact",Padding="compact");

nexttile(distribucion)
plot(t,y,"Color",[0.15 0.15 0.15],LineWidth=1.0)
hold on
plot(t,yModelo,"--",Color=[0.85 0.20 0.15],LineWidth=1.8)
grid on
ylabel("T_1 (degC)")
legend("Experimental","FOPDT",Location="best")
title("Identificacion FOPDT: "+nombreMostrado,Interpreter="none")

nexttile(distribucion)
stairs(t,u,Color=[0.00 0.35 0.65],LineWidth=1.4)
grid on
ylabel("Q_1 (%)")

nexttile(distribucion)
plot(t,residuo,Color=[0.35 0.35 0.35],LineWidth=1.0)
yline(0,"k:")
grid on
xlabel("Tiempo (s)")
ylabel("Residuo (degC)")

end


function datos = extraerTablaExperimental(contenido)
%EXTRAERTABLAEXPERIMENTAL Localiza la tabla que contiene las senales SISO.

if isfield(contenido,"datos") && istable(contenido.datos)
    datos = contenido.datos;
    return
end

campos = fieldnames(contenido);
requeridas = ["Tiempo_s","Q1_pct","T1_C"];
indicesCandidatos = false(size(campos));

for k = 1:numel(campos)
    valor = contenido.(campos{k});

    if istable(valor)
        nombres = string(valor.Properties.VariableNames);
        indicesCandidatos(k) = all(ismember(requeridas,nombres));
    end
end

candidatos = campos(indicesCandidatos);

if isempty(candidatos)
    error("TCLab:TablaNoEncontrada", ...
        ["El archivo MAT no contiene una tabla con Tiempo_s, " ...
         "Q1_pct y T1_C."])
end

if numel(candidatos) > 1
    error("TCLab:TablaAmbigua", ...
        "El archivo contiene mas de una tabla experimental compatible.")
end

datos = contenido.(candidatos{1});

end


function [SSE,K,z] = evaluarSSE(t,u,y,u0,y0,tau,theta)
%EVALUARSSE Simula la dinamica y calcula el K optimo para tau y theta.

z = simularRespuestaUnitaria(t,u,u0,tau,theta);
desviacionY = y-y0;
denominador = z'*z;

if denominador <= eps
    K = 0;
    SSE = Inf;
    return
end

% Para una planta termica, la ganancia debe ser no negativa.
K = max(0,(z'*desviacionY)/denominador);
residuo = desviacionY-K*z;
SSE = sum(residuo.^2);

end


function z = simularRespuestaUnitaria(t,u,u0,tau,theta)
%SIMULARRESPUESTAUNITARIA Respuesta FOPDT para una ganancia K unitaria.
%
% La entrada retardada se reconstruye con retencion de orden cero. En cada
% intervalo se usa la solucion exacta del sistema de primer orden.

numeroMuestras = numel(t);
z = zeros(numeroMuestras,1);

tiemposConsulta = t(1:end-1)-theta;
uRetardada = u0*ones(size(tiemposConsulta));
indicesDentro = tiemposConsulta >= t(1);

if any(indicesDentro)
    uRetardada(indicesDentro) = interp1( ...
        t,u,tiemposConsulta(indicesDentro),"previous");
end

for k = 2:numeroMuestras
    dt = t(k)-t(k-1);
    a  = exp(-dt/tau);
    z(k) = a*z(k-1)+(1-a)*(uRetardada(k-1)-u0);
end

end
