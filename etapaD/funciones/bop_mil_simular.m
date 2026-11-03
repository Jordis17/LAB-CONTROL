function R = bop_mil_simular(cfg)
%BOP_MIL_SIMULAR Simulacion MIL del lazo completo de dos ejes.
%
%   R = bop_mil_simular(cfg)        cfg de bop_mil_config
%
% Cadena simulada (unidades mm, s, rad):
%
%   planta continua (bola no lineal de la Etapa A, 2 ejes, RK4 con dt = Ts/N_sub)
%     -> camara: muestrea Xm en t_k = k*Ts (bop_medicion) + ruido gaussiano
%     -> el dato llega a la ESP32 en t_k + tau_m, tau_m = retardo - T_pwm/2
%     -> Kalman por eje (igual que kalman.py, dt = Ts, arranca en la 1a medida)
%     -> controlador por eje (bop_controlador_paso)
%     -> cinematica inversa por eje (modo 'plano', lo que haria el firmware)
%     -> el servo recibe el objetivo en el siguiente flanco del PWM (T_pwm)
%     -> servo: 2o orden critico (omega_n), velocidad maxima omega_srv,
%        carrera +-phi_max
%     -> cinematica directa por eje (bop_fk_plano) + desnivel th_dist -> plato
%
% Durante cfg.t_espera el controlador no actua (th_cmd = 0, integrador en 0):
% es el arranque del ensayo con la bola quieta, igual que en el experimento.
%
% Con cfg.actuador_ideal = true se quita la cinematica y todos los limites:
% el plato sigue th_cmd con la misma dinamica de 2o orden, sin saturaciones.
%
% Hipotesis adicionales: la cinematica se trata por eje (el acople 3D del
% mecanismo, <0,63 deg en +-12 deg segun A1, no se modela); la exposicion
% de la camara es instantanea; la ESP32 calcula en tiempo cero.

P = cfg.P;  C = cfg.C;
Ts = C.Ts;  dt = Ts/cfg.N_sub;
tau_m = cfg.retardo - P.T_pwm/2;
if tau_m < 0
    error('bop_mil_simular: retardo (%g s) menor que T_pwm/2.', cfg.retardo);
end
L = bop_modelo_lineal(P);
ideal = cfg.actuador_ideal;
saturar = cfg.saturar && ~ideal;

N = round(cfg.T_fin/dt);
n_fr = floor(cfg.T_fin/Ts) + 1;

% Estado continuo: [x y xd yd  a1 a2 a1d a2d]
%   a = angulo del servo (phi) o, con actuador ideal, angulo del plato.
s = [cfg.x0(:); cfg.v0(:); 0; 0; 0; 0];
obj = [0; 0];                 % objetivo actual del servo (o del plato, si es ideal)
obj_pend = [];  t_pend = Inf; % objetivo que espera el siguiente flanco del PWM

% Kalman (por eje)
F = [1 Ts; 0 1];  H = [1 0];
Q = cfg.kalman_sigma_a^2*[Ts^4/4 Ts^3/2; Ts^3/2 Ts^2];
Rk = cfg.kalman_sigma_m^2;
kf_x = cell(2,1);  kf_P = cell(2,1);  kf_ini = false;
Ec = {bop_controlador_estado0(); bop_controlador_estado0()};

% Cola de mediciones en transito
cola_t = [];  cola_y = zeros(2,0);  cola_k = [];
rng_estado = cfg.semilla;
if exist('OCTAVE_VERSION','builtin')
    randn('state', rng_estado);
else
    rng(rng_estado, 'twister');
end

% Registro continuo (submuestreado cada paso)
R.t = (0:N)'*dt;
R.x = zeros(N+1,2);  R.th = zeros(N+1,2);  R.a = zeros(N+1,2);
% Registro por cuadro (cuando la ESP32 calcula)
R.k_t = NaN(n_fr,1);  R.k_tcap = NaN(n_fr,1);
R.k_y = NaN(n_fr,2);  R.k_xh = NaN(n_fr,2);  R.k_vh = NaN(n_fr,2);
R.k_r = NaN(n_fr,2);  R.k_th = NaN(n_fr,2);  R.k_u = NaN(n_fr,2);
R.k_sat = false(n_fr,2);  R.k_I = NaN(n_fr,2);
nk = 0;  k_cap = 0;  t_cap = 0;

for i = 0:N
    t = i*dt;

    % --- registro del estado continuo
    [th, ~, ~] = angulo_plato(s, cfg, P, L, obj);
    R.x(i+1,:) = s(1:2)';  R.th(i+1,:) = th';  R.a(i+1,:) = s(5:6)';

    % --- captura de la camara
    if t >= t_cap - 1e-9
        y = medir(s, th, P, cfg) + cfg.sigma_ruido*randn(2,1);
        cola_t(end+1) = t + tau_m;  cola_y(:,end+1) = y;  cola_k(end+1) = t; %#ok<AGROW>
        k_cap = k_cap + 1;  t_cap = k_cap*Ts;
    end

    % --- llegada de mediciones a la ESP32: Kalman + controlador
    while ~isempty(cola_t) && t >= cola_t(1) - 1e-9
        y = cola_y(:,1);  tcap = cola_k(1);
        cola_t(1) = [];  cola_y(:,1) = [];  cola_k(1) = [];
        r = cfg.r(tcap);
        th_cmd = [0; 0];  u = [0; 0];  sat = [false; false];
        for e = 1:2
            if ~kf_ini
                kf_x{e} = [y(e); 0];
                kf_P{e} = diag([Rk 1e4]);
            else
                kf_x{e} = F*kf_x{e};
                kf_P{e} = F*kf_P{e}*F' + Q;
            end
            Kk = kf_P{e}*H'/(H*kf_P{e}*H' + Rk);
            kf_x{e} = kf_x{e} + Kk*(y(e) - H*kf_x{e});
            kf_P{e} = (eye(2) - Kk*H)*kf_P{e};
            if tcap >= cfg.t_espera - 1e-9
                [th_cmd(e), Ec{e}, info_c] = bop_controlador_paso(kf_x{e}(1), kf_x{e}(2), r(e), Ec{e}, C, cfg.usar_aw, saturar);
                u(e) = info_c.u;  sat(e) = info_c.saturado;
            end
        end
        kf_ini = true;
        nk = nk + 1;
        R.k_t(nk) = t;  R.k_tcap(nk) = tcap;  R.k_y(nk,:) = y';
        R.k_xh(nk,:) = [kf_x{1}(1) kf_x{2}(1)];  R.k_vh(nk,:) = [kf_x{1}(2) kf_x{2}(2)];
        R.k_r(nk,:) = r';  R.k_th(nk,:) = th_cmd';  R.k_u(nk,:) = u';  R.k_sat(nk,:) = sat';
        R.k_I(nk,:) = [Ec{1}.I Ec{2}.I];
        % objetivo del actuador
        if ideal
            obj_pend = th_cmd;
        else
            phi = bop_cinematica_inversa(th_cmd, P, 'plano');
            phi(isnan(phi)) = sign(th_cmd(isnan(phi)))*P.phi_max;
            obj_pend = min(max(phi, -P.phi_max), P.phi_max);
        end
        t_pend = ceil((t + 1e-9)/P.T_pwm)*P.T_pwm;     % siguiente flanco del PWM
    end
    if ~isempty(obj_pend) && t >= t_pend - 1e-9
        obj = obj_pend;  obj_pend = [];  t_pend = Inf;
    end

    if i == N, break; end

    % --- integracion RK4 de la planta y el servo
    f = @(ss) derivada(ss, cfg, P, L, obj);
    k1 = f(s);  k2 = f(s + dt/2*k1);  k3 = f(s + dt/2*k2);  k4 = f(s + dt*k3);
    s = s + dt/6*(k1 + 2*k2 + 2*k3 + k4);
    if ~ideal
        % limites duros del servo
        for e = 1:2
            if abs(s(4+e)) > P.phi_max
                s(4+e) = sign(s(4+e))*P.phi_max;
                if sign(s(6+e)) == sign(s(4+e)), s(6+e) = 0; end
            end
            s(6+e) = min(max(s(6+e), -P.omega_srv), P.omega_srv);
        end
    end
end

nk = max(nk,1);
campos = {'k_t','k_tcap','k_y','k_xh','k_vh','k_r','k_th','k_u','k_sat','k_I'};
for j = 1:numel(campos)
    R.(campos{j}) = R.(campos{j})(1:nk,:);
end
R.cfg = cfg;
R.toca_pared = any(abs(R.x(:)) > P.x_max);
end

% ----------------------------------------------------------------------
function ds = derivada(s, cfg, P, L, obj)
[th, thd, thdd, add] = angulo_plato(s, cfg, P, L, obj);
q = s(1:2);  qd = s(3:4);
if strcmp(cfg.planta, 'lineal')
    qdd = P.c_rod*(-P.g*th + L.h_ef*thdd);
else
    qdd = bop_aceleracion(q, qd, th, thd, thdd, P);
end
ds = [qd; qdd; s(7:8); add];
end

function [th, thd, thdd, add] = angulo_plato(s, cfg, P, L, obj) %#ok<INUSD>
% Angulo del plato y aceleracion del actuador a partir del estado del servo.
a = s(5:6);  ad = s(7:8);
wn = cfg.omega_n_servo;
add = wn^2*(obj - a) - 2*wn*ad;
if ~cfg.actuador_ideal
    for e = 1:2
        % limite de velocidad y de carrera: no se acelera hacia afuera
        if (abs(ad(e)) >= P.omega_srv && sign(add(e)) == sign(ad(e))) || ...
           (abs(a(e)) >= P.phi_max && sign(add(e)) == sign(a(e)))
            add(e) = 0;
        end
    end
    th = zeros(2,1);  thd = th;  thdd = th;
    for e = 1:2
        [g0, g1, g2] = bop_fk_plano(a(e), P);
        th(e) = g0;  thd(e) = g1*ad(e);  thdd(e) = g2*ad(e)^2 + g1*add(e);
    end
else
    th = a;  thd = ad;  thdd = add;
end
th = th + cfg.th_dist;
end

function y = medir(s, th, P, cfg)
if strcmp(cfg.planta, 'lineal')
    y = s(1:2) - P.h*th;
else
    y = bop_medicion(s(1:2), th, P);
end
end
