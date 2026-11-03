function imprimir_ceros(nombre, z)
%IMPRIMIR_CEROS Imprime ceros continuos y su frecuencia.
if isempty(z)
    fprintf('  Ceros de %s: ninguno\n', nombre);
    return
end
for i = 1:numel(z)
    fprintf('  Cero de %s: s = %+9.3f %+9.3fj rad/s   (|s| = %.3f rad/s = %.3f Hz)\n', ...
        nombre, real(z(i)), imag(z(i)), abs(z(i)), abs(z(i))/(2*pi));
end
end
