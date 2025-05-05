import mibian
import pandas as pd
from datetime import datetime

def calcular_volatilidad(df_opciones, df_futuros):
    df = df_opciones.copy()

    # Identificar el futuro más cercano
    hoy = datetime.today().date()

    def parsear_fecha(f):
        try:
            return pd.to_datetime(f, dayfirst=True, format='%d %b. %Y').date()
        except:
            try:
                return pd.to_datetime(f, dayfirst=True, format='%d %B %Y').date()
            except:
                return None

    df_futuros['fecha_vto'] = df_futuros['vencimiento'].apply(parsear_fecha)
    df_futuros = df_futuros.dropna(subset=['fecha_vto'])
    futuros_validos = df_futuros[df_futuros['fecha_vto'] >= hoy]

    if futuros_validos.empty:
        return df  # No futuro válido encontrado

    futuro_cercano = futuros_validos.sort_values('fecha_vto').iloc[0]
    precio_futuro = futuro_cercano['ant_futuro']

    if precio_futuro is None:
        return df  # No precio del futuro

    # Calcular volatilidad
    for idx, fila in df.iterrows():
        try:
            strike = fila['strike']
            ant_opcion = fila['ant']
            vencimiento_opcion = pd.to_datetime(fila['FV']).date()

            if pd.isna(strike) or pd.isna(ant_opcion):
                continue

            dias_restantes = (vencimiento_opcion - hoy).days
            if dias_restantes <= 0:
                continue

            if fila['put/call'] == "Call":
                resultado = mibian.BS([precio_futuro, strike, 0, dias_restantes], callPrice=ant_opcion)
            elif fila['put/call'] == "Put":
                resultado = mibian.BS([precio_futuro, strike, 0, dias_restantes], putPrice=ant_opcion)
            else:
                continue

            volatilidad = resultado.impliedVolatility
            if volatilidad is not None and 0 < volatilidad < 500:
                df.at[idx, 'σ'] = volatilidad
            else:
                df.at[idx, 'σ'] = None

        except Exception:
            continue

    return df
