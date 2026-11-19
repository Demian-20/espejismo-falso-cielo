"""Genera por síntesis los efectos y ambientes del prólogo de Espejismo (WAV mono 16 bits, 22050 Hz).

Uso (requiere Python 3 y numpy):
    python herramientas/generar_audio.py assets/audio

Crea assets/audio/sfx/*.wav y assets/audio/ambiente/*.wav. Para cambiar un sonido,
se ajustan sus parámetros aquí y se vuelve a correr. Los ambientes deben tener
"Loop Mode: Forward" en la pestaña Import de Godot.
"""
import numpy as np, wave, os, sys

SR = 22050
OUT = sys.argv[1]
os.makedirs(os.path.join(OUT, 'sfx'), exist_ok=True)
os.makedirs(os.path.join(OUT, 'ambiente'), exist_ok=True)
rng = np.random.default_rng(7)


def t(seg):
    return np.arange(int(SR * seg)) / SR


def env(n, ataque, caida):
    """Envolvente con ataque lineal y caída exponencial (segundos)."""
    x = np.arange(n) / SR
    e = np.exp(-x / caida)
    a = int(SR * ataque)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def lowpass(x, corte):
    a = np.exp(-2 * np.pi * corte / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, corte):
    return x - lowpass(x, corte)


def tono(f, seg, forma='sin'):
    ph = 2 * np.pi * np.cumsum(np.broadcast_to(f, (int(SR * seg),))) / SR
    if forma == 'sin':
        return np.sin(ph)
    if forma == 'square':
        return np.sign(np.sin(ph)) * 0.6
    if forma == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if forma == 'saw':
        return 2 * ((ph / (2 * np.pi)) % 1) - 1


def ruido(seg):
    return rng.uniform(-1, 1, int(SR * seg))


def guardar(nombre, x, pico_db=-3.0, carpeta='sfx'):
    x = x / (np.max(np.abs(x)) + 1e-9) * 10 ** (pico_db / 20)
    d = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, carpeta, nombre + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
    print(f'{carpeta}/{nombre}.wav {len(x) / SR:.2f}s')


def mezclar(*partes):
    n = max(len(p) for p in partes)
    s = np.zeros(n)
    for p in partes:
        s[:len(p)] += p
    return s


def retrasar(x, seg):
    return np.concatenate([np.zeros(int(SR * seg)), x])


# ---------------- efectos ----------------
n = int(SR * 0.09)
paso = lowpass(ruido(0.09), 1800) * env(n, 0.002, 0.018) + 0.5 * tono(110, 0.09) * env(n, 0.001, 0.02)
guardar('paso', highpass(paso, 60), -6)

n = int(SR * 0.035)
guardar('letra', tono(540, 0.035, 'square') * env(n, 0.002, 0.012) * 0.8, -14)

n = int(SR * 0.05)
guardar('seleccionar', tono(700, 0.05, 'tri') * env(n, 0.002, 0.02), -10)

a = tono(660, 0.07, 'tri') * env(int(SR * 0.07), 0.002, 0.03)
b = tono(990, 0.12, 'tri') * env(int(SR * 0.12), 0.002, 0.05)
guardar('confirmar', mezclar(a, retrasar(b, 0.06)), -8)

notas = [523.25, 659.25, 783.99, 1046.5]
partes = []
for i, f in enumerate(notas):
    d = 0.35 if i == 3 else 0.16
    s = (tono(f, d) + 0.3 * tono(2 * f, d) + 0.1 * tono(3 * f, d)) * env(int(SR * d), 0.004, 0.12 if i == 3 else 0.06)
    partes.append(retrasar(s, i * 0.075))
guardar('evidencia', mezclar(*partes), -5)


def clink(seg=0.25):
    m = int(SR * seg)
    return sum(tono(f, seg) * g for f, g in ((2100, 1), (3350, 0.6), (4700, 0.35), (6200, 0.2))) * env(m, 0.001, 0.05)


guardar('monedas', mezclar(clink(), retrasar(clink() * 0.7, 0.09), retrasar(clink() * 0.5, 0.17)), -6)

n = int(SR * 0.3)
golpe = lowpass(ruido(0.3), 900) * env(n, 0.001, 0.05)
caida = tono(np.linspace(260, 70, n), 0.3, 'saw') * env(n, 0.002, 0.08) * 0.6
guardar('dano', lowpass(golpe + caida, 2500), -4)

partes = []
for i, (f, d) in enumerate(((440, 0.35), (349.23, 0.35), (293.66, 0.35), (146.83, 1.3))):
    m = int(SR * d)
    s = (tono(f, d, 'tri') + 0.4 * tono(f * 1.005, d, 'saw')) * env(m, 0.01, d * 0.6)
    partes.append(retrasar(lowpass(s, 1600), i * 0.3))
guardar('game_over', mezclar(*partes), -5)

n = int(SR * 0.6)
disparo = ruido(0.6) * env(n, 0.0005, 0.06)
disparo = lowpass(disparo, 4000) + lowpass(ruido(0.6), 400) * env(n, 0.001, 0.18) * 1.5
boom = tono(np.linspace(90, 40, n), 0.6) * env(n, 0.001, 0.15) * 1.2
guardar('disparo', disparo + boom, -1)

pulso = tono(170, 0.35, 'square') * (0.6 + 0.4 * tono(28, 0.35)) * env(int(SR * 0.35), 0.01, 0.6)
pulso *= np.minimum(1, (np.arange(len(pulso))[::-1]) / (SR * 0.03))
guardar('vibracion', lowpass(mezclar(pulso, retrasar(pulso, 0.5)), 1200), -7)

a = (tono(880, 0.4) + 0.2 * tono(1760, 0.4)) * env(int(SR * 0.4), 0.003, 0.12)
b = (tono(1318.5, 0.6) + 0.2 * tono(2637, 0.6)) * env(int(SR * 0.6), 0.003, 0.2)
guardar('notificacion', mezclar(a, retrasar(b, 0.12)), -8)

d = 3.0
sw = 700 + 180 * np.sin(2 * np.pi * 0.9 * t(d))
sirena = tono(sw, d, 'tri') * np.sin(np.pi * t(d) / d) ** 2
guardar('sirena_lejana', lowpass(sirena, 1400) + 0.02 * lowpass(ruido(d), 300), -16)

# ---------------- ambientes en bucle (10 s) ----------------
L = 10.0


def bucle(x, cruce=1.0):
    """Hace que el final empalme con el inicio sin corte."""
    c = int(SR * cruce)
    total = len(x) - c
    y = x[:total].copy()
    rampa = np.linspace(0, 1, c)
    y[:c] = x[:c] * rampa + x[total:] * (1 - rampa)
    return y


T = t(L + 1)
viento = lowpass(lowpass(ruido(L + 1), 500), 500) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.1 * T) ** 2)
pad = sum(tono(f, L + 1, 'tri') * 0.08 for f in (110, 164.81, 220, 261.63)) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.2 * T))
pajaros = np.zeros_like(T)
for k, inicio in enumerate((1.3, 4.1, 7.6)):
    m = int(SR * 0.12)
    canto = tono(np.linspace(2600, 3400, m), 0.12) * env(m, 0.01, 0.05) * 0.15
    for r in range(3):
        p = int(SR * (inicio + r * 0.16))
        pajaros[p:p + m] += canto
guardar('plaza_tarde', bucle(viento + lowpass(pad, 900) + pajaros), -9, 'ambiente')

grillos = np.zeros_like(T)
for inicio in np.arange(0, L + 1, 0.55):
    m = int(SR * 0.05)
    for r in range(3):
        p = int(SR * (inicio + r * 0.07))
        if p + m < len(grillos):
            grillos[p:p + m] += tono(4400, 0.05) * env(m, 0.003, 0.015) * 0.12
dron = (tono(55, L + 1) + 0.5 * tono(82.41, L + 1)) * 0.25
noche = 0.5 * viento + grillos + lowpass(dron, 300)
noche[int(SR * 5.5):int(SR * 8.5)] += lowpass(sirena, 1400) * 0.05
guardar('plaza_noche', bucle(noche), -10, 'ambiente')

latido = np.zeros_like(T)
for inicio in np.arange(0, L + 1, 0.625):
    for desfase, g in ((0, 1.0), (0.16, 0.7)):
        m = int(SR * 0.15)
        p = int(SR * (inicio + desfase))
        if p + m < len(latido):
            latido[p:p + m] += tono(np.linspace(70, 45, m), 0.15) * env(m, 0.002, 0.05) * g
cuerdas = lowpass(tono(110, L + 1, 'saw') + tono(116.54, L + 1, 'saw'), 700) * 0.12 * (0.6 + 0.4 * np.sin(2 * np.pi * 8 * T))
guardar('tension', bucle(latido + cuerdas + 0.3 * viento), -7, 'ambiente')

motor = lowpass(tono(32 + 1.5 * np.sin(2 * np.pi * 0.4 * T), L + 1, 'saw') + 0.4 * ruido(L + 1), 350) * (0.8 + 0.2 * np.sin(2 * np.pi * 9.6 * T))
guardar('motor_ralenti', bucle(motor), -12, 'ambiente')
