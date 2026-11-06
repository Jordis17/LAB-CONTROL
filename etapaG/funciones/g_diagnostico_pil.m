function g_diagnostico_pil(mdl)
% Se llama solo si la simulacion PIL falla. Busca en el paquete de Arduino
% donde se registra la configuracion de conexion PIL "Arduino Board" y con
% que criterio se asocia a un modelo (placa, tipo de procesador, ...), para
% saber por que no coincide con Controller_BoP_ESP32.
fprintf('\n===== DIAGNOSTICO PIL =====\n');
for p = {'HardwareBoard','ProdHWDeviceType','TargetHWDeviceType','ProdEqTarget','PortableWordSizes', ...
         'SystemTargetFile','TargetLang','Toolchain','CreateSILPILBlock'}
    try
        v = get_param(mdl, p{1});  if isnumeric(v), v = num2str(v); end
        fprintf('  %-20s %s\n', p{1}, v);
    catch
    end
end
try
    raiz = matlabshared.supportpkg.getSupportPackageRoot;
catch
    raiz = '';
end
fprintf('Raiz de paquetes: %s\n', raiz);
if isempty(raiz), return; end
[~, txt] = system(sprintf('grep -rIl --include=*.m -e "Arduino Board" "%s" 2>/dev/null | head -20', raiz));
fprintf('Archivos .m que mencionan "Arduino Board":\n%s\n', txt);
archivos = strsplit(strtrim(txt), newline);
for i = 1:min(numel(archivos), 6)
    a = strtrim(archivos{i});
    if isempty(a) || ~isfile(a), continue; end
    fprintf('----- %s -----\n', a);
    [~, l] = system(sprintf('grep -n -i -E "Arduino Board|HWDeviceType|HardwareBoard|ConfigRegistry|isConfigSetCompatible|ESP32|Board|config\\." "%s" | head -60', a));
    fprintf('%s\n', l);
end
[~, txt] = system(sprintf('grep -rIl --include=*.m -i -e "ESP32" "%s" 2>/dev/null | grep -i -E "pil|connectivity|registry" | head -20', raiz));
fprintf('Archivos de PIL/conectividad que mencionan ESP32:\n%s\n', txt);
fprintf('===== FIN DIAGNOSTICO =====\n');
end
