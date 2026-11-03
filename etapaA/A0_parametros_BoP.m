function P = A0_parametros_BoP(imprimir)
%A0_PARAMETROS_BOP Unica fuente de parametros de la planta Ball on Plate.
%
%   P = A0_parametros_BoP()        devuelve la estructura de parametros.
%   P = A0_parametros_BoP(true)    ademas imprime la tabla en consola.
%
% Unidades internas de TODO el proyecto: mm, s, rad. Los angulos solo se
% pasan a grados para imprimir y para los CSV (columnas *_deg).
%
% Cada parametro tiene un estado:
%   MEDIDO       medido sobre el prototipo
%   DISENO       cota del diseno mecanico (docs/mecanica-decisiones-y-medidas.md)
%   PROVISIONAL  sale del diseno o de una cuenta; hay que medirlo
%   HOJA_DATOS   hoja de datos del fabricante
%   ESTIMADO     estimacion a priori, NO es una medicion
%   PENDIENTE    falta el valor; se usa un nominal marcado como tal
%
% Si cambia un valor medido, se cambia AQUI y se vuelven a correr A1 y A2.

if nargin < 1
    imprimir = false;
end

%% Constantes
P.g = 9810;                    % gravedad [mm/s^2] (valor redondeado, igual que config.py)

%% Bola
P.r_bola = 20.0;               % radio de la bola [mm]                    MEDIDO (diametro 40 mm)
P.m_bola_g = 34;               % masa [g]                                 MEDIDO
                               % (la masa se cancela en la dinamica de rodadura; se guarda como dato)
P.c_rod = 5/7;                 % c = 1/(1 + J/(m r^2)) [-]                PENDIENTE identificar (Etapa B)
                               % 5/7 = esfera maciza; estimado entre 0,685 y 0,714
P.k_inercia = 1/P.c_rod - 1;   % J/(m r^2) [-], derivado de c

%% Geometria del plato y del pivote (alturas medidas desde la cara superior de la base)
cota_cara_inf_plato = 215.4;   % [mm]                                     DISENO
espesor_plato       = 3.0;     % [mm]                                     DISENO
cota_pivote_junta   = 169.4;   % [mm] centro de la junta universal ("aprox." en docs)  PROVISIONAL
cota_pivote_rotula  = 195.6;   % [mm]                                     DISENO
cota_eje_servo      = 33.4;    % [mm] (ajustable 29,4 a 37,4)             DISENO

P.h_sup = cota_cara_inf_plato + espesor_plato - cota_pivote_junta;  % cara superior del plato sobre el pivote [mm]  PROVISIONAL
P.h     = P.h_sup + P.r_bola;  % centro de la bola sobre el pivote [mm]   PROVISIONAL

P.x_max = 127;                 % rango util del centro de la bola, por eje [mm]

%% Mecanismo servo -> plato (cada eje en su plano vertical)
P.d       = 70.0;              % centro del plato -> pivote de la rotula, sobre +X y +Y [mm]   DISENO
P.r_brazo = 24.0;              % brazo del servo [mm]                     PROVISIONAL
P.z_rot   = cota_pivote_rotula - cota_pivote_junta;   % pivote de rotula sobre la junta [mm]
P.H_serv  = cota_pivote_junta - cota_eje_servo;       % junta sobre el eje del servo [mm]
P.L_var   = 162.2;             % distancia entre las bolas de la cadena [mm]   DISENO
P.sigma_brazo = +1;            % +1: el eje del servo esta del lado del centro del plato
                               %     (brazo apuntando hacia afuera); -1: al reves.
                               % PENDIENTE confirmar en el prototipo. Solo cambia la asimetria.
% Hipotesis de neutro: plato horizontal con brazo horizontal y varilla vertical.
% Se cumple por construccion si L_var = z_rot + H_serv (se verifica en A1).

%% Servo (Tower Pro MG90D, confirmar modelo)
P.phi_max   = deg2rad(45);     % carrera del servo, +-[rad]               HOJA_DATOS
P.omega_srv = deg2rad(60)/0.10;% velocidad sin carga a 4,8 V [rad/s]      HOJA_DATOS
                               % (a 6 V seria 60 grados/0,08 s). Tension de alimentacion PENDIENTE.
P.T_pwm     = 0.020;           % periodo del PWM del servo [s] (50 Hz)    HOJA_DATOS / habitual

%% Medicion
P.Ts        = 1/30;            % periodo de muestreo [s], nominal 30 fps  PENDIENTE medir (--period)
P.retardo   = 0.075;           % retardo total del lazo [s]               ESTIMADO (punto medio de 60-90 ms, CLAUDE.md)
                               % Reemplazar con run_benchmark.py --latency.
P.H_cam     = 450.0;           % lente sobre la cara superior del plato [mm]   MEDIDO (confirmado por el equipo)

%% Estados (para imprimir y para guardar con los resultados)
P.estado = struct( ...
    'c_rod','PENDIENTE identificar (Etapa B)', ...
    'h','PROVISIONAL (cotas de diseno, pivote aprox.)', ...
    'r_brazo','PROVISIONAL', ...
    'sigma_brazo','PENDIENTE confirmar', ...
    'omega_srv','HOJA_DATOS a 4,8 V (tension PENDIENTE)', ...
    'Ts','PENDIENTE medir (nominal 30 fps)', ...
    'retardo','ESTIMADO a priori, no medido', ...
    'H_cam','MEDIDO');

if imprimir
    fprintf('\n=== Parametros de la planta (A0_parametros_BoP) ===\n');
    fprintf('  g            = %8.1f mm/s^2\n', P.g);
    fprintf('  r_bola       = %8.2f mm      MEDIDO\n', P.r_bola);
    fprintf('  c_rod        = %8.4f -       %s\n', P.c_rod, P.estado.c_rod);
    fprintf('  k = J/(m r^2)= %8.4f -       derivado de c\n', P.k_inercia);
    fprintf('  h_sup        = %8.2f mm      cara superior del plato sobre la junta, %s\n', P.h_sup, P.estado.h);
    fprintf('  h            = %8.2f mm      centro de la bola sobre la junta, %s\n', P.h, P.estado.h);
    fprintf('  d            = %8.2f mm      DISENO\n', P.d);
    fprintf('  r_brazo      = %8.2f mm      %s\n', P.r_brazo, P.estado.r_brazo);
    fprintf('  z_rot        = %8.2f mm      DISENO (derivado)\n', P.z_rot);
    fprintf('  H_serv       = %8.2f mm      DISENO (derivado)\n', P.H_serv);
    fprintf('  L_var        = %8.2f mm      DISENO\n', P.L_var);
    fprintf('  sigma_brazo  = %+8d         %s\n', P.sigma_brazo, P.estado.sigma_brazo);
    fprintf('  phi_max      = %8.2f deg     HOJA_DATOS\n', rad2deg(P.phi_max));
    fprintf('  omega_srv    = %8.1f deg/s   %s\n', rad2deg(P.omega_srv), P.estado.omega_srv);
    fprintf('  T_pwm        = %8.4f s\n', P.T_pwm);
    fprintf('  Ts           = %8.4f s       %s\n', P.Ts, P.estado.Ts);
    fprintf('  retardo      = %8.4f s       %s\n', P.retardo, P.estado.retardo);
    fprintf('  H_cam        = %8.1f mm      %s\n', P.H_cam, P.estado.H_cam);
    fprintf('  x_max        = %8.1f mm\n\n', P.x_max);
end
end
