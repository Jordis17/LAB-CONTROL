"""Margen de fase del lazo con el modelo nominal identificado y retardo puro.

L(s) = c*g*(Kd*s + Kp + Ki/s)*exp(-td*s)/s^2   (ganancias en rad/mm, g en mm/s^2)
Repite el calculo del rediseno preliminar (estado_proyecto.md, 2026-11-13), que se hizo
originalmente fuera de MATLAB. Correr: python3 informe/scripts/margenes_retardo.py
"""
import numpy as np
G, R = 9810.0, np.pi / 180
CTRL = {'original (Etapa C)': (0.034118997, 0.025875847, 0.022745998),
        'rediseno (c = 0,3; te = 0,44 s)': (0.00727, 0.0184, 0.00727 / 5)}
TD = 0.44
w = np.logspace(-2, 2, 200000)
s = 1j * w
print(f'Retardo puro td = {TD} s')
print('controlador                        ley  c     wc[rad/s]  PM[deg]  GMsup[dB]')
print('(PID: con la integral como termino lineal, caso conservador; PD: sin integral)')
for nombre, (kp, kd, ki0) in CTRL.items():
  for con_i in (True, False):
    ki = ki0 if con_i else 0.0
    for c in (0.15, 0.2, 0.3, 0.45, 0.57):
        L = c * G * (kd * R * s + kp * R + ki * R / s) * np.exp(-TD * s) / s**2
        mag = np.abs(L)
        i = np.where(np.diff(np.sign(mag - 1)))[0]
        ic = i[-1]                                   # ultimo cruce de |L| = 1
        pm = np.degrees(np.angle(L[ic])) + 180
        pm = (pm + 180) % 360 - 180
        # margen de ganancia superior: cruce de fase -180 por encima de wc
        fase = np.degrees(np.angle(L))
        j = [k for k in np.where(np.diff(np.sign(np.sin(np.radians(fase)))))[0]
             if k > ic and np.cos(np.radians(fase[k])) < 0]
        gm = -20 * np.log10(mag[j[0]]) if j else float('inf')
        print(f'{nombre:34s} {"PID" if con_i else "PD ":3s} {c:4.2f} {w[ic]:9.3f} {pm:8.1f} {gm:9.1f}')
