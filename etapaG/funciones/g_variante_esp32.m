function variante = g_variante_esp32(mdl, modulo, preferida)
% Elige la variante de la ESP32 (CoderTargetData.ESP32.ESP32_board), que el
% paquete deja vacia al cambiar la placa. Las opciones salen de la misma
% funcion que usa el dialogo: getESP32SupportedBoards(hObj, modulo).
% modulo: 'ESP32-WROOM'; preferida: texto a buscar (p. ej. 'Dev Module').
cs = getActiveConfigSet(mdl);
lista = {};
for obj = {cs, get_param(mdl,'Handle'), mdl}
    try
        lista = codertarget.arduinobase.registry.getESP32SupportedBoards(obj{1}, modulo);
        break
    catch e
        fprintf('  getESP32SupportedBoards(%s): %s\n', class(obj{1}), e.message);
    end
end
if isstring(lista), lista = cellstr(lista); end
if ischar(lista), lista = strsplit(lista, ';'); end
fprintf('Variantes de %s que ofrece el paquete:\n', modulo);
if isempty(lista)
    fprintf('  (ninguna)\n');  variante = '';  return
end
fprintf('  - %s\n', lista{:});
i = find(contains(lista, preferida, 'IgnoreCase', true), 1);
if isempty(i), i = 1; end
variante = lista{i};
data = get_param(cs, 'CoderTargetData');
data.ESP32.ESP32_board = variante;
try
    codertarget.data.setData(cs, data);
catch
    set_param(cs, 'CoderTargetData', data);
end
d2 = get_param(cs, 'CoderTargetData');
fprintf('ESP32.ESP32_board = "%s"\n', d2.ESP32.ESP32_board);
end
