function g_conexion_target_framework(placa, puerto, baud)
% Target Framework: muestra lo que Simulink tiene definido para la placa y
% agrega (solo para esta sesion de MATLAB) un target.TargetConnection por
% puerto serie, que es lo que pide el error "Target is underspecified ...
% Specify a target.TargetConnection object with Target property set to Board".
fprintf('\n--- Target Framework: placa "%s" ---\n', placa);
try
    b = target.get('Board', placa);
catch e
    fprintf('target.get(Board) fallo: %s\n', e.message);  return
end
disp(b);
for p = {'Processors','CommunicationInterfaces','CommunicationProtocolStacks','Tools','MainFunctions'}
    try
        v = b.(p{1});
        fprintf('%s (%d):\n', p{1}, numel(v));
        for i = 1:numel(v), disp(v(i)); end
    catch
        fprintf('%s: (no existe)\n', p{1});
    end
end
try
    ci = b.CommunicationInterfaces;
    for i = 1:numel(ci)
        try, fprintf('Interfaz %d: canal %s\n', i, class(ci(i).Channel)); disp(ci(i).Channel); catch, end
        try, disp(ci(i).APIImplementations); catch, end
    end
catch
end
% Conexiones existentes para la placa
try
    cs = target.get('TargetConnection');
    fprintf('TargetConnection registradas: %d\n', numel(cs));
    for i = 1:numel(cs)
        try, fprintf('  - %s -> %s\n', cs(i).Name, cs(i).Target.Name); catch, end
    end
catch
end
% Nueva conexion por serie
nombre = 'ESP32 BoP serie';
try
    viejas = target.get('TargetConnection', nombre);
    if ~isempty(viejas), target.remove(viejas); end
catch
end
try
    c = target.create('TargetConnection');
    c.Name = nombre;
    c.Target = b;
    c.CommunicationChannel = target.create('RS232Channel');
    c.CommunicationChannel.Name = 'ESP32 BoP RS232';
    c.CommunicationChannel.SerialPort = puerto;
    c.CommunicationChannel.BaudRate = baud;
    target.add(c, 'UserInstall', false);
    fprintf('TargetConnection "%s" agregada: %s a %d baud\n', nombre, puerto, baud);
    disp(c);
catch e
    fprintf('No se pudo crear la TargetConnection:\n%s\n', e.getReport('extended','hyperlinks','off'));
end
end
