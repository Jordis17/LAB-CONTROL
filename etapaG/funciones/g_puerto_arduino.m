function g_puerto_arduino(mdl, puerto)
% Imprime la configuracion del paquete de Arduino guardada en el modelo
% (CoderTargetData) y fija el puerto serie a mano en los campos que lo piden.
% Sirve para PIL: si el paquete no detecta solo la placa (las ESP32 con
% CP2102 no son placas Arduino "oficiales"), la configuracion de conexion PIL
% queda sin puerto y falla con "Index exceeds array bounds".
cs = getActiveConfigSet(mdl);
data = get_param(cs, 'CoderTargetData');
fprintf('\nCoderTargetData (configuracion del paquete en el modelo):\n');
[data, cambios] = recorrer(data, '', puerto);
if isempty(cambios)
    fprintf(['AVISO: no se encontro ningun campo de puerto COM. Fijenlo a mano: Hardware board settings > ' ...
             'Target hardware resources > Host-board connection > Set host COM port: Manually.\n']);
    return
end
try
    codertarget.data.setData(cs, data);
catch
    set_param(cs, 'CoderTargetData', data);
end
fprintf('Puerto fijado en: %s\n', strjoin(cambios, ', '));
end

function [s, cambios] = recorrer(s, ruta, puerto)
cambios = {};
f = fieldnames(s);
for i = 1:numel(f)
    v = s.(f{i});  r = [ruta '.' f{i}];
    if isstruct(v) && isscalar(v)
        [v, c] = recorrer(v, r, puerto);  s.(f{i}) = v;  cambios = [cambios c]; %#ok<AGROW>
    else
        if ischar(v) || isstring(v), txt = char(v);
        elseif (isnumeric(v) || islogical(v)) && numel(v) <= 4, txt = mat2str(v);
        else, txt = sprintf('<%s>', class(v)); end
        fprintf('  %-50s %s\n', r(2:end), txt);
        if (ischar(v) || isstring(v)) && ~isempty(regexpi(f{i}, '^(com_?port|port|serialport|hostcomport)$', 'once'))
            s.(f{i}) = puerto;  cambios{end+1} = r(2:end); %#ok<AGROW>
            fprintf('  %-50s -> %s\n', '', puerto);
        end
    end
end
end
