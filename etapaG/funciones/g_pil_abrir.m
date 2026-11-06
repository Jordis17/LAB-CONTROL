function sp = g_pil_abrir(puerto)
% Abre el puerto de la ESP32 (sketch bop_pil_esp32) y comprueba el protocolo.
% Baja DTR y RTS: en las placas con CP2102 esas lineas manejan EN e IO0, y
% dejarlas activas puede mantener la ESP32 en reinicio o en modo de carga.
sp = serialport(puerto, 115200, 'Timeout', 2);
try, setDTR(sp, false); setRTS(sp, false); catch, end
pause(2.5);                 % arranque de la ESP32 (imprime basura del ROM a 115200)
flush(sp);
for intento = 1:5
    write(sp, uint8([165 'R' 'R']), 'uint8');
    r = leer(sp, 7);
    if numel(r) == 7 && r(1) == 90 && r(2) == 'R' && isequal(char(r(3:6)), 'BoP1') ...
            && r(7) == bitxor(bitxor(bitxor(bitxor(r(2), r(3)), r(4)), r(5)), r(6))
        fprintf('ESP32 responde en %s (protocolo BoP1), intento %d\n', puerto, intento);
        return
    end
    pause(1);  flush(sp);
end
error('G:PIL', 'La ESP32 no respondio en %s. Revisen que el sketch este cargado (G3) y el puerto libre.', puerto);
end

function r = leer(sp, n)
r = uint8([]);
t0 = tic;
while numel(r) < n && toc(t0) < 2
    k = sp.NumBytesAvailable;
    if k > 0, r = [r; read(sp, min(k, n - numel(r)), 'uint8')']; else, pause(0.002); end %#ok<AGROW>
end
r = r(:)';
% descartar basura antes del 0x5A
i = find(r == 90, 1);
if isempty(i), r = uint8([]); else, r = r(i:end); end
while numel(r) < n && toc(t0) < 2
    k = sp.NumBytesAvailable;
    if k > 0, r = [r read(sp, min(k, n - numel(r)), 'uint8')]; else, pause(0.002); end %#ok<AGROW>
end
end
