# -*- coding: utf-8 -*-
import pandas as pd
from sqlalchemy import create_engine, text
import urllib
import pyodbc
import unicodedata
import re
from datetime import datetime

# --- CONFIGURACION ---
# Asegurate de que la ruta sea accesible desde tu equipo Lenovo
ruta_excel = r'C:\Users\mibarra\Downloads\Ingresos 2026 Ppto.xlsx'
servidor = r'LH-GESTIONDOS2'
base_datos = 'ESTUDIOSCOMERCIALES'

# 1. Cadena de conexion limpia para Pyodbc
conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={servidor};DATABASE={base_datos};Trusted_Connection=yes'

# 2. Cadena codificada para SQLAlchemy
params_quoted = urllib.parse.quote_plus(conn_str)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params_quoted}",pool_pre_ping=True)

# 3. Establecer conexiones
conexion = pyodbc.connect(conn_str) 

# CORRECCION LINEA 30: El atributo es .timeout y se asigna despues de crear el cursor
conexion.timeout = 300 # 10 minutos de espera para procesos pesados
cursor = conexion.cursor()

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
    excel_file = pd.ExcelFile(ruta_excel)
    registro_comparativo = []

    for nombre_pestania in excel_file.sheet_names:
        try:
            # 1. Leer pestana: saltamos encabezados (skiprows=1)
            df_raw = pd.read_excel(ruta_excel, sheet_name=nombre_pestania, skiprows=1, header=None)
            df_raw = df_raw.dropna(how='all').reset_index(drop=True)

            nombre_tabla = limpiar_nombre_tabla(nombre_pestania)
            print(f"Procesando: '{nombre_pestania}' -> Tabla Destino: '{nombre_tabla}'")

            # 2. Mapeo por posicion (0 a 12)
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
            df_final['FECHA']       = datetime.now() 

            # 3. Limpieza
            df_final = df_final.dropna(subset=['SUBSEGMENTO'])
            df_final = df_final.fillna(0)

            # 4. Carga a SQL Server usando SQLAlchemy
            with engine.begin() as conn:
                conn.execute(text(f"IF OBJECT_ID('{nombre_tabla}', 'U') IS NOT NULL DROP TABLE [{nombre_tabla}]"))
                
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
                df_final.to_sql(nombre_tabla, con=conn, if_exists='append', index=False)
            
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

    # Tabla de control
    if registro_comparativo:
        df_control = pd.DataFrame(registro_comparativo)
        df_control.to_sql('control_carga_tablas', con=engine, if_exists='replace', index=False)


    # ==========================================
    # EJECUCION PROCEDIMIENTO DE CARGA
    # ==========================================
    print(f"\n--- INICIANDO CARGA PRESUPUESTO ---")
    
    # Liberamos recursos de engine para evitar bloqueos
    engine.dispose()

    with pyodbc.connect(conn_str) as conn_nueva:
        conn_nueva.timeout = 300
        nuevo_cursor = conn_nueva.cursor()
        
        print("Ejecutando Stored Procedure...")
        # Usar SET NOCOUNT ON ayuda a evitar que pyodbc se confunda con mensajes intermedios
        nuevo_cursor.execute("SET NOCOUNT ON; EXEC [dbo].[usp_CargaPresupuestoMensual]")
        
        # El COMMIT es vital aqui para persistir los resultados del SP
        conn_nueva.commit()

    print("  --> Proceso del SP ejecutado con exito.\n")

except Exception as e:
    print(f"Error critico al procesar: {e}")

finally:
    if 'conexion' in locals():
        conexion.close()
    print("\nProceso finalizado.")
