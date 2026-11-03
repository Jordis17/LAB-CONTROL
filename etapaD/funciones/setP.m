function cfg = setP(cfg, campo, valor)
%SETP Copia de una configuracion MIL con un parametro de la planta cambiado.
cfg.P = bop_param_con(cfg.P, campo, valor);
end
