%% ETAPA C - SEGUNDA ESTRATEGIA: LQR CON ACCION INTEGRAL (UN EJE; EL OTRO ES IGUAL)
% El enunciado del proyecto final (Intrucciones.txt) pide dos estrategias de control
% distintas llevadas hasta MIL. La primera es el PID con integracion condicional
% (C1). Esta es la segunda: realimentacion de estados optima (LQR) sobre un modelo
% discreto que incluye el retardo del lazo, con un integrador del error (LQI).
%
% Por que esta y no otra:
%   - La planta por eje es un doble integrador con retardo. El Kalman del pipeline
%     ya entrega los dos estados (x_hat, v_hat), asi que la realimentacion de
%     estados no necesita sensores nuevos.
%   - El retardo se modela con estados (las inclinaciones ya mandadas, que el
%     controlador conoce): el LQR actua como un predictor y compensa el retardo
%     de forma explicita, cosa que el PID no hace.
%   - El metodo de sintonia (minimizar un costo cuadratico con pesos Q y R) es
%     distinto de la asignacion de polos del PID.
%
% Este script:
%   1. Arma el modelo discreto de diseno (bop_modelo_lqr).
%   2. Recorre una grilla de pesos (regla de Bryson) y calcula los margenes del
%      lazo lineal con la planta de la Etapa A y el Kalman (bop_lazo_lineal_lqr),
%      igual que se hizo con el PID.
%   3. Fija los pesos elegidos, calcula K (dlqr_propio; compara con dlqr si hay
%      Control System Toolbox) y escribe la ley discreta explicita.
%   4. Margenes y polos nominales, y robustez frente a los mismos casos del PID
%      mas el modelo identificado en el prototipo (Etapa B), lado a lado con el PID.
%
% Requiere: etapaA, etapaC/resultados/C1_controlador.mat (mismo Kalman, Ts y
% saturacion que el PID, para comparar en igualdad de condiciones).
% No requiere toolboxes.
%
% Salidas (resultados/): C2_consola.txt, C2_controlador_LQR.mat, C2_grilla.csv,
%   C2_bode.csv, C2_robustez.csv

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), carpeta, ...
        fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaD','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'C2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA C - C2_disenar_LQR_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
if exist('OCTAVE_VERSION','builtin'), fprintf('Octave %s\n', version); else, fprintf('MATLAB %s\n', version); end
txt_sino = {'NO','si'};
% Q por la regla de Bryson (ver seccion 2); las entradas pasadas no se penalizan
pesoQ = @(M, e_max, v_max, q_z) diag([1/e_max^2, 1/v_max^2, zeros(1, M.n - 3), q_z]);

P  = A0_parametros_BoP(false);
L  = bop_modelo_lineal(P);
Rq = C0_requisitos_BoP();
S1 = load(fullfile(carpeta,'resultados','C1_controlador.mat'));
Cpid = S1.Ctrl;

%% 1. Modelo de diseno
omega_n_servo = Cpid.omega_n_servo;               % mismo supuesto que el PID
tau_d = P.retardo + 2/omega_n_servo;              % retardo + atraso del servo [s]
M = bop_modelo_lqr(P, tau_d);
fprintf('\n=== 1. Modelo discreto de diseno ===\n');
fprintf('  Planta: xdd = -c*g*th, c*g = %.1f mm/(s^2 rad); retardo de entrada tau_d = retardo + 2/omega_n = %.4f s\n', ...
    P.c_rod*P.g, tau_d);
fprintf('  ZOH exacto con Ts = %.4f s: d = %d entradas pasadas en el estado (tau_d = %d*Ts + %.4f s)\n', ...
    P.Ts, M.d, M.d - 1, tau_d - (M.d-1)*P.Ts);
fprintf('  Estado aumentado (%d): %s\n', M.n, strjoin(M.estados, ', '));
fprintf('  A =\n');  fprintf(['    ' repmat('%11.4g ', 1, M.n) '\n'], M.A');
fprintf('  B = [%s]''\n', sprintf('%.4g ', M.B));

%% 2. Grilla de pesos (regla de Bryson)
% Q = diag(1/e_max^2, 1/v_max^2, 0 ... 0, q_z),  R = 1/th_max^2
% e_max, v_max, th_max: error, velocidad e inclinacion "aceptables"; q_z pesa la
% integral del error. Las entradas pasadas no se penalizan (son memoria).
fprintf('\n=== 2. Grilla de pesos: margenes del lazo lineal (planta Etapa A + retardo %.3f s + Kalman) ===\n', P.retardo);
fprintf('  e_max[mm] v_max[mm/s] th_max[deg]   q_z      Ke[deg/mm]  Kv[deg/(mm/s)]  Kz[deg/(mm s)]  PM[deg] GMsup[dB] GMinf[dB] wc[rad/s]\n');
g_e = [50 100];  g_v = [100 300];  g_th = deg2rad([3 5]);  g_qz = [1e-6 1e-5 1e-4];
G = [];
for a = g_e, for b = g_v, for c = g_th, for q = g_qz
    K = dlqr_propio(M.A, M.B, pesoQ(M, a, b, q), 1/c^2);
    Ci = struct('K',K,'d',M.d,'Ts',P.Ts,'Kf',Cpid.Kf);
    Si = bop_lazo_lineal_lqr(P, L, Ci, P.retardo);
    G(end+1,:) = [a b rad2deg(c) q -rad2deg(K(1)) -rad2deg(K(2)) -rad2deg(K(end)) Si.PM Si.GM_sup_dB Si.GM_inf_dB Si.wc]; %#ok<AGROW>
    fprintf('  %6.0f %10.0f %10.0f   %8.0e   %9.4f   %12.4f   %13.5f   %6.1f  %7.1f  %8.1f  %7.2f\n', G(end,:));
end, end, end, end
escribir_csv(fullfile(dirRes,'C2_grilla.csv'), {'e_max_mm','v_max_mm_s','th_max_deg','q_z', ...
    'Ke_deg_mm','Kv_deg_mm_s','Kz_deg_mm_s','PM_deg','GM_sup_dB','GM_inf_dB','wc_rad_s'}, G);

%% 3. Pesos elegidos y ganancias
% Decision de ingenieria, con la grilla de arriba, la simulacion lineal de la seccion 3b
% y pruebas en el simulador MIL (Octave, 2026-11-25; D2 las repite con el juego elegido):
%   - q_z = 1e-5 (primer intento): mas margen, pero la integral es tan lenta que en el MIL
%     la bola se pasa ~19 %% y no entra en la banda del 5 %% en 6 s.
%   - q_z = 1e-4 sin recorte: el integrador se carga mientras la bola viaja (24 %% de
%     sobreimpulso en la simulacion lineal). Recortando el error que entra al integrador
%     a +-10 mm el MIL dio ts = 3,2 s y Mp = 7,7 %%; con +-5 mm y v_max = 300 mm/s,
%     ts = 2,0 s y Mp = 5,2 %%. Recortes de 2-3 mm mejoran ts pero dejan 6-12 mm de error
%     con un desnivel de 1 deg, y q_z = 2e-4 o mas baja el margen de fase de 40 deg.
%   Elegido: e_max = 100 mm (el ensayo de requisitos), v_max = 300 mm/s, th_max = 5 deg,
%   q_z = 1e-4 y recorte e_clip = 5 mm.
e_max = 100;  v_max = 300;  th_max = deg2rad(5);  q_z = 1e-4;  e_clip = 5;
Q = pesoQ(M, e_max, v_max, q_z);  Rw = 1/th_max^2;
[K, Pr] = dlqr_propio(M.A, M.B, Q, Rw);
fprintf('\n=== 3. Pesos elegidos y ganancias ===\n');
fprintf('  e_max = %g mm, v_max = %g mm/s, th_max = %g deg, q_z = %g, e_clip = %g mm  ->  Q = diag([%s]), R = %.4g\n', ...
    e_max, v_max, rad2deg(th_max), q_z, e_clip, sprintf('%.3g ', diag(Q)), Rw);
fprintf('  K = [%s]   (u = -K*s, en rad y unidades del estado)\n', sprintf('%.6g ', K));
fprintf('  En grados: Ke = %.5f deg/mm, Kv = %.5f deg/(mm/s), Kz = %.6f deg/(mm s)\n', ...
    -rad2deg(K(1)), -rad2deg(K(2)), -rad2deg(K(end)));
fprintf('  Peso de las entradas pasadas (predictor), de u[k-%d] a u[k-1]: [%s] (adimensional)\n', M.d, sprintf('%.4f ', K(3:2+M.d)));
polos = eig(M.A - M.B*K);
fprintf('  Polos de lazo cerrado del modelo de diseno: %s\n', sprintf('%.4f%+.4fj  ', [real(polos) imag(polos)].'));
fprintf('    (radio maximo %.4f; equivalentes continuos: %s rad/s)\n', max(abs(polos)), ...
    sprintf('%.2f ', sort(abs(log(polos(abs(polos) > 1e-9)))/P.Ts)));
if exist('dlqr', 'file') == 2 || exist('dlqr', 'file') == 3
    try
        K2 = dlqr(M.A, M.B, Q, Rw);
        fprintf('  Comprobacion con dlqr (Control System Toolbox): max|K - K_dlqr| = %.2e\n', max(abs(K - K2)));
    catch err
        fprintf('  dlqr no se pudo usar (%s)\n', err.message);
    end
end
fprintf('\n  Ley discreta (cada cuadro, Ts = %.4f s), por eje:\n', P.Ts);
fprintf('    e[k]      = x_hat[k] - r[k]                                       [mm]\n');
fprintf('    u[k]      = -( Ke*e[k] + Kv*v_hat[k] + sum_i Ku_i*th_cmd[k-i] + Kz*z[k] )   [rad]\n');
fprintf('    th_cmd[k] = min(max(u[k], -th_lim), th_lim),  th_lim = %.1f deg (igual que el PID)\n', rad2deg(Cpid.th_lim));
fprintf('    z[k+1]    = z[k] + Ts*sat(e[k], +-%g mm), salvo con th_cmd saturado y el integrador empujando\n', e_clip);
fprintf('                hacia la saturacion (clamping): z[k+1] = z[k]\n');
fprintf('    Incremento por muestra del integrador: Kz*Ts = %.3e deg/mm  (Kz continua = %.3e deg/(mm s))\n', ...
    -rad2deg(K(end))*P.Ts, -rad2deg(K(end)));

C = struct('tipo','LQR','K',K,'d',M.d,'Ts',P.Ts,'th_lim',Cpid.th_lim,'e_clip',e_clip,'Kf',Cpid.Kf, ...
           'kalman_sigma_a',Cpid.kalman_sigma_a,'kalman_sigma_m',Cpid.kalman_sigma_m, ...
           'omega_n_servo',omega_n_servo,'tau_d',tau_d,'Q',Q,'R',Rw, ...
           'e_max',e_max,'v_max',v_max,'th_max',th_max,'q_z',q_z,'A',M.A,'B',M.B,'estados',{M.estados});

%% 3b. Simulacion lineal rapida del ensayo de requisitos (justifica los pesos)
% Planta lineal de la Etapa A con retardo tau_d, Kalman y la ley con saturacion,
% clamping y recorte; sin servo ni tabla (eso lo agrega el MIL, D2).
fprintf('\n=== 3b. Simulacion lineal del ensayo de requisitos (bola quieta a 100 mm, r = 0, 6 s) ===\n');
fprintf('  juego de pesos                               ts[s]   Mp[%%]  e_final[mm]  max|th|[deg]\n');
Dlin = bop_discretizar(L.A, L.B, L.C(2,:), L.D(2), P.Ts, tau_d);
juegos = {'q_z = 1e-5, sin recorte (primer intento)', pesoQ(M,100,100,1e-5), deg2rad(3), Inf;
          'q_z = 1e-4, v_max 200, sin recorte',       pesoQ(M,100,200,1e-4), th_max,     Inf;
          'q_z = 1e-4, v_max 200, recorte 10 mm',     pesoQ(M,100,200,1e-4), th_max,     10;
          'q_z = 1e-4, v_max 300, recorte 5 mm (elegido)', Q,                th_max,     e_clip};
for j = 1:size(juegos,1)
    Kj = dlqr_propio(M.A, M.B, juegos{j,2}, 1/juegos{j,3}^2);
    xp = zeros(size(Dlin.A,1),1);  xp(1) = 100;  xh = [100; 0];  E = struct('ub', zeros(M.d,1), 'z', 0);
    Nn = round(6/P.Ts);  ys = zeros(Nn,1);  thm = 0;
    for k = 1:Nn
        xh = [1 P.Ts; 0 1]*xh;  xh = xh + Cpid.Kf*(Dlin.C*xp - xh(1));  ys(k) = xh(1);
        [th, E.ub, E.z] = bop_ley_lqr(xh(1), xh(2), 0, E.ub, E.z, Kj, P.Ts, Cpid.th_lim, juegos{j,4}, true, true);
        thm = max(thm, abs(th));  xp = Dlin.A*xp + Dlin.B*th;
    end
    fuera = find(abs(ys) > 0.05*100, 1, 'last');
    if isempty(fuera), tsj = 0; elseif fuera == Nn, tsj = NaN; else, tsj = fuera*P.Ts; end
    fprintf('  %-46s %6.2f  %6.1f  %10.2f  %11.2f\n', juegos{j,1}, tsj, max(0, max(-ys))/100*100, ...
        abs(mean(ys(end-29:end))), rad2deg(thm));
end

%% 4. Margenes nominales y robustez, lado a lado con el PID
fprintf('\n=== 4. Lazo discreto nominal y robustez (mismas condiciones que C1) ===\n');
S = bop_lazo_lineal_lqr(P, L, C, P.retardo);
Sp = bop_lazo_lineal(P, L, Cpid, P.retardo);
fprintf('  LQR: wc = %.3f rad/s, PM = %.1f deg, GM = %+.1f / %+.1f dB, margen de retardo %.0f ms, radio max %.4f\n', ...
    S.wc, S.PM, S.GM_sup_dB, S.GM_inf_dB, 1000*S.margen_retardo, S.radio_max);
fprintf('  PID: wc = %.3f rad/s, PM = %.1f deg, GM = %+.1f / %+.1f dB, margen de retardo %.0f ms, radio max %.4f\n', ...
    Sp.wc, Sp.PM, Sp.GM_sup_dB, Sp.GM_inf_dB, 1000*Sp.margen_retardo, Sp.radio_max);
escribir_csv(fullfile(dirRes,'C2_bode.csv'), {'w_rad_s','mag_dB_LQR','fase_deg_LQR','mag_dB_PID','fase_deg_PID'}, ...
    [S.w S.mag_dB S.fase_deg Sp.mag_dB Sp.fase_deg]);

fprintf('\n  caso                              LQR: PM  GMsup  GMinf  estable | PID: PM  GMsup  GMinf  estable\n');
casos = { 'nominal',                         P,                               P.retardo;
          'retardo 120 ms',                  P,                               0.120;
          'c = 0,685',                       bop_param_con(P,'c_rod',0.685),  P.retardo;
          'h_sup = 40 mm',                   bop_param_con(P,'h_sup',40),     P.retardo;
          'identificado X (c 0,18; 0,27 s)', bop_param_con(P,'c_rod',0.18),   0.27;
          'identificado Y (c 0,28; 0,27 s)', bop_param_con(P,'c_rod',0.28),   0.27;
          'identificado X, retardo 0,44 s',  bop_param_con(P,'c_rod',0.18),   0.44 };
Rb = zeros(size(casos,1), 9);
for i = 1:size(casos,1)
    Pi = casos{i,2};  Li = bop_modelo_lineal(Pi);
    A1 = bop_lazo_lineal_lqr(Pi, Li, C, casos{i,3});
    A2 = bop_lazo_lineal(Pi, Li, Cpid, casos{i,3});
    Rb(i,:) = [i A1.PM A1.GM_sup_dB A1.GM_inf_dB A1.estable A2.PM A2.GM_sup_dB A2.GM_inf_dB A2.estable];
    fprintf('  %-32s %6.1f %6.1f %6.1f   %-5s | %6.1f %6.1f %6.1f   %s\n', casos{i,1}, ...
        A1.PM, A1.GM_sup_dB, A1.GM_inf_dB, txt_sino{A1.estable+1}, A2.PM, A2.GM_sup_dB, A2.GM_inf_dB, txt_sino{A2.estable+1});
end
escribir_csv(fullfile(dirRes,'C2_robustez.csv'), {'caso','PM_LQR','GMsup_LQR','GMinf_LQR','estable_LQR', ...
    'PM_PID','GMsup_PID','GMinf_PID','estable_PID'}, Rb);
fprintf('  Casos: %s\n', strjoin(casos(:,1)', ' | '));
fprintf('  Nota: los casos "identificado" cambian solo c y el retardo en el modelo lineal; la zona\n');
fprintf('  muerta y la holgura del prototipo no entran en este analisis.\n');

%% Guardado
C.margenes = rmfield(S, {'w','L','P','C','mag_dB','fase_deg'});
C.P_diseno = P;
C.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
Ctrl = C; %#ok<NASGU>
save(fullfile(dirRes,'C2_controlador_LQR.mat'), 'Ctrl', 'Rq', '-v7');
fprintf('\nControlador guardado en %s (variable Ctrl)\n', fullfile(dirRes,'C2_controlador_LQR.mat'));
fprintf('FIN C2\n');

