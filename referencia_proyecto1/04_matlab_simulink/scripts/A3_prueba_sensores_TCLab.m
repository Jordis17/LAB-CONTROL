function datos = A3b_prueba_sensores_TCLab(puerto,duracion,Ts)
    % Prueba de los sensores de temperatura del TCLab
    % No activa los calentadores.
    % Ts = sampling time
    % 
    % Ejemplo:
    % datos = prueba_sensores_TCLab("COM6",30,1);
    
    arguments
        puerto   (1,1) string = "COM8"
        duracion (1,1) double {mustBePositive} = 30
        Ts       (1,1) double {mustBePositive} = 1
    end
    
    a = arduino(puerto,"Leonardo");
    
    % Apaga las salidas al terminar, ante un error o interrupción
    proteccion = onCleanup(@() apagarSalidas(a));
    
    % Estado inicial seguro
    apagarSalidas(a);
    
    nPromedio = 10;
    nMuestras = floor(duracion/Ts) + 1;
    
    t  = zeros(nMuestras,1);
    V1 = zeros(nMuestras,1);
    V2 = zeros(nMuestras,1);
    T1 = zeros(nMuestras,1);
    T2 = zeros(nMuestras,1);
    
    disp("Prueba de sensores iniciada")
    fprintf("Calentadores Q1 y Q2 apagados.\n\n")
    
    reloj = tic;
    
    for k = 1:nMuestras
    
        % Mantener aproximadamente el periodo de muestreo solicitado
        espera = (k-1)*Ts - toc(reloj);
    
        if espera > 0
            pause(espera)
        end
    
        t(k)  = toc(reloj);
        V1(k) = leerVoltajePromedio(a,"A0",nPromedio);
        V2(k) = leerVoltajePromedio(a,"A2",nPromedio);
    
        % Relación del sensor de temperatura TMP36
        % offset 0.5 V a 0 °C  y la sensibilidad de 10 mV/°C.

        T1(k) = (V1(k)-0.5)*100;
        T2(k) = (V2(k)-0.5)*100;
    
        fprintf("t = %5.1f s | T1 = %6.2f °C | T2 = %6.2f °C\n", ...
                t(k),T1(k),T2(k));
    end
    
    datos = table(t,V1,V2,T1,T2,T1-T2, ...
        VariableNames=["Tiempo_s","V1_V","V2_V","T1_C","T2_C","Diferencia_C"]);
    
    fprintf("\nResumen:\n")
    fprintf("T1 promedio:       %.2f °C\n",mean(T1))
    fprintf("T2 promedio:       %.2f °C\n",mean(T2))
    fprintf("Diferencia media:  %.2f °C\n",mean(T1-T2))
    fprintf("Desviación de T1:  %.3f °C\n",std(T1))
    fprintf("Desviación de T2:  %.3f °C\n",std(T2))
    fprintf("Prueba finalizada. Salidas apagadas.\n")
    
    figure(Name="Prueba de sensores del TCLab")
    plot(t,T1,"o-",LineWidth=1.2,MarkerSize=4)
    hold on
    plot(t,T2,"s-",LineWidth=1.2,MarkerSize=4)
    grid on
    xlabel("Tiempo (s)")
    ylabel("Temperatura (°C)")
    legend("T_1","T_2",Location="best")
    title("Temperaturas con Q_1=Q_2=0")

end

%%
function V = leerVoltajePromedio(a,pin,n)
% Promedia varias lecturas de tensión

    lecturas = zeros(n,1);
    
    for k = 1:n
        lecturas(k) = readVoltage(a,pin);
    end
    
    V = mean(lecturas);

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