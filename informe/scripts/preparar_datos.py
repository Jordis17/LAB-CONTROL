"""Prepara los CSV de las figuras y tablas del informe que salen de logs del prototipo.

Correr desde la raiz del repo:  python3 informe/scripts/preparar_datos.py
Escribe en informe/datos_graficas/ e imprime las metricas que se citan en el informe.
Definiciones de las metricas: las de la Seccion I del informe (etapaC/C0_requisitos_BoP.m).
"""
import csv, math, os, statistics as st

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SAL = os.path.join(RAIZ, 'informe', 'datos_graficas')
LOGS = os.path.join(RAIZ, 'datos_prototipo', 'etapaB')


def leer_log(nombre):
    r = list(csv.DictReader(open(os.path.join(LOGS, nombre + '.csv'))))
    t0 = float(r[0]['t'])
    for x in r:
        x['ts'] = float(x['t']) - t0
    return r


def f(v):
    return float(v) if v not in ('', None) else math.nan


# ---------------------------------------------------------------- B3: validacion por ventanas
def b3_validacion(n_ventanas=6):
    r = list(csv.DictReader(open(os.path.join(RAIZ, 'etapaB', 'resultados', 'B3_validacion.csv'))))
    # log 2 = el de validacion; modelo 1 = identificado, 2 = nominal
    filas = []
    k = 0
    for eje in ('1', '2'):
        vent = []
        for x in r:
            if x['eje'] == eje and x['modelo'] == '1' and x['ventana'] not in vent:
                vent.append(x['ventana'])
        for w in vent[:n_ventanas]:
            ide = [x for x in r if x['eje'] == eje and x['ventana'] == w and x['modelo'] == '1']
            nom = [x for x in r if x['eje'] == eje and x['ventana'] == w and x['modelo'] == '2']
            for a, b in zip(ide, nom):
                xm, xi, xn = f(a['x_med_mm']), f(a['x_pred_mm']), f(b['x_pred_mm'])
                filas.append([k, eje, w, a['t_s'], xm, xi, xn, xm - xi, xm - xn])
                k += 1
            filas.append([k, eje, w, '', 'nan', 'nan', 'nan', 'nan', 'nan'])   # corte entre ventanas
            k += 1
    with open(os.path.join(SAL, 'B3_validacion_ventanas.csv'), 'w', newline='') as fo:
        w = csv.writer(fo)
        w.writerow(['k', 'eje', 'ventana', 't_s', 'x_med_mm', 'x_ident_mm', 'x_nom_mm',
                    'res_ident_mm', 'res_nom_mm'])
        w.writerows(filas)
    print(f'B3_validacion_ventanas.csv: {n_ventanas} ventanas por eje, {len(filas)} filas')


# ---------------------------------------------------------------- escalones del ensayo automatico
def metricas_escalones(nombre):
    r = [x for x in leer_log(nombre) if x['tel_modo'] != '']
    cambios = []
    for i in range(1, len(r)):
        for e, kr in (('X', 'tel_rx'), ('Y', 'tel_ry')):
            a, b = f(r[i - 1][kr]), f(r[i][kr])
            fase = int(r[i]['tel_banderas']) >> 4
            if r[i]['tel_modo'] == '3' and fase == 2 and abs(b - a) >= 20:   # fase 2: escalones
                cambios.append((i, e, a, b))
    print(f'\nEscalones de {nombre} (definiciones de la Seccion I):')
    print('  eje  r0 -> r   t0[s]  dur[s]  Delta[mm]  tr[s]   ts[s]    Mp[%]  e_final[mm]  max|th|[deg]')
    out = []
    for j, (i, e, a, b) in enumerate(cambios):
        kx = 'x' if e == 'X' else 'y'
        kth = 'tel_thx' if e == 'X' else 'tel_thy'
        t0 = r[i]['ts']
        fin = next((c[0] for c in cambios if c[0] > i), len(r))
        # el tramo termina en el siguiente cambio de referencia de cualquier eje o de modo
        for q in range(i + 1, len(r)):
            if r[q]['tel_modo'] != '3' or (int(r[q]['tel_banderas']) >> 4) != 2 or f(r[q]['tel_rx']) != f(r[i]['tel_rx']) or f(r[q]['tel_ry']) != f(r[i]['tel_ry']):
                fin = min(fin, q)
                break
        tramo = r[i:fin]
        prev = [f(x[kx]) for x in r if t0 - 0.3 <= x['ts'] < t0]
        x0 = st.mean(prev)
        d = b - x0
        t = [x['ts'] - t0 for x in tramo]
        xs = [f(x[kx]) for x in tramo]
        def cruza(p):
            for tt, xx in zip(t, xs):
                if (xx - x0) / d >= p:
                    return tt
            return math.nan
        tr = cruza(0.9) - cruza(0.1)
        fuera = [tt for tt, xx in zip(t, xs) if abs(xx - b) > 0.05 * abs(d)]
        ts = fuera[-1] if fuera else 0.0
        no_establece = bool(fuera) and fuera[-1] >= t[-1] - 0.05
        mp = max(0.0, max((xx - b) / d for xx in xs) * 100)
        ult = [xx for tt, xx in zip(t, xs) if tt >= t[-1] - 1.0]
        ef = abs(st.mean(ult) - b)
        thmax = max(abs(f(x[kth])) for x in tramo)
        out.append([e, a, b, round(t0, 2), round(t[-1], 2), round(d, 1), round(tr, 2),
                    ('>' + f'{t[-1]:.1f}') if no_establece else round(ts, 2), round(mp, 1),
                    round(ef, 1), round(thmax, 2)])
        print('  %s %5.0f->%4.0f %6.2f %6.2f %9.1f %6.2f %7s %8.1f %10.1f %10.2f' % (
            e, a, b, t0, t[-1], d, tr, out[-1][7], mp, ef, thmax))
    with open(os.path.join(SAL, f'metricas_escalones_{nombre[7:]}.csv'), 'w', newline='') as fo:
        w = csv.writer(fo)
        w.writerow(['eje', 'r0_mm', 'r_mm', 't0_s', 'duracion_s', 'cambio_mm', 'tr_s', 'ts_s',
                    'Mp_pct', 'error_final_mm', 'max_abs_th_deg'])
        w.writerows(out)


# ---------------------------------------------------------------- circulo
def metricas_circulo(nombre, R):
    r = [x for x in leer_log(nombre) if x['tel_modo'] == '2']
    r = [x for x in r if x['ts'] >= r[0]['ts'] + 3.0]            # sin la rampa de 3 s del radio
    xs = [f(x['x']) for x in r]; ys = [f(x['y']) for x in r]
    cx, cy = st.mean(xs), st.mean(ys)
    rad = sorted(math.hypot(a - cx, b - cy) for a, b in zip(xs, ys))
    err = sorted(math.hypot(f(x['x']) - f(x['tel_rx']), f(x['y']) - f(x['tel_ry'])) for x in r)
    q = lambda v, p: v[int(p * (len(v) - 1))]
    borde = sum(max(abs(a), abs(b)) > 115 for a, b in zip(xs, ys)) / len(xs) * 100
    det = sum(x['detectada'] == '1' for x in r) / len(r) * 100
    print(f'\nCirculo de {nombre} (R = {R} mm, {r[-1]["ts"] - r[0]["ts"]:.0f} s sin la rampa):')
    print(f'  centro de la orbita ({cx:.1f}, {cy:.1f}) mm; radio medio {st.mean(rad):.1f} mm '
          f'(p10 {q(rad, .1):.1f}, p90 {q(rad, .9):.1f}); error a la referencia: mediana '
          f'{q(err, .5):.1f} mm, p90 {q(err, .9):.1f} mm; tiempo a mas de 115 mm: {borde:.1f} %; '
          f'deteccion {det:.1f} %')


if __name__ == '__main__':
    b3_validacion()
    metricas_escalones('sesion_20261113_105834')
    metricas_circulo('sesion_20261113_105517', 45)
