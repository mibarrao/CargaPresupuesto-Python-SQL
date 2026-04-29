# 📊 ETL Ingesta y Consolidación de Presupuesto / Budget Ingestion & Consolidation ETL

🇪🇸 **[ESPAÑOL]**

Este proyecto es un pipeline **ETL (Extracción, Transformación y Carga)** automatizado diseñado para centralizar presupuestos financieros distribuidos en múltiples archivos y pestañas de Excel. El sistema normaliza datos heterogéneos y los consolida en una matriz relacional para análisis avanzado en SQL Server.

### 🚀 Arquitectura y Flujo de Datos
1. **Extracción (Python/Pandas):** Lectura dinámica de un libro de Excel con 19+ pestañas, manejando estructuras variables y nombres de hojas con caracteres especiales (ej. `%`).
2. **Transformación:** Mapeo seguro de columnas por posición para evitar errores de índices, limpieza de filas de totales/encabezados y estandarización de tipos de datos numéricos.
3. **Carga (SQL Server):** Creación dinámica de tablas intermedias con llaves primarias autoincrementales (`ID IDENTITY`) mediante `SQLAlchemy` para asegurar la integridad y el orden de los registros.
4. **Consolidación (T-SQL):** Ejecución de un motor de reglas basado en **Cursores Dinámicos** y **Unpivot**. El proceso transforma meses de columnas a filas, calcula indicadores compuestos (Padre-Hijo) y segmenta automáticamente entre Pensionados (P) y Trabajadores (T).

### 🛠️ Tecnologías Utilizadas

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Pandas](https://img.shields.io/badge/pandas-%23150458.svg?style=for-the-badge&logo=pandas&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=power-bi&logoColor=black)

* **Lenguaje:** Python 3.x
* **Librerías:** `pandas`, `sqlalchemy`, `pyodbc`
* **Base de Datos:** SQL Server (Azure / On-premise)
* **Conceptos:** SQL Dinámico, Unpivot, Cursores, ETL de archivos planos.

---

🇬🇧 **[ENGLISH]**

This project is an automated **ETL (Extract, Transform, Load)** pipeline designed to centralize financial budgets distributed across multiple Excel files and tabs. The system normalizes heterogeneous data and consolidates it into a relational matrix for advanced analysis in SQL Server.

### 🚀 Architecture & Data Flow
1. **Extraction (Python/Pandas):** Dynamic reading of an Excel workbook with 19+ tabs, handling variable structures and sheet names with special characters (e.g., `%`).
2. **Transformation:** Secure column mapping by position to prevent index errors, removal of total/header rows, and standardization of numeric data types.
3. **Loading (SQL Server):** Dynamic creation of intermediate tables with auto-incremental primary keys (`ID IDENTITY`) using `SQLAlchemy` to ensure data integrity and record lineage.
4. **Consolidation (T-SQL):** Execution of a rules engine based on **Dynamic Cursors** and **Unpivot**. The process transforms months from columns to rows, calculates composite indicators (Parent-Child), and automatically segments between Pensioners (P) and Workers (T).

### 🛠️ Tech Stack & Tools

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Pandas](https://img.shields.io/badge/pandas-%23150458.svg?style=for-the-badge&logo=pandas&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=power-bi&logoColor=black)

* **Language:** Python 3.x
* **Libraries:** `pandas`, `sqlalchemy`, `pyodbc`
* **Database:** SQL Server (Azure / On-premise)
* **Concepts:** Dynamic SQL, Unpivot, Cursors, Flat-file ETL.

---

### 📂 Archivos del Proyecto / Project Files
* `etl_presupuesto_carga.py`: Script de Python para ingesta y limpieza / *Python script for ingestion and cleansing*.
* `sp_ConsolidacionMatriz.sql`: Procedimiento de consolidación y unpivot / *Consolidation and unpivot stored procedure*.
