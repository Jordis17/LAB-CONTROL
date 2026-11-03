function escribir_csv(archivo, encabezados, datos)
%ESCRIBIR_CSV CSV con encabezado, separador coma y punto decimal.
%
%   escribir_csv(archivo, {'t_s','x_mm'}, [t x])
%
% Se usa en lugar de writetable para que el formato sea identico en
% cualquier version de MATLAB (y para no depender de tablas).

if numel(encabezados) ~= size(datos,2)
    error('escribir_csv: %d encabezados para %d columnas.', ...
        numel(encabezados), size(datos,2));
end
fid = fopen(archivo, 'w');
if fid < 0
    error('escribir_csv: no se pudo abrir %s', archivo);
end
limpieza = onCleanup(@() fclose(fid));
fprintf(fid, '%s', encabezados{1});
fprintf(fid, ',%s', encabezados{2:end});
fprintf(fid, '\n');
fmt = [repmat('%.10g,', 1, size(datos,2)-1) '%.10g\n'];
fprintf(fid, fmt, datos.');
end
