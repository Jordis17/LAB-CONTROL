function imprimir_discreto(Dm)
%IMPRIMIR_DISCRETO Polos, ceros y matrices de un modelo de bop_discretizar.
n = size(Dm.A,1);
fprintf('    Orden %d (2 estados de la planta + %d de retardo)\n', n, Dm.d);
fprintf('    Ad =\n');  fprintf(['      ' repmat('%11.6f ',1,n) '\n'], Dm.A.');
fprintf('    Bd = [%s]''\n', sprintf(' %.6g', Dm.B));
fprintf('    Cd = [%s]\n',  sprintf(' %.6g', Dm.C));
fprintf('    Dd = %.6g\n', Dm.D);
p = eig(Dm.A);
fprintf('    Polos z: %s\n', sprintf('%.4f%+.4fj  ', [real(p) imag(p)].'));
% ceros de transmision: valores propios generalizados finitos de la matriz de Rosenbrock
Mr = [Dm.A Dm.B; Dm.C Dm.D];
Nr = blkdiag(eye(n), 0);
z = eig(Mr, Nr);
z = z(isfinite(z) & abs(z) < 1e8);
if isempty(z)
    fprintf('    Ceros z: ninguno finito\n');
else
    fprintf('    Ceros z: %s\n', sprintf('%.4f%+.4fj  ', [real(z) imag(z)].'));
    fprintf('    |ceros z|: %s\n', sprintf('%.4f  ', abs(z)));
end
end
