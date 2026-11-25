function [th_cmd, ub_n, z_n, u, saturado, integra] = bop_ley_lqr(x_hat, v_hat, r, ub, z, ...
    K, Ts, th_lim, e_clip, usar_aw, saturar)
%BOP_LEY_LQR Ley LQR con accion integral (LQI) de UN eje, un paso.
%
%   [th_cmd, ub_n, z_n, u, saturado, integra] = bop_ley_lqr(x_hat, v_hat, r, ub, z, ...
%       K, Ts, th_lim, e_clip, usar_aw, saturar)
%
% Segunda estrategia de control (Etapa C, C2_disenar_LQR_BoP). Realimentacion
% de estados con el estado aumentado del modelo de diseno (bop_modelo_lqr):
%
%   s[k]  = [ e ; v_hat ; u[k-d] ; ... ; u[k-1] ; z ],   e = x_hat - r
%   u[k]  = -K*s[k]                       [rad]
%   th_cmd = sat(u, +-th_lim)
%   z[k+1] = z[k] + Ts*sat(e[k], +-e_clip)   salvo que este saturado y el
%                             integrador empuje hacia la saturacion (clamping)
%   El recorte e_clip limita lo que el integrador acumula mientras la bola
%   viaja (sin el, el LQI se pasa y vuelve lento; ver C2).
%   el registro de entradas pasadas guarda th_cmd (lo que se mando).
%
% Las entradas pasadas hacen de predictor: el controlador "sabe" que
% inclinaciones ya mando y que todavia no le llegaron a la bola por el retardo.
%
% Entradas: x_hat [mm], v_hat [mm/s], r [mm], ub (d x 1) [rad] = [u[k-d] ... u[k-1]],
%           z [mm s], K (1 x (d+3)), Ts [s], th_lim [rad], e_clip [mm], usar_aw, saturar.
%#codegen

d = numel(ub);
e = x_hat - r;
s = [e; v_hat; ub(:); z];
u = -K*s;
if saturar
    th_cmd = min(max(u, -th_lim), th_lim);
else
    th_cmd = u;
end
saturado = (th_cmd ~= u);
du_z = -K(end)*Ts*e;                       % lo que el integrador sumaria a u
congelar = usar_aw && saturado && (sign(du_z) == sign(u));
integra = ~congelar;
if integra
    z_n = z + Ts*min(max(e, -e_clip), e_clip);
else
    z_n = z;
end
ub_n = ub(:);
if d > 0
    ub_n = [ub_n(2:end); th_cmd];
end
end
