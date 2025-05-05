from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import pandas as pd
from datetime import datetime
import time
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

def scrapeo_opciones_y_futuros():

    os.environ['XDG_CACHE_HOME'] = "/tmp"

    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-software-rasterizer")
    options.add_argument("--single-process")
    options.add_argument("--no-zygote")
    options.add_argument("--window-size=1920,1080")

    driver = webdriver.Chrome(options=options)

    driver = webdriver.Chrome(options=options)
    driver.get("https://www.meff.es/esp/Derivados-Financieros/Ficha/FIEM_MiniIbex_35")

    try:
        driver.find_element(By.ID, "onetrust-accept-btn-handler").click()
    except:
        pass

    time.sleep(2)

    filas_opciones = driver.find_elements(By.XPATH, '//*[@id="tblOpciones"]/tbody/tr[contains(@class, "text-right")]')
    datos_opciones = []

    for fila in filas_opciones:
        tipo = fila.get_attribute("data-tipo")
        if not tipo:
            continue
        vencimiento = f"{tipo[3:7]}-{tipo[7:9]}-{tipo[9:]}"
        tipo_opcion = "Call" if tipo.startswith("OCE") else "Put" if tipo.startswith("OPE") else None
        celdas = fila.find_elements(By.TAG_NAME, "td")
        strike = celdas[0].get_attribute('innerHTML').strip().replace('.', '').replace(',', '.') if celdas else None
        ant = celdas[-1].get_attribute('innerHTML').strip().replace('.', '').replace(',', '.') if celdas else None
        datos_opciones.append([
            datetime.today().date(),
            vencimiento,
            float(strike) if strike and strike != '-' else None,
            tipo_opcion,
            float(ant.replace('&nbsp;', '').strip()) if ant and '-' not in ant else None,
            None
        ])

    df_opciones = pd.DataFrame(datos_opciones, columns=['hoy', 'FV', 'strike', 'put/call', 'ant', 'σ'])

    filas_futuros = driver.find_elements(By.XPATH, '//*[@id="Contenido_Contenido_tblFuturos"]/tbody/tr[@class="text-right"]')
    datos_futuros = []

    for fila in filas_futuros:
        celdas = fila.find_elements(By.TAG_NAME, "td")
        if len(celdas) < 14:
            continue
        fecha_vto = celdas[0].text.strip()
        ult = celdas[13].text.strip().replace('.', '').replace(',', '.')
        ult = None if ult == '-' else float(ult)
        datos_futuros.append([
            datetime.today().date(),
            fecha_vto,
            ult
        ])

    df_futuros = pd.DataFrame(datos_futuros, columns=['hoy', 'vencimiento', 'ant_futuro'])

    driver.quit()

    return df_opciones, df_futuros

