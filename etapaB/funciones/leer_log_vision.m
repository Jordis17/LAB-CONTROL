function L = leer_log_vision(archivo)
%LEER_LOG_VISION Lee un CSV de main_vision.py (logs/sesion_*.csv).
%
%   L = leer_log_vision(archivo)
%
% Columnas del pipeline (src/datalog.py): t, dt, fps, detectada, x_raw, y_raw,
% x, y, vx, vy, area, circularidad, enviado. Los campos vacios (bola no
% detectada) quedan en NaN. Devuelve una estructura con un vector por columna
% y L.n (filas). Funciona sin toolboxes (no usa readtable).

fid = fopen(archivo, 'r');
if fid < 0
    error('leer_log_vision:NoAbre', 'No se pudo abrir %s', archivo);
end
limpieza = onCleanup(@() fclose(fid));
cab = strtrim(fgetl(fid));
nombres = strsplit(cab, ',');
datos = zeros(0, numel(nombres));
while true
    l = fgetl(fid);
    if ~ischar(l), break; end
    if isempty(strtrim(l)), continue; end
    campos = strsplit(l, ',', 'CollapseDelimiters', false);
    v = NaN(1, numel(nombres));
    for j = 1:min(numel(campos), numel(nombres))
        v(j) = str2double(campos{j});
    end
    datos(end+1,:) = v; %#ok<AGROW>
end
for j = 1:numel(nombres)
    L.(strtrim(nombres{j})) = datos(:,j);
end
L.n = size(datos,1);
L.archivo = archivo;
end
