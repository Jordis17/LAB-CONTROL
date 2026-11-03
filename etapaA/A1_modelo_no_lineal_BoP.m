%% ETAPA A - SCRIPT 1: MODELO NO LINEAL DE LA PLANTA BALL ON PLATE
% Este script:
%   1. Carga los parametros (A0_parametros_BoP) y comprueba la geometria del neutro.
%   2. Calcula la relacion servo -> plato del mecanismo (cinematica directa),
%      su pendiente en el neutro y su desviacion de la recta.
%   3. Cuantifica el acople del mecanismo: error de inclinacion si el firmware
%      resuelve cada eje por separado en lugar de la cinematica 3D.
%   4. Verifica la implementacion de la dinamica: con inclinacion constante y
%      la bola partiendo del reposo en el centro, el modelo debe dar la parabola
%      x(t) = -0.5*c*g*sin(th)*t^2 exactamente.
%   5. Cuantifica el error de la camara por la inclinacion del plato
%      (diferencia entre la posicion sobre el plato y la que reporta la vision).
%
% Salidas (carpeta resultados/):
%   A1_consola.txt, A1_cinematica_servo_plato.csv, A1_acople_mecanismo.csv,
%   A1_verificacion_parabola.csv, A1_error_camara.csv, A1_resultados.mat
% El orden de columnas de cada CSV esta en orden_csv.md.
%
% Uso: en MATLAB, con la carpeta etapaA como carpeta actual,
%   >> A1_modelo_no_lineal_BoP

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
addpath(fullfile(carpeta,'funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'A1_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA A - A1_modelo_no_lineal_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

P = A0_parametros_BoP(true);

%% 1. Geometria del neutro
fprintf('=== 1. Geometria del neutro ===\n');
holgura_neutro = P.L_var - (P.z_rot + P.H_serv);
fprintf('  L_var - (z_rot + H_serv) = %.3f mm  (0 => varilla vertical con brazo horizontal y plato horizontal)\n', holgura_neutro);
phi_neutro = bop_cinematica_inversa([0;0], P);
fprintf('  Cinematica inversa en th = 0: phix = %.6f deg, phiy = %.6f deg\n', rad2deg(phi_neutro));
if any(abs(phi_neutro) > 1e-9)
    warning('BoP:Neutro','El neutro del servo no corresponde al plato horizontal con esta geometria.');
end

%% 2. Relacion servo -> plato (un eje, el otro en neutro)
fprintf('\n=== 2. Relacion servo -> plato (eje X, servo Y en neutro) ===\n');
phi_deg = (-45:1:45)';
th_deg  = NaN(size(phi_deg));
for i = 1:numel(phi_deg)
    th_i = bop_cinematica_directa([deg2rad(phi_deg(i)); 0], P);
    th_deg(i) = rad2deg(th_i(1));
end
e = 1e-6;
thp = bop_cinematica_directa([ e;0], P);
thm = bop_cinematica_directa([-e;0], P);
pendiente = (thp(1)-thm(1))/(2*e);            % [rad/rad] = [deg/deg]
th_recta_deg = pendiente*phi_deg;
dev_deg = th_deg - th_recta_deg;

fprintf('  Pendiente en el neutro dth/dphi = %.4f deg/deg\n', pendiente);
fprintf('  phi = -45 deg -> th = %8.3f deg\n', th_deg(1));
fprintf('  phi = +45 deg -> th = %8.3f deg\n', th_deg(end));
fprintf('  Maxima desviacion respecto de la recta en +-45 deg: %.3f deg\n', max(abs(dev_deg)));
idx20 = abs(phi_deg) <= 20;
fprintf('  Maxima desviacion respecto de la recta en +-20 deg: %.3f deg\n', max(abs(dev_deg(idx20))));
th_max_alc = min(abs(th_deg([1 end])));
fprintf('  Inclinacion alcanzable simetrica (limitada por el servo): +-%.3f deg\n', th_max_alc);
escribir_csv(fullfile(dirRes,'A1_cinematica_servo_plato.csv'), ...
    {'phi_deg','th_deg','th_recta_deg','desviacion_deg'}, ...
    [phi_deg th_deg th_recta_deg dev_deg]);

%% 3. Acople del mecanismo entre ejes
% Si el firmware calcula cada servo con la cinematica de su propio eje
% (modo 'plano'), la inclinacion real (3D) difiere de la pedida cuando los
% dos ejes estan inclinados a la vez.
fprintf('\n=== 3. Acople del mecanismo: IK por eje vs inclinacion real 3D ===\n');
rejilla = (-12:2:12)';
filas = zeros(numel(rejilla)^2, 6);
k = 0;
for i = 1:numel(rejilla)
    for j = 1:numel(rejilla)
        thc = deg2rad([rejilla(i); rejilla(j)]);
        phi_pl = bop_cinematica_inversa(thc, P, 'plano');
        th_real = bop_cinematica_directa(phi_pl, P, '3D', thc);
        k = k + 1;
        filas(k,:) = [rejilla(i) rejilla(j) rad2deg(phi_pl') rad2deg(th_real' - thc')];
    end
end
fprintf('  Rejilla de +-12 deg por eje, paso 2 deg (%d puntos)\n', k);
fprintf('  Error maximo de inclinacion en X: %.4f deg\n', max(abs(filas(:,5))));
fprintf('  Error maximo de inclinacion en Y: %.4f deg\n', max(abs(filas(:,6))));
err_acople_max = max(max(abs(filas(:,5:6))));
escribir_csv(fullfile(dirRes,'A1_acople_mecanismo.csv'), ...
    {'thx_pedido_deg','thy_pedido_deg','phix_deg','phiy_deg','err_thx_deg','err_thy_deg'}, filas);

%% 4. Verificacion de la dinamica: parabola con inclinacion constante
fprintf('\n=== 4. Verificacion de la implementacion: inclinacion constante ===\n');
th0_deg = 2.0;                                % inclinacion de la prueba [deg]
th0 = deg2rad(th0_deg);
a_teo = -P.c_rod*P.g*sin(th0);                % [mm/s^2]
t_pared = sqrt(2*P.x_max/abs(a_teo));         % tiempo hasta x_max
t_eval = (0:0.001:floor(t_pared*1000)/1000)';
rhs = @(t,s) [s(3:4); bop_aceleracion(s(1:2), s(3:4), [th0;0], [0;0], [0;0], P)];
opciones = odeset('RelTol',1e-10,'AbsTol',1e-10);
[~, S] = ode45(rhs, t_eval, [0;0;0;0], opciones);
x_teo = 0.5*a_teo*t_eval.^2;
err = S(:,1) - x_teo;
fprintf('  th = %.1f deg, aceleracion teorica = %.3f mm/s^2, tiempo hasta |x| = %.0f mm: %.3f s\n', ...
    th0_deg, a_teo, P.x_max, t_pared);
fprintf('  Maximo |x_modelo - x_teorico| = %.3e mm  (debe ser ~0: verifica la transcripcion)\n', max(abs(err)));
fprintf('  y se mantiene en %.3e mm (debe ser 0)\n', max(abs(S(:,2))));
escribir_csv(fullfile(dirRes,'A1_verificacion_parabola.csv'), ...
    {'t_s','x_modelo_mm','x_teorico_mm','error_mm'}, [t_eval S(:,1) x_teo err]);

%% 5. Error de la camara por la inclinacion del plato
fprintf('\n=== 5. Medicion de la camara con el plato inclinado (solo eje X) ===\n');
fprintf('  Hipotesis: camara fija sobre la junta, homografia calibrada con el plato horizontal.\n');
th_c_deg = (-14:1:14)';
x_c = [-P.x_max 0 P.x_max];
filas = zeros(numel(th_c_deg)*numel(x_c), 5);
k = 0;
for i = 1:numel(th_c_deg)
    for j = 1:numel(x_c)
        th_i = [deg2rad(th_c_deg(i)); 0];
        Xm = bop_medicion([x_c(j); 0], th_i, P);
        Xl = x_c(j) - P.h*th_i(1);            % aproximacion lineal
        k = k + 1;
        filas(k,:) = [th_c_deg(i) x_c(j) Xm(1) Xm(1)-x_c(j) Xm(1)-Xl];
    end
end
for jx = 1:numel(x_c)
    sel = filas(:,2) == x_c(jx);
    fprintf('  x = %+6.1f mm: Xm - x en [%.2f, %.2f] mm para th en [-14, 14] deg\n', ...
        x_c(jx), min(filas(sel,4)), max(filas(sel,4)));
end
fprintf('  Error de la aproximacion lineal Xm = x - h*th: maximo %.3f mm\n', max(abs(filas(:,5))));
escribir_csv(fullfile(dirRes,'A1_error_camara.csv'), ...
    {'th_deg','x_mm','Xm_mm','Xm_menos_x_mm','Xm_menos_lineal_mm'}, filas);

%% Guardado
A1.P = P;
A1.pendiente_servo_plato = pendiente;
A1.th_max_alcanzable_deg = th_max_alc;
A1.th_en_phi_menos45_deg = th_deg(1);
A1.th_en_phi_mas45_deg = th_deg(end);
A1.err_parabola_max_mm = max(abs(err));
A1.err_acople_max_deg = err_acople_max;
A1.err_camara_lineal_max_mm = max(abs(filas(:,5)));
A1.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
save(fullfile(dirRes,'A1_resultados.mat'), 'A1');
fprintf('\nResultados guardados en %s\n', dirRes);
fprintf('FIN A1\n');
