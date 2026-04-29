# -*- coding: utf-8 -*-
import pandas as pd
from sqlalchemy import create_engine, text
import urllib
import unicodedata
import re
from datetime import datetime

# --- CONFIGURACION ---
ruta_excel = r'C:\Users\mibarra\Downloads\Ingresos 2026 Ppto.xlsx'
servidor = r'LH-GESTIONDOS2'
base_datos = 'ESTUDIOSCOMERCIALES'


params = urllib.parse.quote_plus(f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={servidor};DATABASE={base_datos};Trusted_Connection=yes')
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

def limpiar_nombre_tabla(nombre):
    nombre = nombre.replace('%', 'per')
    nombre = "".join(c for c in unicodedata.normalize('NFD', nombre) if unicodedata.category(c) != 'Mn')
    nombre = nombre.replace(" ", "_").lower()
    nombre = re.sub(r'[^a-z0-9_]', '', nombre)
    nombre = re.sub(r'_+', '_', nombre).strip('_')
    return nombre

# --- PROCESO DE CARGA ---
print("Iniciando proceso de carga con mapeo de columnas estricto...")
try:
    # Leemos el archivo completo para obtener las pestanias
    excel_file = pd.ExcelFile(ruta_excel)
    registro_comparativo = []

    for nombre_pestania in excel_file.sheet_names:
        # 1. Leer pestania: saltamos encabezados para llegar a los datos (skiprows=2 segun tu captura)
        # header=None para usar indices numericos (0, 1, 2...)
        df_raw = pd.read_excel(ruta_excel, sheet_name=nombre_pestania, skiprows=1, header=None)
        
        #22-04-2026
        df_raw = df_raw.dropna(how='all').reset_index(drop=True)

        # Nombre limpio para SQL
        nombre_tabla = limpiar_nombre_tabla(nombre_pestania)
        print(f"Procesando: '{nombre_pestania}' -> Tabla Destino: '{nombre_tabla}'")

        try:
            # 2. CONSTRUIR EL FORMATO SOLICITADO (Mapeo por posicion)
            df_final = pd.DataFrame()
            
            df_final['SUBSEGMENTO'] = df_raw.iloc[:, 0]
            df_final['ENERO']       = pd.to_numeric(df_raw.iloc[:, 1], errors='coerce')
            df_final['FEBRERO']     = pd.to_numeric(df_raw.iloc[:, 2], errors='coerce')
            df_final['MARZO']       = pd.to_numeric(df_raw.iloc[:, 3], errors='coerce')
            df_final['ABRIL']       = pd.to_numeric(df_raw.iloc[:, 4], errors='coerce')
            df_final['MAYO']        = pd.to_numeric(df_raw.iloc[:, 5], errors='coerce')
            df_final['JUNIO']       = pd.to_numeric(df_raw.iloc[:, 6], errors='coerce')
            df_final['JULIO']       = pd.to_numeric(df_raw.iloc[:, 7], errors='coerce')
            df_final['AGOSTO']      = pd.to_numeric(df_raw.iloc[:, 8], errors='coerce')
            df_final['SEPTIEMBRE']  = pd.to_numeric(df_raw.iloc[:, 9], errors='coerce')
            df_final['OCTUBRE']     = pd.to_numeric(df_raw.iloc[:, 10], errors='coerce')
            df_final['NOVIEMBRE']   = pd.to_numeric(df_raw.iloc[:, 11], errors='coerce')
            df_final['DICIEMBRE']   = pd.to_numeric(df_raw.iloc[:, 12], errors='coerce')
            df_final['FECHA']  = datetime.now() 

            # 3. LIMPIEZA DE DATOS
            # Quitar filas donde el subsegmento sea nulo y rellenar meses vacios con 0
            df_final = df_final.dropna(subset=['SUBSEGMENTO'])
            df_final = df_final.fillna(0)
            # Evitar cargar filas que contengan titulos o totales
            #df_final = df_final[~df_final['SUBSEGMENTO'].astype(str).str.contains("Total|Monto|ene-26", case=False)]

            # 4. CARGA A SQL SERVER
            with engine.begin() as conn:
                #sql_drop = text(f"IF OBJECT_ID('{nombre_tabla}', 'U') IS NOT NULL DROP TABLE [{nombre_tabla}]")
                conn.execute(text(f"IF OBJECT_ID('{nombre_tabla}', 'U') IS NOT NULL DROP TABLE [{nombre_tabla}]"))

            # CREAR TABLA CON ID PRIMERO (Este es el cambio clave)
                sql_create = text(f"""
                    CREATE TABLE [{nombre_tabla}] (
                        ID INT IDENTITY(1,1) PRIMARY KEY,
                        SUBSEGMENTO NVARCHAR(MAX),
                        ENERO FLOAT, FEBRERO FLOAT, MARZO FLOAT, ABRIL FLOAT,
                        MAYO FLOAT, JUNIO FLOAT, JULIO FLOAT, AGOSTO FLOAT,
                        SEPTIEMBRE FLOAT, OCTUBRE FLOAT, NOVIEMBRE FLOAT, DICIEMBRE FLOAT,
                        FECHA DATETIME
                    )
                """)
                conn.execute(sql_create)
                #conn.execute(sql_drop)
                df_final.to_sql(nombre_tabla, con=conn, if_exists='append', index=False)
                #df_final.to_sql(nombre_tabla, con=engine, if_exists='replace', index=False)

            
                registro_comparativo.append({
                    'Nombre_Pestania_Excel': nombre_pestania,
                    'Nombre_Tabla_SQL': nombre_tabla,
                    'Cantidad_Filas': len(df_final),
                    'Estado': 'Exitoso'
                })
            print(f"   [OK] Tabla '{nombre_tabla}' cargada con {len(df_final)} filas.")

        except Exception as e:
            print(f"   [ERROR] En pestania {nombre_pestania}: {e}")
            registro_comparativo.append({
                'Nombre_Pestania_Excel': nombre_pestania,
                'Nombre_Tabla_SQL': nombre_tabla,
                'Cantidad_Filas': 0,
                'Estado': f'Error: {str(e)[:50]}'
            })

    # Generar tabla de control final
    if registro_comparativo:
        df_control = pd.DataFrame(registro_comparativo)
        df_control.to_sql('control_carga_tablas', con=engine, if_exists='replace', index=False)
        print("\n--- RESUMEN FINAL ---")
        print(df_control[['Nombre_Pestania_Excel', 'Nombre_Tabla_SQL', 'Estado']])

except Exception as e:
    print(f"Error critico al procesar el Excel: {e}")

print("\nProceso finalizado.")