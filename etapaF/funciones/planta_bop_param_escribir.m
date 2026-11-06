function planta_bop_param_escribir(P, C, archivo)
%PLANTA_BOP_PARAM_ESCRIBIR Genera planta_bop_param.m con los valores como literales.
%
% El bloque MATLAB Function de la planta necesita los parametros como
% constantes en el codigo. Este generador los escribe a partir de la Etapa A
% (A0_parametros_BoP) y de la Etapa C (C1_controlador.mat), para que no haya
% numeros copiados a mano. Lo llama F0_build_Test_SIL_BoP.
fid = fopen(archivo, 'w');
if fid < 0, error('No se pudo escribir %s', archivo); end
c = onCleanup(@() fclose(fid));
fprintf(fid, 'function Pp = planta_bop_param()\n');
fprintf(fid, '%%PLANTA_BOP_PARAM Parametros de la planta del banco SIL/PIL.\n');
fprintf(fid, '%% ARCHIVO GENERADO por planta_bop_param_escribir (%s). No editar a mano.\n', datestr(now,'yyyy-mm-dd HH:MM'));
fprintf(fid, '%%#codegen\n');
campos = {'g','c_rod','k_inercia','r_bola','h','h_sup','H_cam'};
for i = 1:numel(campos)
    fprintf(fid, 'P.%s = %.17g;\n', campos{i}, P.(campos{i}));
end
fprintf(fid, 'Pp.P = P;\n');
fprintf(fid, 'Pp.Ts = %.17g;          %% periodo [s]\n', C.Ts);
fprintf(fid, 'Pp.N = 33;              %% subpasos de integracion por periodo\n');
fprintf(fid, 'Pp.wn = %.17g;          %% servo, 2o orden critico [rad/s] (supuesto, igual que el MIL)\n', C.omega_n_servo);
fprintf(fid, 'Pp.w_max = %.17g;       %% velocidad maxima del plato [rad/s] (200 deg/s)\n', deg2rad(200));
fprintf(fid, 'Pp.th_max = %.17g;      %% inclinacion maxima del plato [rad] (11,3 deg, tabla medida)\n', deg2rad(11.3));
fprintf(fid, 'Pp.nd = 1;              %% retardo de medicion [cuadros] (+1 cuadro del Unit Delay del banco)\n');
fprintf(fid, 'Pp.sigma = 1;           %% ruido de la camara [mm]\n');
fprintf(fid, 'Pp.kal_sa = %.17g;      %% Kalman sigma_a [mm/s^2]\n', C.kalman_sigma_a);
fprintf(fid, 'Pp.kal_sm = %.17g;      %% Kalman sigma_m [mm]\n', C.kalman_sigma_m);
fprintf(fid, 'Pp.x0 = [80; -60];      %% posicion inicial de la bola [mm] (como el ensayo D4)\n');
fprintf(fid, 'Pp.semilla = 12345;\n');
fprintf(fid, 'end\n');
end
