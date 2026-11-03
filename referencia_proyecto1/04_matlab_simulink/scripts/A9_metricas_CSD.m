%% A9_metricas_CSD.m — ejecutar con Run despues de simular el modelo MIL
% Mismas definiciones de metricas que A8_validar_TCLab_SIMC.m

if ~exist('T_ref','var') || ~exist('T_amb','var')
    error('Falta T_ref o T_amb. Ejecute primero A8_init_TCLab_SIMC.');
end

casos = {'PI-SIMC con AW', 'T1_conAW_sim', 'Q1_conAW_sim'; ...
         'PI-CSD  con AW', 'T1_CSD_sim'  , 'Q1_CSD_sim'  };

fprintf('\n%-16s %8s %8s %8s %11s %9s %9s %9s\n', ...
    'Caso','tr [s]','ts [s]','Mp [%]','ess [degC]','Tmax','Q1min','Q1max');
fprintf('%s\n', repmat('-',1,84));

for k = 1:size(casos,1)
    nT = casos{k,2};   nQ = casos{k,3};

    if ~exist(nT,'var') || ~exist(nQ,'var')
        fprintf('%-16s  >> faltan %s / %s en el workspace\n', casos{k,1}, nT, nQ);
        continue
    end

    Tts = eval(nT);    Qts = eval(nQ);
    t   = Tts.Time;
    T1  = squeeze(Tts.Data);
    Q1  = squeeze(Qts.Data);

    info = stepinfo(T1 - T_amb, t, T_ref - T_amb, 'SettlingTimeThreshold', 0.02);
    ess  = T_ref - mean(T1(t >= t(end)-60));

    fprintf('%-16s %8.2f %8.2f %8.2f %11.4f %9.2f %9.2f %9.2f\n', ...
        casos{k,1}, info.RiseTime, info.SettlingTime, info.Overshoot, ...
        ess, max(T1), min(Q1), max(Q1));
end