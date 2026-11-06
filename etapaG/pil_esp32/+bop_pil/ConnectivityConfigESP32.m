classdef ConnectivityConfigESP32 < codertarget.arduinotarget.pil.ConnectivityConfig
% Conexion PIL para la ESP32 (Etapa G, Ball on Plate).
% Hereda TODO de la conexion PIL del Simulink Support Package for Arduino
% Hardware (compilacion con la toolchain ESP32, carga y comunicacion serie).
% Existe solo porque Simulink no deja registrar la misma clase en dos
% configuraciones ("Arduino Board" ya registra la del paquete, y la habilita
% solo en placas con IsPilSupported = true; la ESP32 tiene 0).
% No cambia ningun comportamiento de la clase del paquete.
    methods
        function this = ConnectivityConfigESP32(componentArgs)
            this@codertarget.arduinotarget.pil.ConnectivityConfig(componentArgs);
        end
    end
end
