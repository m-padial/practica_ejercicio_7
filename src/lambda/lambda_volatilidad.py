import boto3
import mibian
import pandas as pd
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = 'OpcionesFuturosMiniIBEX'

def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    hoy = datetime.today().strftime("%Y-%m-%d")

    # Obtener todos los datos del día
    response = table.scan(
        FilterExpression='fecha = :hoy AND begins_with(tipo_id, :prefix)',
        ExpressionAttributeValues={':hoy': hoy, ':prefix': 'opcion#'}
    )
    opciones = response['Items']

    response = table.scan(
        FilterExpression='fecha = :hoy AND begins_with(tipo_id, :prefix)',
        ExpressionAttributeValues={':hoy': hoy, ':prefix': 'futuro#'}
    )
    futuros = response['Items']

    # Construir DataFrames
    df_opciones = pd.DataFrame(opciones)
    df_futuros = pd.DataFrame(futuros)

    if df_opciones.empty or df_futuros.empty:
        return {"statusCode": 200, "body": "Sin datos para calcular."}

    # Convertir tipos
    df_opciones['strike'] = pd.to_numeric(df_opciones['strike'], errors='coerce')
    df_opciones['ant'] = pd.to_numeric(df_opciones['precio'], errors='coerce')
    df_opciones['FV'] = pd.to_datetime(df_opciones['vencimiento'])

    df_futuros['ant_futuro'] = pd.to_numeric(df_futuros['precio_futuro'], errors='coerce')
    df_futuros['vencimiento'] = pd.to_datetime(df_futuros['vencimiento'])

    # Elegir futuro más cercano
    futuros_validos = df_futuros[df_futuros['vencimiento'].dt.date >= datetime.today().date()]
    if futuros_validos.empty:
        return {"statusCode": 200, "body": "No hay futuros válidos."}

    futuro = futuros_validos.sort_values('vencimiento').iloc[0]
    precio_futuro = futuro['ant_futuro']

    # Calcular volatilidad
    for _, fila in df_opciones.iterrows():
        try:
            dias = (fila['FV'].date() - datetime.today().date()).days
            if dias <= 0 or pd.isna(fila['strike']) or pd.isna(fila['ant']):
                continue

            if fila['tipo'] == "Call":
                result = mibian.BS([precio_futuro, fila['strike'], 0, dias], callPrice=fila['ant'])
            elif fila['tipo'] == "Put":
                result = mibian.BS([precio_futuro, fila['strike'], 0, dias], putPrice=fila['ant'])
            else:
                continue

            vol = result.impliedVolatility
            if vol and 0 < vol < 500:
                # Update en DynamoDB
                table.update_item(
                    Key={'fecha': fila['fecha'], 'tipo_id': fila['tipo_id']},
                    UpdateExpression="SET #s = :val",
                    ExpressionAttributeNames={"#s": "σ"},
                    ExpressionAttributeValues={":val": str(vol)}
                )
        except:
            continue

    return {"statusCode": 200, "body": "Volatilidad calculada correctamente."}
