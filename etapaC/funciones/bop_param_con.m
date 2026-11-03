function Pn = bop_param_con(P, campo, valor)
%BOP_PARAM_CON Copia de P con un parametro cambiado y sus derivados actualizados.
%   Pn = bop_param_con(P, 'c_rod', 0.685)
%   Pn = bop_param_con(P, 'h_sup', 40)
%   Pn = bop_param_con(P, 'omega_srv', deg2rad(60)/0.08)
Pn = P;
Pn.(campo) = valor;
switch campo
    case 'c_rod'
        Pn.k_inercia = 1/valor - 1;
    case 'h_sup'
        Pn.h = valor + P.r_bola;
end
end
