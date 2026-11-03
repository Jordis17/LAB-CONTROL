function s = limpiar(s)
%LIMPIAR Nombre de caso apto para archivo/campo.
s = regexprep(s, '[^A-Za-z0-9]+', '_');
s = regexprep(s, '_+$', '');
end
