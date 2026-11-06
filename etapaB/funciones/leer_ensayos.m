function E = leer_ensayos(archivo)
%LEER_ENSAYOS Lee datos_prototipo/etapaB/ensayos.csv.
%
% Columnas (en este orden, con encabezado):
%   archivo,ensayo,eje,comando_deg,th_app_deg,repeticion,borde,observaciones
%   archivo       nombre del CSV de main_vision.py (en la misma carpeta)
%   ensayo        B1 o B2
%   eje           X o Y
%   comando_deg   comando del sketch prueba_servos (grados)
%   th_app_deg    lectura de la app del celular en ese eje (se usa su valor absoluto)
%   repeticion    1, 2, 3, ...
%   borde         solo B2: +X, -X, +Y o -Y (borde contra el que esta la bola); B1: vacio
%   observaciones texto libre SIN comas
% Devuelve un arreglo de estructuras, una por fila.
fid = fopen(archivo, 'r');
if fid < 0, error('leer_ensayos:NoAbre', 'No se pudo abrir %s', archivo); end
limpieza = onCleanup(@() fclose(fid));
fgetl(fid);   % encabezado
E = struct('archivo',{},'ensayo',{},'eje',{},'comando_deg',{},'th_app_deg',{}, ...
           'repeticion',{},'borde',{},'observaciones',{});
while true
    l = fgetl(fid);
    if ~ischar(l), break; end
    if isempty(strtrim(l)), continue; end
    c = strsplit(l, ',', 'CollapseDelimiters', false);
    c(end+1:8) = {''};
    k = numel(E) + 1;
    E(k).archivo = strtrim(c{1});  E(k).ensayo = upper(strtrim(c{2}));
    E(k).eje = upper(strtrim(c{3}));  E(k).comando_deg = str2double(c{4});
    E(k).th_app_deg = str2double(c{5});  E(k).repeticion = str2double(c{6});
    E(k).borde = upper(strtrim(c{7}));  E(k).observaciones = strtrim(strjoin(c(8:end), ' '));
end
end
