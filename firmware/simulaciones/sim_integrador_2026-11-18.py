# Simulacion de un eje: misma ley del firmware (zona 5 mm, E_ZONA 40, descarga, I_MAX 3, slew 6),
# planta xdd = -c g sin(th_real) - rozamiento de Coulomb (zona muerta en grados), retardo tau.
import math, sys
KP,KD,KI,TS=0.034118997,0.025875847,0.022745998,1/30
TH_LIM,E_CLIP,V_INT,NQ,E_ZONA,I_MAX,TAUD,ZONA,SLEW=10,30,25,4,40,3,1.5,5,6
def sim(nuevo,c,tau,dz,delta,x0,T=60):
    g=9810; dt=1e-3; x=x0; v=0; I=0; nq=0; tho=0; buf=[]; nd=int(round(tau/TS))
    # Kalman simplificado: medicion exacta con 2 cuadros de atraso de datos ya incluidos en tau
    hist=[]; xs=[]
    for k in range(int(T/TS)):
        xh=x; vh=v
        eps=xh
        en=False
        if abs(eps)<=ZONA: eps=0; en=True
        else: eps=eps-ZONA if eps>0 else eps+ZONA
        u=KP*eps+I+KD*vh; th=max(-TH_LIM,min(TH_LIM,u)); sat=th!=u
        cong=sat and (eps>0)-(eps<0)==(u>0)-(u<0)
        nq=nq+1 if abs(vh)<V_INT else 0
        quieta = nq>=NQ
        if abs(eps)>=E_ZONA and (not nuevo or not quieta): I*=1-TS/TAUD
        if not cong and not en and quieta and (nuevo or abs(eps)<E_ZONA):
            I+=KI*TS*max(-E_CLIP,min(E_CLIP,eps)); I=max(-I_MAX,min(I_MAX,I))
        d=max(-SLEW,min(SLEW,th-tho)); tho+=d
        buf.append(tho)
        thr=(buf[-1-nd] if len(buf)>nd else 0)-delta   # inclinacion real (deg); delta = error de nivel
        for _ in range(int(TS/dt)):
            a=-c*g*math.sin(math.radians(thr)); f=c*g*math.sin(math.radians(dz))
            if abs(v)<1e-3 and abs(a)<=f: v=0; continue
            a-= f*(1 if v>0 else -1 if v<0 else (1 if a>0 else -1))
            v+=a*dt; x+=v*dt
            if abs(x)>127: x=127*(1 if x>0 else -1); v=-0.3*v
        xs.append(x)
    return xs
print('c    tau  dz  delta  x0  | viejo: x final, |x| med ult 20 s | nuevo: x final, |x| med, max|x| ult 20 s')
for c in (0.2,0.4,0.57):
  for tau in (0.27,0.4):
    for dz,delta,x0 in ((1,1,110),(1,-1,110),(1.5,1,-80),(1,0,60),(1,1.5,0)):
      a=sim(False,c,tau,dz,delta,x0); b=sim(True,c,tau,dz,delta,x0)
      la=a[-600:]; lb=b[-600:]
      print('%.2f %.2f %.1f %+.1f %4d | %7.1f %6.1f | %7.1f %6.1f %6.1f'%(c,tau,dz,delta,x0,a[-1],sum(map(abs,la))/600,b[-1],sum(map(abs,lb))/600,max(map(abs,lb))))
