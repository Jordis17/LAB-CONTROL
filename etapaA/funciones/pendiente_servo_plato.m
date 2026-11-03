function pend = pendiente_servo_plato(P)
%PENDIENTE_SERVO_PLATO dth/dphi del mecanismo en el neutro (eje X) [rad/rad].
e = 1e-6;
thp = bop_cinematica_directa([ e; 0], P);
thm = bop_cinematica_directa([-e; 0], P);
pend = (thp(1) - thm(1))/(2*e);
end
