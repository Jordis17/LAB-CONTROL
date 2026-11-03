%% ETAPA A - SCRIPT 2: LINEALIZACION Y ERROR DE LA APROXIMACION LINEAL
% Este script:
%   1. Construye el modelo lineal de un eje alrededor de x = y = 0, th = 0,
%      thd = 0 (bop_modelo_lineal) e imprime la funcion de transferencia, el
%      modelo en espacio de estados, los polos y los ceros.
%   2. Verifica la linealizacion analitica contra un jacobiano numerico del
%      modelo no lineal (bop_aceleracion y bop_medicion).
%   3. Discretiza el modelo con ZOH a Ts, sin retardo y con el retardo
%      estimado, e imprime polos y ceros discretos.
%   4. Compara el modelo lineal con el no lineal para dos amplitudes de
%      inclinacion (1 y 10 grados) en un eje, y para un caso con los dos ejes
%      a la vez (acople).
%   5. Barre la amplitud de 0,5 a 13 grados, con transicion rapida y lenta,
%      y delimita el rango en que el error relativo queda bajo el umbral.
%   6. Expresa el termino centrifugo como inclinacion equivalente.
%
% Requisito previo: ninguno (no usa resultados de A1).
% No requiere Control System Toolbox; si esta, ademas imprime los modelos tf/ss.
%
% Salidas (carpeta resultados/):
%   A2_consola.txt, A2_modelo_lineal.mat,
%   A2_comparacion_A01_rapida.csv, A2_comparacion_A01_lenta.csv,
%   A2_comparacion_A10_rapida.csv, A2_comparacion_A10_lenta.csv,
%   A2_comparacion_2ejes.csv, A2_barrido_amplitud.csv
% El orden de columnas de cada CSV esta en orden_csv.md.

clearvars; close all; clc;

carpeta = fileparts(mfilename('fullpath'));
addpath(fullfile(carpeta,'funciones'));
dirRes = fullfile(carpeta,'resultados');
if ~isfolder(dirRes), mkdir(dirRes); end
archivoConsola = fullfile(dirRes,'A2_consola.txt');
if isfile(archivoConsola), delete(archivoConsola); end
diary(archivoConsola);
limpiezaDiary = onCleanup(@() diary('off'));

fprintf('ETAPA A - A2_linealizar_BoP   (%s)\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s\n', version);

P = A0_parametros_BoP(true);
L = bop_modelo_lineal(P);

%% Parametros de la comparacion (decisiones de la Etapa A, documentadas en LEEME_etapaA.md)
A_casos_deg   = [1 10];        % las dos amplitudes de la comparacion [deg]
x_pico_frac   = 0.6;           % desplazamiento maximo pedido al triplete, fraccion de x_max
umbral_rel    = 5;             % umbral de validez del modelo lineal [% de max|x|]
A_barrido_deg = [0.5 1:13]';   % barrido de amplitud [deg] (13,7 deg es el maximo alcanzable)
frac_lenta    = 0.8;           % transicion lenta: tr = frac_lenta*T
dt_salida     = 0.001;         % paso de la rejilla de comparacion [s]
t_reposo      = 0.2;           % reposo antes de que empiece la primera transicion [s]
t_post        = 0.5;           % tiempo simulado despues del perfil [s]

%% 1. Modelo lineal
fprintf('=== 1. Modelo lineal de un eje (x = 0, th = 0, thd = 0) ===\n');
fprintf('  Hipotesis: rodadura sin deslizamiento, sin friccion, plato rigido,\n');
fprintf('  actuador ideal (th es la entrada), camara fija sobre la junta.\n\n');
fprintf('  h_ef = h + k*r_b       = %8.3f mm\n', L.h_ef);
fprintf('  c*g                    = %8.2f mm/(s^2 rad)  (= %.3f mm/(s^2 deg))\n', L.Kg, L.Kg*pi/180);
fprintf('  c*h_ef                 = %8.3f mm/rad\n', L.Dx);
fprintf('  c*h_ef - h             = %8.3f mm/rad  (= -(1-c)*h_sup = %.3f)\n', L.Dm, -(1-P.c_rod)*P.h_sup);
fprintf('\n  Posicion sobre el plato (restriccion |x| <= %.0f mm):\n', P.x_max);
fprintf('             %8.3f s^2 - %9.2f\n', L.Dx, L.Kg);
fprintf('    X/TH = -------------------------   [mm/rad]\n');
fprintf('                     s^2\n');
fprintf('\n  Posicion medida por la camara (realimentacion):\n');
fprintf('             %8.3f s^2 - %9.2f\n', L.Dm, L.Kg);
fprintf('    Xm/TH = ------------------------   [mm/rad]\n');
fprintf('                     s^2\n');
fprintf('\n  Polos: s = 0 (doble). Doble integrador: no es estable en lazo abierto.\n');
imprimir_ceros('X/TH ', L.ceros_x);
imprimir_ceros('Xm/TH', L.ceros_Xm);
fprintf('\n  Espacio de estados (estados xi = x - c*h_ef*th [mm], xid [mm/s]; entrada th [rad]):\n');
fprintf('    A = [0 1; 0 0]\n');
fprintf('    B = [0; %.2f]\n', L.B(2));
fprintf('    C = [1 0; 1 0]   (salidas: x, Xm)\n');
fprintf('    D = [%.3f; %.3f]\n', L.D(1), L.D(2));

usar_cst = false;
try
    usar_cst = license('test','Control_Toolbox') && exist('tf','file') > 0;
catch
end
if usar_cst
    G_x  = tf(L.num_x,  L.den);
    G_Xm = tf(L.num_Xm, L.den);
    fprintf('\n  Control System Toolbox disponible: tf de X/TH y Xm/TH:\n');
    disp(G_x);  disp(G_Xm);
else
    fprintf('\n  Control System Toolbox no detectado: se omiten los objetos tf/ss.\n');
end

%% 2. Verificacion con jacobiano numerico
fprintf('\n=== 2. Jacobiano numerico del modelo no lineal en el punto de operacion ===\n');
% variables: [x y xd yd thx thy thxd thyd thxdd thydd]
v0 = zeros(10,1);
fa = @(v) bop_aceleracion(v(1:2), v(3:4), v(5:6), v(7:8), v(9:10), P);
Jn = zeros(2,10);
paso = [1e-3*ones(1,4) 1e-6*ones(1,4) 1e-4*ones(1,2)];
for j = 1:10
    dv = zeros(10,1);  dv(j) = paso(j);
    Jn(:,j) = (fa(v0+dv) - fa(v0-dv))/(2*paso(j));
end
Ja = zeros(2,10);
Ja(1,5) = -L.Kg;  Ja(1,9)  = L.Dx;
Ja(2,6) = -L.Kg;  Ja(2,10) = L.Dx;
fprintf('  Jacobiano numerico de [xdd; ydd] respecto de [x y xd yd thx thy thxd thyd thxdd thydd]:\n');
fprintf('    %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f\n', Jn.');
err_jac = max(abs(Jn(:)-Ja(:)))/max(abs(Ja(:)));
fprintf('  Diferencia relativa maxima con el analitico: %.2e\n', err_jac);
fprintf('  Terminos cruzados (x <-> y) en el punto de operacion: %.2e (0 => ejes desacoplados a primer orden)\n', ...
    max(abs([Jn(1,[2 4 6 8 10]) Jn(2,[1 3 5 7 9])])));

fm = @(v) bop_medicion(v(1:2), v(3:4), P);
Jm = zeros(2,4);
for j = 1:4
    dv = zeros(4,1);  dv(j) = 1e-6;
    Jm(:,j) = (fm(dv) - fm(-dv))/2e-6;
end
fprintf('  Jacobiano de [Xm; Ym] respecto de [x y thx thy]:\n');
fprintf('    %10.4f %10.4f %10.4f %10.4f\n', Jm.');
fprintf('  Esperado: [1 0 -h 0; 0 1 0 -h] con h = %.3f mm\n', P.h);

%% 3. Modelo discreto
fprintf('\n=== 3. Modelo discreto (ZOH, Ts = %.4f s) ===\n', P.Ts);
Dsin = bop_discretizar(L.A, L.B, L.C(2,:), L.D(2), P.Ts, 0);
Dcon = bop_discretizar(L.A, L.B, L.C(2,:), L.D(2), P.Ts, P.retardo);
fprintf('  Sin retardo (salida Xm):\n');
imprimir_discreto(Dsin);
fprintf('  Con retardo %.4f s (%s) = (%d - 1)*Ts + %.4f s:\n', P.retardo, P.estado.retardo, Dcon.d, Dcon.tau1);
imprimir_discreto(Dcon);
if usar_cst
    try
        Gd = c2d(ss(L.A, L.B, L.C(2,:), L.D(2), 'InputDelay', P.retardo), P.Ts, 'zoh');
        fprintf('  Comprobacion con c2d (Control System Toolbox):\n');
        disp(tf(Gd));
        pc = sort(abs(pole(Gd)));  pp = sort(abs(eig(Dcon.A)));
        fprintf('  |polos| c2d vs bop_discretizar: max diferencia %.2e\n', max(abs(pc - pp(end-numel(pc)+1:end))));
    catch err
        fprintf('  c2d fallo: %s\n', err.message);
    end
end

%% 4. Comparacion lineal vs no lineal
pend = pendiente_servo_plato(P);
omega_plato = pend*P.omega_srv;
fprintf('\n=== 4. Comparacion modelo lineal vs no lineal ===\n');
fprintf('  Entrada: triplete +A (T), -A (2T), +A (T), transiciones de coseno alzado.\n');
fprintf('  T se elige para que el doble integrador ideal llegue a %.0f %% de x_max = %.1f mm.\n', ...
    100*x_pico_frac, x_pico_frac*P.x_max);
fprintf('  Velocidad maxima del plato = %.4f (pendiente servo-plato) x %.1f deg/s = %.1f deg/s\n', ...
    pend, rad2deg(P.omega_srv), rad2deg(omega_plato));
fprintf('  Dos tipos de transicion:\n');
fprintf('    rapida: tr = max(T_pwm, pi*A/omega_plato), el plato se mueve a la velocidad maxima del servo;\n');
fprintf('    lenta : tr = %.1f*T, velocidad angular baja.\n', frac_lenta);
fprintf('  Error = lineal - no lineal; metricas sobre todo el perfil mas %.1f s.\n', t_post);
fprintf('  Ademas se descompone el error de aceleracion del modelo (no lineal - lineal, evaluado sobre\n');
fprintf('  la trayectoria no lineal) en: seno (sin th vs th), centrifugo (x*thd^2) y resto.\n');
fprintf('  Se expresa como inclinacion equivalente th_eq = error/(c*g).\n\n');

modos = {'rapida','lenta'};
casos = struct([]);
for i = 1:numel(A_casos_deg)
    for m = 1:numel(modos)
        A = deg2rad(A_casos_deg(i));
        [T, tr] = parametros_triplete(A, x_pico_frac, P, L, omega_plato, modos{m}, frac_lenta);
        t0 = t_reposo + tr/2;          % la primera transicion empieza en t_reposo, con todo en reposo
        t_fin = t0 + 4*T + tr + t_post;
        R = bop_simular_triplete(P, L, A, 0, T, t0, t0, tr, t_fin, dt_salida);
        Mx = bop_metricas_error(R.t, R.x_nl,  R.x_li,  0, t_fin);
        Mm = bop_metricas_error(R.t, R.Xm_nl, R.Xm_li, 0, t_fin);
        E  = bop_terminos_error(R, P, L);
        fprintf('  Caso A = %4.1f deg, transicion %s (T = %.3f s, tr = %.3f s, max|thd| = %.1f deg/s):\n', ...
            A_casos_deg(i), modos{m}, T, tr, rad2deg(max(abs(R.thxd))));
        imprimir_metricas('x  (plato) ', Mx);
        imprimir_metricas('Xm (camara)', Mm);
        fprintf('    Al final: x_nl = %.2f mm, xd_nl = %.2f mm/s (el lineal vuelve a 0)\n', R.x_nl(end), R.xd_nl(end));
        imprimir_terminos(E);
        if R.toca_pared, fprintf('    AVISO: la bola del modelo no lineal pasa |x| = %.0f mm.\n', P.x_max); end
        nombre = sprintf('A2_comparacion_A%02d_%s.csv', A_casos_deg(i), modos{m});
        escribir_csv(fullfile(dirRes,nombre), ...
            {'t_s','thx_deg','thxd_deg_s','x_nl_mm','x_li_mm','err_x_mm','Xm_nl_mm','Xm_li_mm','err_Xm_mm', ...
             'eacc_total_mm_s2','eacc_sen_mm_s2','eacc_centrif_mm_s2','eacc_resto_mm_s2'}, ...
            [R.t rad2deg(R.thx) rad2deg(R.thxd) R.x_nl R.x_li R.x_li-R.x_nl R.Xm_nl R.Xm_li R.Xm_li-R.Xm_nl ...
             E.total E.sen E.centrif E.resto]);
        k = numel(casos) + 1;
        casos(k).A_deg = A_casos_deg(i);  casos(k).modo = modos{m};
        casos(k).T = T;  casos(k).tr = tr;  casos(k).thd_max = max(abs(R.thxd));
        casos(k).Mx = Mx;  casos(k).Mm = Mm;  casos(k).E = rmfield(E, {'total','sen','centrif','resto'});
        casos(k).archivo = nombre;
    end
end

% Caso con los dos ejes: misma amplitud, eje Y desfasado T/2 para que haya
% velocidad angular en los dos ejes mientras la bola esta lejos del centro.
% Transicion rapida (peor caso). El caso de un eje equivalente es el de arriba.
A2ej_deg = max(A_casos_deg);
A = deg2rad(A2ej_deg);
[T, tr] = parametros_triplete(A, x_pico_frac, P, L, omega_plato, 'rapida', frac_lenta);
t0 = t_reposo + tr/2;
t_fin = t0 + 4.5*T + tr + t_post;
R = bop_simular_triplete(P, L, A, A, T, t0, t0+T/2, tr, t_fin, dt_salida);
Mx2 = bop_metricas_error(R.t, R.x_nl, R.x_li, 0, t_fin);
My2 = bop_metricas_error(R.t, R.y_nl, R.y_li, 0, t_fin);
% Para aislar el acople: el eje Y solo, con el mismo perfil y el mismo desfase.
R1 = bop_simular_triplete(P, L, 0, A, T, t0, t0+T/2, tr, t_fin, dt_salida);
dy_acople = R.y_nl - R1.y_nl;
R0 = bop_simular_triplete(P, L, A, 0, T, t0, t0+T/2, tr, t_fin, dt_salida);
dx_acople = R.x_nl - R0.x_nl;
fprintf('\n  Caso dos ejes A = %.1f deg en X y en Y, transicion rapida (Y desfasado T/2 = %.3f s):\n', A2ej_deg, T/2);
imprimir_metricas('x       ', Mx2);
imprimir_metricas('y       ', My2);
fprintf('    Efecto del acople (no lineal 2 ejes - no lineal 1 eje): max|dx| = %.3f mm, max|dy| = %.3f mm\n', ...
    max(abs(dx_acople)), max(abs(dy_acople)));
escribir_csv(fullfile(dirRes,'A2_comparacion_2ejes.csv'), ...
    {'t_s','thx_deg','thy_deg','x_nl_mm','x_li_mm','y_nl_mm','y_li_mm','err_x_mm','err_y_mm','dx_acople_mm','dy_acople_mm'}, ...
    [R.t rad2deg(R.thx) rad2deg(R.thy) R.x_nl R.x_li R.y_nl R.y_li R.x_li-R.x_nl R.y_li-R.y_nl dx_acople dy_acople]);
caso2ejes = struct('A_deg',A2ej_deg,'T',T,'tr',tr,'Mx',Mx2,'My',My2, ...
    'max_dx_acople',max(abs(dx_acople)),'max_dy_acople',max(abs(dy_acople)));

%% 5. Barrido de amplitud (un eje, transicion rapida y lenta)
fprintf('\n=== 5. Barrido de amplitud (un eje) ===\n');
fprintf('  modo    A[deg]  T[s]   tr[s] thd[deg/s] max|x|[mm] max|e_x|[mm] e_x[%%] e_Xm[%%]  th_eq_sen[deg] th_eq_cf[deg]\n');
B = NaN(numel(A_barrido_deg)*numel(modos), 13);
k = 0;
for m = 1:numel(modos)
    for i = 1:numel(A_barrido_deg)
        k = k + 1;
        A = deg2rad(A_barrido_deg(i));
        B(k,1:2) = [A_barrido_deg(i) m];
        try
            [T, tr] = parametros_triplete(A, x_pico_frac, P, L, omega_plato, modos{m}, frac_lenta);
        catch
            fprintf('  %-7s %5.1f   (no se puede: tr >= T)\n', modos{m}, A_barrido_deg(i));
            continue
        end
        t0 = t_reposo + tr/2;
        t_fin = t0 + 4*T + tr + t_post;
        R = bop_simular_triplete(P, L, A, 0, T, t0, t0, tr, t_fin, dt_salida);
        Mx = bop_metricas_error(R.t, R.x_nl,  R.x_li,  0, t_fin);
        Mm = bop_metricas_error(R.t, R.Xm_nl, R.Xm_li, 0, t_fin);
        E  = bop_terminos_error(R, P, L);
        B(k,:) = [A_barrido_deg(i) m T tr rad2deg(max(abs(R.thxd))) Mx.max_ref Mx.max_err Mx.rel_pct Mx.rmse ...
                  Mm.max_err Mm.rel_pct E.th_eq_sen_deg E.th_eq_cf_deg];
        fprintf('  %-7s %5.1f  %6.3f %6.3f %8.1f %10.2f %11.3f %7.2f %7.2f %12.4f %13.4f\n', ...
            modos{m}, B(k,[1 3 4 5 6 7 8 11 12 13]));
    end
end
escribir_csv(fullfile(dirRes,'A2_barrido_amplitud.csv'), ...
    {'A_deg','modo_1rapida_2lenta','T_s','tr_s','max_thd_deg_s','max_x_nl_mm','max_err_x_mm','err_rel_x_pct','rmse_x_mm', ...
     'max_err_Xm_mm','err_rel_Xm_pct','th_eq_sen_deg','th_eq_centrif_deg'}, B);
A_valido = NaN(2,2);
for m = 1:numel(modos)
    sel = B(:,2) == m & ~isnan(B(:,3));
    A_valido(m,1) = ultimo_valido(B(sel,1), B(sel,8)  < umbral_rel);
    A_valido(m,2) = ultimo_valido(B(sel,1), B(sel,11) < umbral_rel);
end
fprintf('\n  Umbral de validez: error relativo < %.1f %% de max|x| sobre el triplete completo.\n', umbral_rel);
for m = 1:numel(modos)
    fprintf('  Transicion %-7s: valido para x hasta A = %s deg; para Xm hasta A = %s deg\n', ...
        modos{m}, num2str(A_valido(m,1)), num2str(A_valido(m,2)));
end

%% 6. Termino centrifugo como inclinacion equivalente
fprintf('\n=== 6. Termino centrifugo x*thd^2 expresado como inclinacion equivalente ===\n');
fprintf('  th_eq = x*thd^2/g (lo que habria que inclinar el plato para producir la misma aceleracion)\n');
x_tab = [25 50 100 P.x_max];
thd_tab = [0.5 1 2 omega_plato];
fprintf('   x[mm] \\ thd[rad/s]:'); fprintf('%10.2f', thd_tab); fprintf('\n');
Tcf = zeros(numel(x_tab), numel(thd_tab));
for i = 1:numel(x_tab)
    Tcf(i,:) = rad2deg(x_tab(i)*thd_tab.^2/P.g);
    fprintf('   %6.0f            ', x_tab(i)); fprintf('%10.3f', Tcf(i,:)); fprintf('   [deg]\n');
end
fprintf('  (la ultima columna es la velocidad maxima del plato con el servo a 4,8 V)\n');

%% Guardado
A2.P = P;  A2.L = L;
A2.discreto_sin_retardo = Dsin;  A2.discreto_con_retardo = Dcon;
A2.err_jacobiano_rel = err_jac;  A2.jacobiano_numerico = Jn;  A2.jacobiano_medicion = Jm;
A2.pendiente_servo_plato = pend;  A2.omega_plato = omega_plato;
A2.casos = casos;  A2.caso2ejes = caso2ejes;
A2.barrido = B;  A2.umbral_rel_pct = umbral_rel;
A2.A_valido_deg = A_valido;   % filas: rapida, lenta; columnas: x, Xm
A2.centrifugo_th_eq_deg = Tcf;  A2.centrifugo_x_mm = x_tab;  A2.centrifugo_thd_rad_s = thd_tab;
A2.x_pico_frac = x_pico_frac;  A2.frac_lenta = frac_lenta;
A2.fecha = datestr(now,'yyyy-mm-dd HH:MM:SS');
save(fullfile(dirRes,'A2_modelo_lineal.mat'), 'A2');
fprintf('\nResultados guardados en %s\n', dirRes);
fprintf('FIN A2\n');
