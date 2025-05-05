# graficos.py

import matplotlib.pyplot as plt
import pandas as pd
import ipywidgets as widgets
from IPython.display import display, clear_output

def plot_skew(df_resultado, vencimiento_seleccionado):
    df_vto = df_resultado[df_resultado['FV'] == vencimiento_seleccionado]

    df_calls = df_vto[df_vto['put/call'] == 'Call'].dropna(subset=['σ'])
    df_puts = df_vto[df_vto['put/call'] == 'Put'].dropna(subset=['σ'])

    fig, ax = plt.subplots(figsize=(10, 6))
    if not df_calls.empty:
        ax.plot(df_calls['strike'], df_calls['σ'], label='Call', marker='o')
    if not df_puts.empty:
        ax.plot(df_puts['strike'], df_puts['σ'], label='Put', marker='o')

    ax.set_title(f"Skew de volatilidad - Vencimiento {vencimiento_seleccionado}")
    ax.set_xlabel('Strike')
    ax.set_ylabel('Volatilidad Implícita (%)')
    ax.grid(True)
    ax.legend()
    plt.show()

def lanzar_grafico_interactivo(df_resultado):
    vencimientos = sorted(df_resultado['FV'].dropna().unique())

    dropdown = widgets.Dropdown(
        options=vencimientos,
        description='Selecciona vencimiento:',
        style={'description_width': 'initial'},
        layout=widgets.Layout(width='50%')
    )

    output = widgets.Output()

    def on_change(change):
        if change['type'] == 'change' and change['name'] == 'value':
            with output:
                clear_output(wait=True)
                plot_skew(df_resultado, change['new'])

    dropdown.observe(on_change)

    display(dropdown, output)
