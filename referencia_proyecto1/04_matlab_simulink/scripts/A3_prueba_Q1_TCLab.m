function datos = A3c_prueba_Q1_TCLab(puerto)
% Prueba funcional segura del calentador Q1

arguments
    puerto (1,1) string = "COM8"
end

% Parámetros fijos de la prueba
Q1_comando       = 30;   % Porcentaje solicitado
tiempoReposo     = 10;   % s
tiempoCalentando = 60;   % s
tiempoEnfriando  = 60;   % s
Ts               = 1;    % s
Tmax             = 45;   % °C
nPromedio        = 10;

% El TCLab limita Q1 a un duty cycle máximo de 0.9
PWM_Q1 = 0.9*Q1_comando/100;

a = arduino(puerto,"Leonardo");

% Apagado al salir, incluso ante error o interrupción
proteccion = onCleanup(@() apagarSalidas(a));

% Estado inicial seguro
apagarSalidas(a);

duracionTotal = tiempoReposo + tiempoCalentando + tiempoEnfriando;
nMuestras = floor(duracionTotal/Ts) + 1;

t     = zeros(nMuestras,1);
T1    = zeros(nMuestras,1);
T2    = zeros(nMuestras,1);
Q1    = zeros(nMuestras,1);
PWM   = zeros(nMuestras,1);
fase  = strings(nMuestras,1);

corteTermico = false;
reloj = tic;

disp("Prueba de Q1 iniciada")
fprintf("Comando Q1: %.0f %% | PWM físico: %.3f\n", ...
        Q1_comando,PWM_Q1);
fprintf("Límite térmico: %.1f °C\n\n",Tmax);

for k = 1:nMuestras

    espera = (k-1)*Ts - toc(reloj);

    if espera > 0
        pause(espera)
    end

    t(k)  = toc(reloj);
    T1(k) = leerTemperatura(a,"A0",nPromedio);
    T2(k) = leerTemperatura(a,"A2",nPromedio);

    % Supervisión térmica
    if T1(k) >= Tmax
        corteTermico = true;
    end

    if t(k) < tiempoReposo
        fase(k) = "Reposo";

    elseif t(k) < tiempoReposo + tiempoCalentando && ~corteTermico
        fase(k) = "Calentamiento";
        Q1(k)   = Q1_comando;
        PWM(k)  = PWM_Q1;

    elseif t(k) < tiempoReposo + tiempoCalentando
        fase(k) = "Corte térmico";

    else
        fase(k) = "Enfriamiento";
    end

    writePWMDutyCycle(a,"D3",PWM(k));
    writePWMDutyCycle(a,"D5",0);

    fprintf("t=%6.1f s | %-14s | Q1=%3.0f %% | T1=%6.2f °C | T2=%6.2f °C\n", ...
            t(k),fase(k),Q1(k),T1(k),T2(k));
end

% Apagado explícito antes de procesar resultados
apagarSalidas(a);

datos = table(t,fase,Q1,PWM,T1,T2, ...
    VariableNames=["Tiempo_s","Fase","Q1_pct","PWM","T1_C","T2_C"]);

T1_inicial = mean(T1(fase=="Reposo"));
incrementoT1 = max(T1) - T1_inicial;

fprintf("\nResumen:\n")
fprintf("T1 inicial promedio: %.2f °C\n",T1_inicial)
fprintf("T1 máxima:           %.2f °C\n",max(T1))
fprintf("Incremento máximo:   %.2f °C\n",incrementoT1)
fprintf("T2 máxima:           %.2f °C\n",max(T2))
fprintf("Corte térmico:       %s\n",string(corteTermico))
fprintf("Prueba finalizada. Todas las salidas están apagadas.\n")

figure(Name="Prueba del calentador Q1")
tiledlayout(2,1)

nexttile
plot(t,T1,LineWidth=1.3)
hold on
plot(t,T2,LineWidth=1.3)
yline(Tmax,"--r","Límite térmico")
grid on
ylabel("Temperatura (°C)")
legend("T_1","T_2",Location="best")
title("Respuesta térmica")

nexttile
stairs(t,Q1,LineWidth=1.3)
grid on
xlabel("Tiempo (s)")
ylabel("Comando Q_1 (%)")
ylim([0 35])

end

%%
function T = leerTemperatura(a,pin,n)
% Lectura promedio y conversión del TMP36

    V = zeros(n,1);
    
    for k = 1:n
        V(k) = readVoltage(a,pin);
    end
    
    % Relación del sensor de temperatura TMP36
    % offset 0.5 V a 0 °C  y la sensibilidad de 10 mV/°C.
    T = (mean(V)-0.5)*100;

end

%%
function apagarSalidas(a)
% Apagado seguro

    try
        writePWMDutyCycle(a,"D3",0);   % Q1
        writePWMDutyCycle(a,"D5",0);   % Q2
        writePWMDutyCycle(a,"D9",0);   % LED
    catch
        warning("No fue posible confirmar el apagado de las salidas.")
    end

end