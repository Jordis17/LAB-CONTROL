%% A12_visualizar_Implementacion_TCLab.m
% Visualización de resultados de la implementación física del controlador
% PI-SIMC sobre TCLab mediante Monitor & Tune.

%% Verificar datos registrados
if ~exist('logsout','var')
    error(['No se encontró la variable logsout en el workspace. ' ...
        'Ejecute primero el experimento mediante Monitor & Tune.']);
end

%% Extraer señales por nombre
sig_Tref = logsout.getElement('T_ref');
sig_T1   = logsout.getElement('T1');
sig_Q1   = logsout.getElement('Q1');

Tref = sig_Tref.Values;
T1   = sig_T1.Values;
Q1   = sig_Q1.Values;

%% Extraer tiempo y datos
t_Tref = Tref.Time;
t_T1   = T1.Time;
t_Q1   = Q1.Time;

y_Tref = squeeze(Tref.Data);
y_T1   = squeeze(T1.Data);
y_Q1   = squeeze(Q1.Data);

%% Visualización
figure('Name','Implementación física TCLab');

tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% -------------------------------------------------------------------------
% Temperatura
nexttile

plot(t_Tref,y_Tref,'LineWidth',1.5);
hold on
plot(t_T1,y_T1,'LineWidth',1.5);

grid on
box on

ylabel('Temperatura [°C]');

legend('$T_{\mathrm{ref}}$','$T_1$', ...
    'Interpreter','latex', ...
    'Location','best');

title('Respuesta experimental de la TCLab');

% -------------------------------------------------------------------------
% Acción de control
nexttile

plot(t_Q1,y_Q1,'LineWidth',1.5);

grid on
box on

xlabel('Tiempo [s]');
ylabel('$Q_1$ [\%]','Interpreter','latex');

%% Ajustar eje temporal común
t_max = max([t_Tref(end), t_T1(end), t_Q1(end)]);

ax = findall(gcf,'Type','axes');
set(ax,'XLim',[0 t_max]);