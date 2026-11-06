function rtwTargetInfo(tr)
% Registro de una configuracion de conexion PIL propia para la ESP32
% (Etapa G, proyecto Ball on Plate).
%
% Por que: el Simulink Support Package for Arduino Hardware (R2026a) trae PIL
% para Arduino ("Arduino Board", arduinoregistry/registerpil.m), pero solo lo
% habilita en las placas con boardInfo.IsPilSupported = true. En la clase
% ESP32WROOMdevkitC_38Board esa propiedad es 0 (G0c, 2026-11-06), asi que la
% ESP32 queda sin conexion PIL.
%
% Que hace: registra "ESP32 BoP (Arduino PIL)", que usa una subclase sin cambios
% (+bop_pil/ConnectivityConfigESP32.m) de la clase de
% conexion del paquete (codertarget.arduinotarget.pil.ConnectivityConfig:
% compilacion con la toolchain ESP32 del paquete, carga y comunicacion serie)
% y la declara compatible solo con modelos cuya placa sea una ESP32.
% No modifica ningun archivo del paquete. Mecanismo documentado por MathWorks:
% "Create PIL Target Connectivity Configuration" (rtwTargetInfo + ConfigRegistry).
%
% Se activa agregando esta carpeta al path y llamando sl_refresh_customizations.
tr.registerTargetInfo(@loc_crear);
end

function config = loc_crear
config = rtw.connectivity.ConfigRegistry;
config.ConfigName = 'ESP32 BoP (Arduino PIL)';
config.ConfigClass = 'bop_pil.ConnectivityConfigESP32';  % subclase sin cambios de la del paquete
config.isConfigSetCompatibleFcn = @loc_compatible;
end

function ok = loc_compatible(configSet)
ok = false;
try
    placa = get_param(configSet, 'HardwareBoard');
    ok = contains(placa, 'ESP32');
catch
end
end
