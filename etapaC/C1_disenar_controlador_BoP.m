%% ETAPA C - DISENO DEL CONTROLADOR (UN EJE; EL OTRO ES IGUAL)
% Este script:
%   1. Fija los datos de diseno a partir de la Etapa A y de los requisitos (C0).
%   2. Elige la sintonia del Kalman del pipeline (PROCESS_ACCEL_STD), que queda
%      DENTRO del lazo porque el controlador usa su velocidad.
%   3. Calcula Kp y Kd por asignacion de polos con el retardo del lazo.
%   4. Fija la accion integral (Ti, integracion condicional por bola quieta,
%      recorte) y la saturacion.
%   5. Reporta el controlador continuo y la ley discreta explicita.
%   6. Calcula margenes (fase, ganancia por arriba y por abajo, retardo) y los
%      polos de lazo cerrado sobre el modelo discreto exacto con el Kalman.
%   7. Repite los margenes con variaciones de los parametros inciertos.
%   8. Compara tres estructuras (PD, PID clasico, PID con integracion
%      condicional) con el simulador MIL nominal: justifica la eleccion.
%
% Requiere: etapaA (parametros y modelo) y etapaD/funciones (simulador).
% No requiere toolboxes.
%
% Salidas (resultados/): C1_consola.txt, C1_controlador.mat, C1_bode.csv,
%   C1_kalman.csv, C1_robustez.csv, C1_estructuras.csv,
%   C1_estructuras_regulacion.csv, C1_estructuras_desnivel.csv

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(fullfile(carpeta,'funciones'), carpeta, ...
        fullfile(raiz,'etapaA'), fullfile(raiz,'etapaA','funciones'), ...
        fullfile(raiz,'etapaD','funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'C1_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA C - C1_disenar_controlador_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

P  = A0_parametros_BoP(true);
L  = bop_modelo_lineal(P);
Rq = C0_requisitos_BoP();

%% 1. Datos y decisiones de diseno
% Todas son decisiones de ingenieria (no hay documento del curso que las fije).
omega_n_servo = 50;            % [rad/s] dinamica supuesta del servo (igual que en el MIL)
zeta    = 0.7;                 % amortiguamiento del par de polos dominante
a_polo  = 1.0;                 % tercer polo en a*w
Ti      = 1.5;                 % [s] tiempo integral (Ki = Kp/Ti)
v_int   = 25;                  % [mm/s] umbral de "bola quieta" (~2,2 veces la std de v_hat por ruido)
Nq      = 4;                   % [cuadros] el integrador actua tras Nq cuadros seguidos quieta
                               %   (cubre el arranque: retardo + tiempo en ganar velocidad)
e_clip  = 30;                  % [mm] recorte del error que entra al integrador
th_lim  = deg2rad(12);         % [rad] saturacion de la inclinacion pedida
sigma_m = 1.0;                 % [mm] ruido de la camara (marcador de config.py, PENDIENTE medir)
sigma_a_cand = [1500 1000 500 300];   % candidatos de PROCESS_ACCEL_STD [mm/s^2]

% Retardo equivalente de diseno: retardo total + medio periodo (ZOH) + atraso
% del servo (2/omega_n para un 2o orden critico).
te = P.retardo + P.Ts/2 + 2/omega_n_servo;

fprintf('=== 1. Datos de diseno ===\n');
fprintf('  Planta por eje (Etapa A): Xm/TH = (%.3f s^2 - %.2f)/s^2 [mm/rad], doble integrador.\n', L.Dm, L.Kg);
fprintf('  Retardo total (estimado): %.4f s; Ts = %.4f s; servo omega_n = %.0f rad/s (supuesto)\n', ...
    P.retardo, P.Ts, omega_n_servo);
fprintf('  Retardo equivalente de diseno te = retardo + Ts/2 + 2/omega_n = %.4f s\n', te);

%% 2. Sintonia del Kalman (queda dentro del lazo)
fprintf('\n=== 2. Kalman del pipeline: efecto de PROCESS_ACCEL_STD ===\n');
fprintf('  R = sigma_m^2 = %.2f mm^2 (marcador). Se comparan candidatos de sigma_a.\n', sigma_m^2);
fprintf('  sigma_a[mm/s^2]   K1      K2[1/s]   std(x_hat)[mm]  std(v_hat)[mm/s]  std(th)[deg]  PM[deg]  GMsup[dB]\n');
D = disenar_pd_asignacion(P, te, zeta, a_polo);
Tk = zeros(numel(sigma_a_cand), 8);
for i = 1:numel(sigma_a_cand)
    Kf = kalman_estacionario(P.Ts, sigma_a_cand(i), sigma_m);
    % ruido de medicion propagado por el filtro estacionario (solo ruido):
    % x_hat[k] = Af x_hat[k-1] + Kf n[k]  -> covarianza por Lyapunov discreta
    Af = (eye(2) - Kf*[1 0])*[1 P.Ts; 0 1];
    Sx = Kf*Kf'*sigma_m^2;
    for it = 1:5000, Sx = Af*Sx*Af' + Kf*Kf'*sigma_m^2; end
    sd = sqrt(diag(Sx));
    sd_th = sqrt([D.Kp D.Kd]*Sx*[D.Kp D.Kd]');
    Ct = struct('Kp',D.Kp,'Kd',D.Kd,'Ki',D.Kp/Ti,'Ts',P.Ts,'Kf',Kf);
    S = bop_lazo_lineal(P, L, Ct, P.retardo);
    Tk(i,:) = [sigma_a_cand(i) Kf' sd' rad2deg(sd_th) S.PM S.GM_sup_dB];
    fprintf('  %8.0f       %6.4f  %8.3f  %10.3f  %14.2f  %14.3f  %7.1f  %8.1f\n', Tk(i,:));
end
escribir_csv(fullfile(dirRes,'C1_kalman.csv'), ...
    {'sigma_a_mm_s2','K1','K2_1_s','std_xhat_mm','std_vhat_mm_s','std_th_deg','PM_deg','GM_sup_dB'}, Tk);
sigma_a = 500;
fprintf('  Eleccion: sigma_a = %d mm/s^2. Con 1500 (valor actual de config.py) la velocidad\n', sigma_a);
fprintf('  sale tan ruidosa que el plato tiembla; con 300 el atraso del filtro se come el margen.\n');
fprintf('  ** Implica cambiar PROCESS_ACCEL_STD en proyecto_ControlDIP-develop/src/config.py **\n');
fprintf('  (y repetir esta tabla cuando se mida MEAS_NOISE_STD_MM).\n');
Kf = kalman_estacionario(P.Ts, sigma_a, sigma_m);

%% 3. Kp y Kd por asignacion de polos
fprintf('\n=== 3. Asignacion de polos (modelo -c*g/(s^2 (te s + 1))) ===\n');
fprintf('  Polinomio deseado: te*(s + a*w)*(s^2 + 2*zeta*w*s + w^2), zeta = %.2f, a = %.2f\n', zeta, a_polo);
fprintf('  w = 1/(te*(a + 2*zeta)) = %.4f rad/s\n', D.w);
fprintf('  Polos de diseno: %s\n', sprintf('%.3f%+.3fj  ', [real(D.polos) imag(D.polos)].'));
Kp = D.Kp;  Kd = D.Kd;  Ki = Kp/Ti;
fprintf('  Kp = %.6f rad/mm   = %.5f deg/mm\n', Kp, rad2deg(Kp));
fprintf('  Kd = %.6f rad/(mm/s) = %.5f deg/(mm/s)\n', Kd, rad2deg(Kd));
fprintf('  Ki = Kp/Ti = %.6f rad/(mm s) = %.5f deg/(mm s)  (Ti = %.2f s)\n', Ki, rad2deg(Ki), Ti);

%% 4-5. Controlador
C = struct('Kp',Kp,'Ki',Ki,'Kd',Kd,'Ts',P.Ts,'th_lim',th_lim,'e_clip',e_clip, ...
           'v_int',v_int,'Nq',Nq,'Kf',Kf,'kalman_sigma_a',sigma_a,'kalman_sigma_m',sigma_m, ...
           'te',te,'zeta',zeta,'a',a_polo,'w',D.w,'Ti',Ti,'omega_n_servo',omega_n_servo);
fprintf('\n=== 4-5. Controlador ===\n');
fprintf('  Continuo equivalente (parte lineal), con eps = x - r y v = dx/dt:\n');
fprintf('    TH(s) = (Kp + Ki/s)*EPS(s) + Kd*V(s)\n');
fprintf('    C(s)  = Kd*s + Kp + Ki/s = (%.6f s^2 + %.6f s + %.6f)/s  [rad/mm]\n', Kd, Kp, Ki);
z_c = roots([Kd Kp Ki]);
fprintf('    Ceros del controlador: %s rad/s\n', sprintf('%.3f%+.3fj  ', [real(z_c) imag(z_c)].'));
fprintf('  Ley discreta (cada cuadro, Ts = %.4f s), por eje:\n', P.Ts);
fprintf('    eps[k]    = x_hat[k] - r[k]                          [mm]\n');
fprintf('    u[k]      = Kp*eps[k] + I[k] + Kd*v_hat[k]              [rad]\n');
fprintf('    th_cmd[k] = min(max(u[k], -th_lim), th_lim),  th_lim = %.1f deg\n', rad2deg(th_lim));
fprintf('    nq[k]     = nq[k-1] + 1 si |v_hat[k]| < %.0f mm/s; si no, 0\n', v_int);
fprintf('    I[k+1]    = I[k] + Ki*Ts*sat(eps[k], +-%.0f mm)  si nq[k] >= %d\n', e_clip, Nq);
fprintf('                y no (th_cmd saturado y sign(eps) == sign(u))   (clamping)\n');
fprintf('                I[k+1] = I[k] en otro caso\n');
fprintf('    Incremento por muestra de la integral: Ki*Ts = %.3e rad/(mm muestra) = %.3e deg/(mm muestra)\n', ...
    Ki*P.Ts, rad2deg(Ki*P.Ts));
fprintf('    (la ganancia continua es Ki = %.3e rad/(mm s); no confundir con el incremento por muestra)\n', Ki);
fprintf('  Kalman estacionario (sigma_a = %d, sigma_m = %.1f): K = [%.4f; %.3f 1/s]\n', sigma_a, sigma_m, Kf);
fprintf('  th_lim = %.1f deg: el mecanismo alcanza +-%.2f deg (A1); se deja margen por la asimetria y holguras.\n', ...
    rad2deg(th_lim), rad2deg(min(abs([bop_fk_plano(-P.phi_max,P) bop_fk_plano(P.phi_max,P)]))));

%% 6. Margenes y polos de lazo cerrado (nominal)
fprintf('\n=== 6. Lazo discreto nominal (planta ZOH + retardo %.3f s + Kalman + controlador lineal) ===\n', P.retardo);
S = bop_lazo_lineal(P, L, C, P.retardo);
fprintf('  Frecuencia de cruce wc = %.3f rad/s (%.3f Hz)\n', S.wc, S.wc/(2*pi));
fprintf('  Margen de fase        PM = %.1f deg   (criterio >= %.0f)\n', S.PM, Rq.PM_min_deg);
fprintf('  Margen de ganancia superior = %+.1f dB (la ganancia puede subir eso)\n', S.GM_sup_dB);
fprintf('  Margen de ganancia inferior = %+.1f dB (la ganancia puede bajar eso; la planta es\n', S.GM_inf_dB);
fprintf('    condicionalmente estable: con poca ganancia el doble integrador se desestabiliza)\n');
fprintf('  Margen de retardo = PM/wc = %.1f ms adicionales\n', 1000*S.margen_retardo);
if S.estable, txt = 'ESTABLE'; else, txt = 'INESTABLE'; end
fprintf('  Polos de lazo cerrado: radio maximo %.4f -> %s\n', S.radio_max, txt);
escribir_csv(fullfile(dirRes,'C1_bode.csv'), {'w_rad_s','mag_dB','fase_deg','re_L','im_L'}, ...
    [S.w S.mag_dB S.fase_deg real(S.L) imag(S.L)]);

%% 7. Robustez de los margenes
fprintf('\n=== 7. Robustez: margenes con variaciones (una a la vez) ===\n');
fprintf('  caso                          PM[deg]  GMsup[dB]  GMinf[dB]  wc[rad/s]  radio_max\n');
casos = { 'nominal',               P,                 P.retardo;
          'retardo 60 ms',         P,                 0.060;
          'retardo 90 ms',         P,                 0.090;
          'retardo 120 ms',        P,                 0.120;
          'c = 0,685',             bop_param_con(P,'c_rod',0.685),     P.retardo;
          'h_sup = 40 mm',         bop_param_con(P,'h_sup',40),        P.retardo;
          'h_sup = 60 mm',         bop_param_con(P,'h_sup',60),        P.retardo };
Rb = zeros(size(casos,1), 6);
for i = 1:size(casos,1)
    Pi = casos{i,2};  Li = bop_modelo_lineal(Pi);
    Si = bop_lazo_lineal(Pi, Li, C, casos{i,3});
    Rb(i,:) = [i Si.PM Si.GM_sup_dB Si.GM_inf_dB Si.wc Si.radio_max];
    fprintf('  %-28s %7.1f  %9.1f  %9.1f  %9.3f  %9.4f\n', casos{i,1}, Rb(i,2:6));
end
escribir_csv(fullfile(dirRes,'C1_robustez.csv'), {'caso','PM_deg','GM_sup_dB','GM_inf_dB','wc_rad_s','radio_max'}, Rb);
fprintf('  Casos: %s\n', strjoin(casos(:,1)', ' | '));

%% 8. Comparacion de estructuras con el simulador MIL nominal
fprintf('\n=== 8. Por que esta estructura: PD vs PID clasico vs PID con integracion condicional ===\n');
fprintf('  Mismo simulador (Etapa D), misma planta no lineal, Kp y Kd iguales; solo cambia la integral.\n');
estr = {'PD (sin integral)',        0,  Inf,   Inf,    1;
        'PID clasico',              Ki, Inf,   Inf,    1;
        'PID integ. condicional',   Ki, v_int, e_clip, Nq};
Te = zeros(3, 8);
serie_reg = [];  serie_dis = [];
for i = 1:3
    Ci = C;  Ci.Ki = estr{i,2};  Ci.v_int = estr{i,3};  Ci.e_clip = estr{i,4};  Ci.Nq = estr{i,5};
    cfg = bop_mil_config(P, Ci);  cfg.kalman_sigma_a = sigma_a;  cfg.omega_n_servo = omega_n_servo;
    cfg.x0 = [Rq.x0_mm; 0];  cfg.T_fin = 6.5;
    R1 = bop_mil_simular(cfg);  M1 = bop_metricas_respuesta(R1, 1, Rq);
    cfg.x0 = [0; 0];  cfg.th_dist = [deg2rad(1); 0];  cfg.T_fin = 10;  cfg.t_espera = 0;
    R2 = bop_mil_simular(cfg);  M2 = bop_metricas_respuesta(R2, 1, Rq);
    Te(i,:) = [i M1.ts M1.Mp M1.ess M1.th_max_deg M2.max_abs_xhat M2.ess M1.std_th_ss_deg];
    fprintf('  %-26s regulacion 100 mm: ts = %5.2f s, Mp = %5.1f %%, ess = %5.2f mm | desnivel 1 deg: max|x| = %5.1f mm, ess = %5.2f mm\n', ...
        estr{i,1}, M1.ts, M1.Mp, M1.ess, M2.max_abs_xhat, M2.ess);
    if isempty(serie_reg)
        serie_reg = R1.k_tcap;  serie_dis = R2.k_tcap;
    end
    n1 = min(numel(serie_reg(:,1)), numel(R1.k_tcap));  n2 = min(numel(serie_dis(:,1)), numel(R2.k_tcap));
    serie_reg = [serie_reg(1:n1,:) R1.k_xh(1:n1,1) R1.k_th(1:n1,1)];
    serie_dis = [serie_dis(1:n2,:) R2.k_xh(1:n2,1) R2.k_th(1:n2,1)];
end
escribir_csv(fullfile(dirRes,'C1_estructuras.csv'), ...
    {'estructura_1PD_2PID_3PIDcond','ts_s','Mp_pct','ess_mm','th_max_deg','desnivel_max_x_mm','desnivel_ess_mm','std_th_ss_deg'}, Te);
cab = {'t_s','xh_PD_mm','th_PD_rad','xh_PID_mm','th_PID_rad','xh_PIDcond_mm','th_PIDcond_rad'};
escribir_csv(fullfile(dirRes,'C1_estructuras_regulacion.csv'), cab, serie_reg);
escribir_csv(fullfile(dirRes,'C1_estructuras_desnivel.csv'), cab, serie_dis);
fprintf('  Lectura: el PD no corrige el desnivel (error = desnivel/Kp); el PID clasico lo corrige\n');
fprintf('  pero su integral se carga durante todo el recorrido y da sobreimpulso grande; la\n');
fprintf('  integracion condicional (solo con la bola quieta %d cuadros) conserva la respuesta\n', Nq);
fprintf('  del PD y corrige el desnivel.\n');

%% Guardado
C.margenes = rmfield(S, {'w','L','P','C','mag_dB','fase_deg'});
C.P_diseno = P;
C.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
Ctrl = C; %#ok<NASGU>
save(fullfile(dirRes,'C1_controlador.mat'), 'Ctrl', 'Rq');
fprintf('\nControlador guardado en %s (variable Ctrl)\n', fullfile(dirRes,'C1_controlador.mat'));
fprintf('FIN C1\n');

