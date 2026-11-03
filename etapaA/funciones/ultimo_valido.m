function A_max = ultimo_valido(A, ok)
%ULTIMO_VALIDO Mayor A tal que todos los valores hasta el cumplen el criterio.
%   NaN si ni el primero lo cumple.
idx = find(~ok(:), 1, 'first');
if isempty(idx)
    A_max = A(end);
elseif idx == 1
    A_max = NaN;
else
    A_max = A(idx-1);
end
end
