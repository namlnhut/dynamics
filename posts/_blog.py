"""Shared helpers for posts: light/dark figures and a fixed-step integrator.

Posts import this with a hidden setup cell:

    import sys; sys.path.insert(0, "..")
    from _blog import themed, rk4

Quarto's freeze does not track this file. After changing it, delete the affected
posts' folders under _freeze/ and run `make render`.
"""
from types import SimpleNamespace

import matplotlib.pyplot as plt
import numpy as np

# Colours match the theorem-block tokens in assets/css/styles.css.
THEMES = {
    "light": SimpleNamespace(fg="#212529", muted="#6c757d", accent="#2c5f9e", accent2="#b5542c"),
    "dark": SimpleNamespace(fg="#dee2e6", muted="#adb5bd", accent="#8ab8f0", accent2="#f0a07a"),
}


def themed(draw, nrows=1, ncols=1, figsize=(7, 3.6), **kwargs):
    """Draw the same figure once per theme, light first.

    Use in a cell with `#| renderings: [light, dark]`. `draw(fig, ax, c)` gets the axes
    (an array when there are several) and the theme colours `c` (fg, muted, accent, accent2).
    """
    for c in THEMES.values():
        rc = {
            "text.color": c.fg, "axes.labelcolor": c.fg, "axes.edgecolor": c.muted,
            "xtick.color": c.muted, "ytick.color": c.muted,
            "figure.facecolor": "none", "axes.facecolor": "none", "savefig.facecolor": "none",
            "axes.spines.top": False, "axes.spines.right": False, "legend.frameon": False,
        }
        with plt.rc_context(rc):
            fig, ax = plt.subplots(nrows, ncols, figsize=figsize, layout="constrained", **kwargs)
            draw(fig, ax, c)
            plt.show()


def rk4(f, x0, t_end, h=0.01):
    """Integrate x' = f(x) with classical RK4. Returns times and states (steps x dim)."""
    n = int(round(t_end / h))
    x = np.asarray(x0, dtype=float)
    xs = np.empty((n + 1, x.size))
    xs[0] = x
    for i in range(n):
        k1 = f(x)
        k2 = f(x + h / 2 * k1)
        k3 = f(x + h / 2 * k2)
        k4 = f(x + h * k3)
        x = x + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        xs[i + 1] = x
    return np.linspace(0, n * h, n + 1), xs
