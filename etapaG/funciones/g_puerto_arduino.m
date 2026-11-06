function g_puerto_arduino(mdl, puerto)
% Imprime la configuracion del paquete de Arduino guardada en el modelo
% (CoderTargetData) y fija el puerto serie de la ESP32 en los campos de
% "Host-board connection" (descarga, Connected IO y modo externo), que son los
% que el paquete usa para hablar con la placa. No toca ConnectionInfo.*: esos
% campos son expresiones que el paquete evalua (getExternalModeMexArgs, ...).
cs = getActiveConfigSet(mdl);
data = get_param(cs, 'CoderTargetData');
fprintf('\nCoderTargetData (configuracion del paquete en el modelo):\n');
imprimir(data, '');
if ~isfield(data, 'HostBoardConnection')
    fprintf('AVISO: no hay HostBoardConnection; fijen el puerto en la interfaz grafica.\n');
    return
end
h = data.HostBoardConnection;
for c = {'AppDownload', 'ConnectedIO', 'ExternalMode'}
    if isfield(h, [c{1} '_COMPort_specify'])
        h.([c{1} '_COMPort_specify']) = puerto;
        fprintf('  HostBoardConnection.%s_COMPort_specify -> %s\n', c{1}, puerto);
    end
end
data.HostBoardConnection = h;
try
    codertarget.data.setData(cs, data);
catch
    set_param(cs, 'CoderTargetData', data);
end
if isfield(data, 'ESP32') && isfield(data.ESP32, 'ESP32_board') && isempty(data.ESP32.ESP32_board)
    fprintf(['AVISO: ESP32.ESP32_board esta vacio (variante de la placa sin elegir en ' ...
             'Target hardware resources).\n']);
end
end

function imprimir(s, ruta)
f = fieldnames(s);
for i = 1:numel(f)
    v = s.(f{i});  r = [ruta '.' f{i}];
    if isstruct(v) && isscalar(v)
        if strcmp(f{i}, 'DashboardCodegenInfo') || strcmp(f{i}, 'MQTT') || strcmp(f{i}, 'Wifi') || strcmp(f{i}, 'BLE'), continue; end
        imprimir(v, r);
    else
        if ischar(v) || isstring(v), txt = char(v);
        elseif (isnumeric(v) || islogical(v)) && numel(v) <= 4, txt = mat2str(v);
        else, txt = sprintf('<%s>', class(v)); end
        fprintf('  %-50s %s\n', r(2:end), txt);
    end
end
end
