function [K, Pss] = kalman_estacionario(Ts, sigma_a, sigma_m)
%KALMAN_ESTACIONARIO Ganancia estacionaria del Kalman de un eje del pipeline.
%
%   [K, Pss] = kalman_estacionario(Ts, sigma_a, sigma_m)
%
% Mismo modelo que src/processing/kalman.py (por eje; el filtro 2D esta
% desacoplado): velocidad constante, F = [1 Ts; 0 1], H = [1 0],
% Q = sigma_a^2*[Ts^4/4 Ts^3/2; Ts^3/2 Ts^2], R = sigma_m^2.
% sigma_a = PROCESS_ACCEL_STD [mm/s^2], sigma_m = MEAS_NOISE_STD_MM [mm].
% K es la ganancia de correccion (2x1) una vez que el filtro convergio.

F = [1 Ts; 0 1];  H = [1 0];
Q = sigma_a^2*[Ts^4/4 Ts^3/2; Ts^3/2 Ts^2];
R = sigma_m^2;
Pp = eye(2)*1e4;
for i = 1:5000
    K = Pp*H'/(H*Pp*H' + R);
    Pc = (eye(2) - K*H)*Pp;
    Pp_n = F*Pc*F' + Q;
    if max(abs(Pp_n(:) - Pp(:))) < 1e-12*max(abs(Pp(:)))
        Pp = Pp_n;
        break
    end
    Pp = Pp_n;
end
K = Pp*H'/(H*Pp*H' + R);
Pss = (eye(2) - K*H)*Pp;
end
