import json
import os
from datetime import datetime
import boto3
import pandas as pd
from scraping import scrapeo_opciones_y_futuros

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = 'OpcionesFuturosMiniIBEX'  # Debe coincidir con Terraform

def lambda_handler(event, context):
    df_opciones, df_futuros = scrapeo_opciones_y_futuros()
    tabla = dynamodb.Table(TABLE_NAME)

    hoy = datetime.today().strftime("%Y-%m-%d")

    # --- Guardar opciones ---
    opciones_insertadas = 0
    for _, fila in df_opciones.iterrows():
        # Filtramos solo si faltan campos esenciales
        if pd.isna(fila['strike']) or pd.isna(fila['put/call']) or pd.isna(fila['ant']):
            continue

        tipo_id = f"opcion#{fila['strike']}-{fila['put/call']}-{fila['FV']}"

        item = {
            'fecha': hoy,
            'tipo_id': tipo_id,
            'strike': str(fila['strike']),
            'tipo': fila['put/call'],
            'vencimiento': fila['FV'],
            'precio': str(fila['ant'])
        }

        tabla.put_item(Item=item)
        opciones_insertadas += 1

    # --- Guardar futuros ---
    futuros_insertados = 0
    for _, fila in df_futuros.iterrows():
        if pd.isna(fila['vencimiento']) or pd.isna(fila['ant_futuro']):
            continue

        tipo_id = f"futuro#{fila['vencimiento']}"

        item = {
            'fecha': hoy,
            'tipo_id': tipo_id,
            'vencimiento': fila['vencimiento'],
            'precio_futuro': str(fila['ant_futuro'])
        }

        tabla.put_item(Item=item)
        futuros_insertados += 1

    return {
        'statusCode': 200,
        'body': json.dumps({
            "opciones_guardadas": opciones_insertadas,
            "futuros_guardados": futuros_insertados
        })
    }
