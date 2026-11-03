function validacion = A6_validar_FOPDT_TCLab(modelo,archivoMAT)
%VALIDAR_FOPDT_TCLAB Valida un modelo FOPDT con otro experimento del TCLab.
%
% El modelo se mantiene fijo durante toda la validacion:
%
%                 Delta T1(s)       K exp(-theta s)
%       G(s) = ------------------ = ----------------
%                 Delta Q1(s)          tau s + 1
%
% Esta funcion NO optimiza ni modifica K, tau o theta. Acepta como primer
% argumento el resultado producido por A5_identificar_FOPDT_TCLab:
%
%   modeloMultinivel = A5_identificar_FOPDT_TCLab( ...
%       "Resultados_experimentos/multinivel_Q1_20260731_232100.mat");
%
% Segundo argumento los resultados experimentales de la otra prueba.
%   validacionMultiEnEscalon = A6_validar_FOPDT_TCLab(...
%                              modeloMultinivel,...
%                              archivoEscalon)
%
% Tambien se pueden indicar directamente [K tau theta]:
%
%   validacion = validar_FOPDT_TCLab( ...
%       [0.948084 183.338 24.038], ...
%       "Resultados_experimentos/escalon_Q1_50_20260731_224643.mat");
%
% Si se omite archivoMAT, se abre un selector de archivos.

arguments
    modelo
    archivoMAT (1,1) string = ""
end

%% Parametros fijos del modelo

[K,tau,theta,archivoIdentificacion] = extraerParametrosModelo(modelo);

if ~isfinite(K) || K < 0
    error("TCLab:GananciaInvalida", ...
        "K debe ser finita y no negativa.")
end

if ~isfinite(tau) || tau <= 0
    error("TCLab:ConstanteTiempoInvalida", ...
        "tau debe ser finita y positiva.")
end

if ~isfinite(theta) || theta < 0
    error("TCLab:RetardoInvalido", ...
        "theta debe ser finito y no negativo.")
end

%% Seleccion y carga del experimento de validacion

if strlength(archivoMAT) == 0
    carpetaInicial = fullfile(pwd,"Resultados_experimentos");

    if ~isfolder(carpetaInicial)
        carpetaInicial = pwd;
    end

    [nombreArchivo,carpetaArchivo] = uigetfile( ...
        fullfile(carpetaInicial,"*.mat"), ...
        "Seleccione el experimento de validacion");

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

nombresRequeridos  = ["Tiempo_s","Q1_pct","T1_C"];
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
        "Se requieren al menos 20 muestras validas para validar el modelo.")
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

%% Simulacion sin reidentificacion

z       = simularRespuestaUnitaria(t,u,u0,tau,theta);
yModelo = y0+K*z;
residuo = y-yModelo;

indicesRespuesta = indiceCambio:numel(t);
metricasCompletas = calcularMetricas(y,yModelo);
metricasRespuesta = calcularMetricas( ...
    y(indicesRespuesta),yModelo(indicesRespuesta));

if exist("tf","file") == 2
    G = tf(K,[tau 1],"InputDelay",theta);
else
    G = [];
    warning("TCLab:ControlSystemToolboxNoDisponible", ...
        ["No se pudo construir el objeto tf. La validacion numerica " ...
         "si fue realizada."])
end

%% Organizacion de los resultados

tramo = ["Datos completos";"Desde el primer cambio"];

validacion = struct;
validacion.ArchivoValidacion     = archivoMAT;
validacion.ArchivoIdentificacion = archivoIdentificacion;
validacion.Modelo                = "FOPDT fijo, sin reoptimizacion";
validacion.G                     = G;
validacion.Parametros = table(K,tau,theta, ...
    VariableNames=["K_C_por_pct","Tau_s","Theta_s"]);
validacion.CondicionInicial = table(u0,y0,t(indiceCambio), ...
    VariableNames=["Q1_inicial_pct","T1_inicial_C","PrimerCambio_s"]);
validacion.Metricas = table( ...
    tramo, ...
    [metricasCompletas.RMSE_C;metricasRespuesta.RMSE_C], ...
    [metricasCompletas.MAE_C;metricasRespuesta.MAE_C], ...
    [metricasCompletas.R2;metricasRespuesta.R2], ...
    [metricasCompletas.Ajuste_pct;metricasRespuesta.Ajuste_pct], ...
    [metricasCompletas.SESGO_C;metricasRespuesta.SESGO_C], ...
    [metricasCompletas.SSE;metricasRespuesta.SSE], ...
    VariableNames=[ ...
        "Tramo","RMSE_C","MAE_C","R2", ...
        "Ajuste_pct","Sesgo_C","SSE"]);
validacion.Datos = table(t,u,y,yModelo,residuo, ...
    VariableNames=[ ...
        "Tiempo_s","Q1_pct","T1_experimental_C", ...
        "T1_modelo_C","Residuo_C"]);

%% Presentacion de resultados

[~,nombreValidacion,extensionValidacion] = fileparts(archivoMAT);
nombreArchivoValidacion = nombreValidacion+extensionValidacion;

nombreArchivoIdentificacion = "";
if strlength(archivoIdentificacion) > 0
    [~,nombreIdentificacion,extensionIdentificacion] = ...
        fileparts(archivoIdentificacion);
    nombreArchivoIdentificacion = ...
        nombreIdentificacion+extensionIdentificacion;
end

fprintf("\nValidacion cruzada del modelo FOPDT\n")
fprintf("Archivo de validacion: %s\n",nombreArchivoValidacion)

if strlength(nombreArchivoIdentificacion) > 0
    fprintf("Modelo identificado con: %s\n",nombreArchivoIdentificacion)
end

fprintf("\n")
fprintf("K      = %.6f degC/%% (fijo)\n",K)
fprintf("tau    = %.3f s (fijo)\n",tau)
fprintf("theta  = %.3f s (fijo)\n",theta)

fprintf("\nMetricas desde el primer cambio de Q1\n")
fprintf("RMSE   = %.4f degC\n",metricasRespuesta.RMSE_C)
fprintf("MAE    = %.4f degC\n",metricasRespuesta.MAE_C)
fprintf("R^2    = %.5f\n",metricasRespuesta.R2)
fprintf("Ajuste = %.2f %%\n",metricasRespuesta.Ajuste_pct)
fprintf("Sesgo  = %.4f degC\n",metricasRespuesta.SESGO_C)
fprintf("SSE    = %.4f (degC)^2\n",metricasRespuesta.SSE)
fprintf("\nNo se reoptimizo ningun parametro.\n\n")

nombreSinRuta = nombreValidacion;
nombreMostrado = nombreArchivoValidacion;

figura = figure( ...
    Name="Validacion FOPDT - "+nombreSinRuta, ...
    Color="w");

distribucion = tiledlayout(figura,3,1, ...
    TileSpacing="compact",Padding="compact");

nexttile(distribucion)
plot(t,y,"Color",[0.15 0.15 0.15],LineWidth=1.0)
hold on
plot(t,yModelo,"--",Color=[0.85 0.20 0.15],LineWidth=1.8)
xline(t(indiceCambio),":",Color=[0.35 0.35 0.35])
grid on
ylabel("T_1 (degC)")
legend("Experimental","FOPDT fijo","Primer cambio",Location="best")
title("Validacion FOPDT: "+nombreMostrado,Interpreter="none")

nexttile(distribucion)
stairs(t,u,Color=[0.00 0.35 0.65],LineWidth=1.4)
xline(t(indiceCambio),":",Color=[0.35 0.35 0.35])
grid on
ylabel("Q_1 (%)")

nexttile(distribucion)
plot(t,residuo,Color=[0.35 0.35 0.35],LineWidth=1.0)
yline(0,"k:")
xline(t(indiceCambio),":",Color=[0.35 0.35 0.35])
grid on
xlabel("Tiempo (s)")
ylabel("Residuo (degC)")

end


function [K,tau,theta,archivoIdentificacion] = ...
        extraerParametrosModelo(modelo)
%EXTRAERPARAMETROSMODELO Lee el resultado del identificador o [K tau theta].

archivoIdentificacion = "";

if isstruct(modelo) && isfield(modelo,"Parametros")
    parametros = modelo.Parametros;

    if ~istable(parametros)
        error("TCLab:ModeloInvalido", ...
            "El campo Parametros del modelo debe ser una tabla.")
    end

    nombres = string(parametros.Properties.VariableNames);
    requeridos = ["K_C_por_pct","Tau_s","Theta_s"];

    if ~all(ismember(requeridos,nombres)) || height(parametros) ~= 1
        error("TCLab:ModeloInvalido", ...
            ["La tabla Parametros debe contener una fila con " ...
             "K_C_por_pct, Tau_s y Theta_s."])
    end

    K     = double(parametros.K_C_por_pct);
    tau   = double(parametros.Tau_s);
    theta = double(parametros.Theta_s);

    if isfield(modelo,"Archivo")
        archivoIdentificacion = string(modelo.Archivo);
    end

elseif isnumeric(modelo) && isvector(modelo) && numel(modelo) == 3
    parametros = double(modelo(:));
    K     = parametros(1);
    tau   = parametros(2);
    theta = parametros(3);

else
    error("TCLab:ModeloInvalido", ...
        ["modelo debe ser el resultado de identificar_FOPDT_TCLab " ...
         "o el vector numerico [K tau theta]."])
end

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


function metricas = calcularMetricas(y,yModelo)
%CALCULARMETRICAS Calcula indicadores sin modificar el modelo.

residuo = y-yModelo;
SSE = sum(residuo.^2);
SST = sum((y-mean(y)).^2);
denominadorAjuste = norm(y-mean(y));

metricas = struct;
metricas.RMSE_C  = sqrt(mean(residuo.^2));
metricas.MAE_C   = mean(abs(residuo));
metricas.SESGO_C = mean(residuo);
metricas.SSE      = SSE;

if SST > 0
    metricas.R2 = 1-SSE/SST;
else
    metricas.R2 = NaN;
end

if denominadorAjuste > 0
    metricas.Ajuste_pct = ...
        100*(1-norm(residuo)/denominadorAjuste);
else
    metricas.Ajuste_pct = NaN;
end

end
