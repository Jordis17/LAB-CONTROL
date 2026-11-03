function A3a_prueba_LED_TCLab(puerto)
% Prueba segura del LED del TCLab
    
    % if nargin < 1
    %     puerto = "COM8";
    % end
    
    arguments
        puerto (1,1) string = "COM8"
    end
    
    a = arduino(puerto,"Leonardo");
    
    % Se ejecutará al salir de la función, incluso ante un error o interrupción
    proteccion = onCleanup(@() apagarSalidas(a));
    
    % Estado inicial seguro
    apagarSalidas(a);
    
    disp("Prueba del LED iniciada")
    
    % Tres parpadeos
    for k = 1:3
        writePWMDutyCycle(a,"D9",0.5);
        pause(0.75)
    
        writePWMDutyCycle(a,"D9",0);
        pause(0.75)
    end
    
    % Prueba de intensidad
    niveles = [0.25 0.50 0.75 1.00];
    
    for nivel = niveles
        fprintf("Intensidad del LED: %.0f %%\n",100*nivel)
        writePWMDutyCycle(a,"D9",nivel);
        pause(1)
    end
    
    disp("Prueba finalizada")

end

%%
function apagarSalidas(a)
    % Apagado seguro de todas las salidas
    
    try
        writePWMDutyCycle(a,"D3",0);   % Q1
        writePWMDutyCycle(a,"D5",0);   % Q2
        writePWMDutyCycle(a,"D9",0);   % LED
    catch
        warning("No fue posible confirmar el apagado de las salidas.")
    end

end