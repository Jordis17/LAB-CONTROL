function v = rmse_v(e)
%RMSE_V Raiz del error cuadratico medio de un vector.
v = sqrt(mean(e(:).^2));
end
