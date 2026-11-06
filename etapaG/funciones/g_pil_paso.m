function [th, I, sat, ciclos] = g_pil_paso(sp, eje, r, x, v, hab)
% Un paso del controlador en la ESP32. eje: 0 = X, 1 = Y.
% Las entradas viajan como double IEEE de 8 bytes, sin redondeo.
p = [uint8(eje) typecast(double(r), 'uint8') typecast(double(x), 'uint8') ...
     typecast(double(v), 'uint8') uint8(logical(hab))];
ck = bitxor(uint8('S'), xorsum(p));
write(sp, [uint8(165) uint8('S') p ck], 'uint8');
b = read(sp, 24, 'uint8');
if numel(b) ~= 24 || b(1) ~= 90
    error('G:PIL', 'Respuesta incompleta de la ESP32 (%d bytes): %s', numel(b), mat2str(b));
end
if b(2) == 'E'
    error('G:PIL', 'La ESP32 informo el error %d', b(3));
end
if b(2) ~= 'S' || b(24) ~= xorsum(b(2:23))
    error('G:PIL', 'Trama de respuesta invalida: %s', mat2str(b));
end
th = typecast(uint8(b(3:10)), 'double');
I  = typecast(uint8(b(11:18)), 'double');
sat = b(19) ~= 0;
ciclos = double(typecast(uint8(b(20:23)), 'uint32'));
end

function c = xorsum(v)
c = uint8(0);
for i = 1:numel(v), c = bitxor(c, uint8(v(i))); end
end
