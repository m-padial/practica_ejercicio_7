from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import boto3
import pandas as pd
import os
from dateutil import parser
from fastapi.responses import JSONResponse

app = FastAPI()

# (opcional) permitir llamadas desde el frontend en otro dominio
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # puedes restringir a tu dominio App Runner
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
tabla = dynamodb.Table("OpcionesFuturosMiniIBEX")


@app.get("/datos")
def get_datos(vencimiento: str):
    response = tabla.scan()
    items = response.get("Items", [])

    while "LastEvaluatedKey" in response:
        response = tabla.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
        items.extend(response.get("Items", []))

    df = pd.DataFrame(items)

    # Normalizar campos
    df["strike"] = pd.to_numeric(df["strike"], errors="coerce")
    df["precio"] = pd.to_numeric(df["precio"], errors="coerce")
    df["σ"] = pd.to_numeric(df["σ"], errors="coerce")

    def normalizar_fecha(f):
        try:
            return parser.parse(f).date().isoformat()
        except:
            return None

    df["vencimiento"] = df["vencimiento"].apply(normalizar_fecha)
    df = df[df["vencimiento"] == vencimiento]
    df = df[df["tipo"].isin(["Call", "Put"])]

    return JSONResponse(content=df.to_dict(orient="records"))


# --- Endpoint de prueba para ver los datos de DynamoDB
@app.get("/datos-todos")
def get_todos_los_datos():
    try:
        response = tabla.scan()
        items = response.get("Items", [])

        while "LastEvaluatedKey" in response:
            response = tabla.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
            items.extend(response.get("Items", []))

        return {"status": "ok", "items": items}
    except Exception as e:
        return {"status": "error", "message": str(e)}
