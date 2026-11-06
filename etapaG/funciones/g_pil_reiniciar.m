function g_pil_reiniciar(sp)
% Reinicia las dos instancias del controlador en la ESP32 (Controller_BoP_ESP32_initialize).
flush(sp);
write(sp, uint8([165 'R' 'R']), 'uint8');
r = read(sp, 7, 'uint8');
if numel(r) ~= 7 || r(1) ~= 90 || r(2) ~= 'R'
    error('G:PIL', 'Respuesta inesperada al reinicio: %s', mat2str(r));
end
end
