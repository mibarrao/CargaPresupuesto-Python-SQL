
/*
--DROP TABLE [ESTUDIOSCOMERCIALES].dbo.MATRIZ
CREATE TABLE [ESTUDIOSCOMERCIALES].dbo.MATRIZ (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    FECHA DATE,
    INDICADORGRUPO NVARCHAR(255),
    INDICADOR NVARCHAR(255),
    ID_CAJA_ORIGEN INT,
    SEGMENTO NVARCHAR(50),
    SUBSEGMENTO NVARCHAR(255),
    VALOR FLOAT,
    VERSION NVARCHAR(50),
    FECHA_CARGA DATETIME
);

*/


-- 1. CREACIÓN DE TABLA (Mantenemos tu estructura)
IF OBJECT_ID('[ESTUDIOSCOMERCIALES].dbo.MATRIZPASO', 'U') IS NOT NULL 
    DROP TABLE [ESTUDIOSCOMERCIALES].dbo.MATRIZPASO;

CREATE TABLE [ESTUDIOSCOMERCIALES].dbo.MATRIZPASO (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    FECHA DATETIME,
    INDICADORGRUPO NVARCHAR(255),
    INDICADOR NVARCHAR(255),
    ID_CAJA_ORIGEN INT,
    SEGMENTO NVARCHAR(50),
    SUBSEGMENTO NVARCHAR(255),
    VALOR FLOAT,
    VERSION NVARCHAR(50),
    FECHA_CARGA DATETIME
);


-- 2. VARIABLES
DECLARE @TableName NVARCHAR(255), @IndicadorGrupo NVARCHAR(100), @Indicador NVARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX), @SegmentoSql NVARCHAR(MAX), @FiltroSql NVARCHAR(MAX), @FiltroFinal NVARCHAR(MAX)
DECLARE @SubsegmentoActual NVARCHAR(255), @CursorSubStr NVARCHAR(MAX)

-- Limpieza de cursor por si quedó abierto de una ejecución fallida
IF CURSOR_STATUS('global','table_cursor') >= -1 BEGIN
    CLOSE table_cursor DEALLOCATE table_cursor
END

DECLARE table_cursor CURSOR FOR 
    SELECT Nombre_Tabla_SQL, Nombre_Pestania_Excel 
    FROM control_carga_tablas  
    WHERE 
	Nombre_Tabla_SQL  in  ('venta_neta','stock_2026_trabajadores', 'stock_2026_pensionados','stock_2026_lh','gastos_financieros'
	,'ingresos_seguros','n_seguros','n_creditos_pens','n_creditos_trab','n_creditos_lh','comision_vta_serv_terc','ingresos_ffnn','afiliacion_trabajador'
	,'afiliacion_pensionados','ingresos_credito_social','comision_vta_serv_terc_trx','prepago','gasto_provisiones','trx_ips','1per') 
	--and 
	--Nombre_Tabla_SQL in ('ingresos_credito_social') 

	--SELECT * FROM dbo.[1per]

OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @TableName, @IndicadorGrupo

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Inicialización de filtros por tabla
    SET @SegmentoSql = ' '''' AS SEGMENTO, ' 
    SET @FiltroSql = '' 

    /************ CONFIGURACIÓN POR TABLA ***************/
    IF @TableName = 'venta_neta' BEGIN
        SET @SegmentoSql ='CASE   
            WHEN SUBSEGMENTO IN (''FFAA'',''P20'',''P15'',''P5'',''PBS'') THEN ''P''
            WHEN SUBSEGMENTO IN (''Gobierno Central'',''Grandes Empresas'',''PYME'',''PYME Empresas y Trabajadores'',''PYME Red Comercial'') THEN ''T''
            END AS SEGMENTO, '
        SET @FiltroSql = ' WHERE ID NOT IN (6,7,12) '
    END
    ELSE IF @TableName IN ('stock_2026_trabajadores', 'stock_2026_pensionados') BEGIN
			IF  @TableName = 'stock_2026_trabajadores' BEGIN
				SET @SegmentoSql = '''T'' AS SEGMENTO,'
			END

			ELSE IF  @TableName = 'stock_2026_pensionados' BEGIN
			SET @SegmentoSql = '''P'' AS SEGMENTO,'
			END

        SET @FiltroSql = ' WHERE ID NOT IN (1,3,6,14) ' 
    END 
    ELSE IF @TableName = 'stock_2026_lh' BEGIN
        SET @FiltroSql = ' WHERE ID NOT IN (2,5,13) ' 
    END
    ELSE IF @TableName = 'ingresos_credito_social' BEGIN
		SET @SegmentoSql = 'CASE	WHEN UPPER(SUBSEGMENTO) LIKE ''%TRABAJADO%'' THEN ''T'' 
									WHEN UPPER(SUBSEGMENTO) LIKE ''%PENSIONADO%'' THEN ''P'' 		
							ELSE '' ''
							END AS SEGMENTO,'
		
		SET @FiltroSql = ' WHERE ID NOT IN (2,5,10) ' 


    END
    ELSE IF @TableName = 'gastos_financieros' BEGIN
        SET @FiltroSql = ' WHERE ID NOT IN (1,2,9,10,18) ' 
    END
    ELSE IF @TableName = 'ingresos_seguros' BEGIN
        SET @FiltroSql = ' WHERE ID NOT IN (5) ' 
    END
	ELSE IF @TableName = 'n_creditos_pens' BEGIN
         SET @SegmentoSql = '''P'' AS SEGMENTO,'
    END
		ELSE IF @TableName = 'n_creditos_trab' BEGIN
         SET @SegmentoSql = '''T'' AS SEGMENTO,'
    END
	    ELSE IF @TableName = 'comision_vta_serv_terc' BEGIN
        SET @FiltroSql = ' WHERE ID NOT IN (7) ' 
    END 	
		ELSE IF @TableName = 'ingresos_ffnn' BEGIN
        SET @FiltroSql = ' WHERE ID NOT IN (6) ' 
    END 	
		ELSE IF @TableName = 'afiliacion_trabajador' BEGIN
		SET @SegmentoSql = '''T'' AS SEGMENTO,'
		SET @FiltroSql = ' WHERE ID NOT IN (5,6,11,12,17) ' 
    END 	
		ELSE IF @TableName = 'afiliacion_pensionados' BEGIN
		SET @SegmentoSql = '''P'' AS SEGMENTO,'
		SET @FiltroSql = ' WHERE ID NOT IN (6,7,13,14,20)' 
    END 	
		ELSE IF @TableName = 'comision_vta_serv_terc_trx' BEGIN
		SET @FiltroSql = ' WHERE ID NOT IN (4,5,7)' 
    END 	
		ELSE IF @TableName = 'prepago' BEGIN
		SET @SegmentoSql = 'CASE	WHEN UPPER(SUBSEGMENTO) LIKE ''%TRABAJADO%'' THEN ''T'' 
									WHEN UPPER(SUBSEGMENTO) LIKE ''%PENSIONADO%'' THEN ''P'' 		
							ELSE '' ''
							END AS SEGMENTO,'
		SET @FiltroSql = ' WHERE ID NOT IN (3,5,8,10,11,24,27,28,29,30,31,32,33)' 
    END 
		ELSE IF @TableName = 'gasto_provisiones' BEGIN
		SET @SegmentoSql = 'CASE	WHEN ID IN (9,10,11,12,13,14,15) THEN ''T'' 
									WHEN ID IN (17,18,19,20,21,22,23) THEN ''P'' 		
							ELSE '' ''
							END AS SEGMENTO,'
		SET @FiltroSql = ' WHERE ID NOT IN (8,16)' 
    END 
		ELSE IF @TableName = 'trx_ips' BEGIN
		SET @FiltroSql = ' WHERE ID NOT IN (4,7,8,12,18)' 
    END 
	ELSE IF @TableName = '1per' BEGIN
		SET @FiltroSql = ' WHERE ID NOT IN (2,5,19)' 
    END 

--	SELECT * FROM dbo.[1per] WHERE ID NOT IN (2,5,19)
			
		

    ELSE BEGIN
        SET @SegmentoSql = ' '' '' AS SEGMENTO, '
        SET @FiltroSql = '' 
    END

	--select *
	--from n_creditos_pens

    -- Cursor de subsegmentos
    SET @CursorSubStr = 'DECLARE sub_cursor CURSOR FOR SELECT DISTINCT SUBSEGMENTO FROM [ESTUDIOSCOMERCIALES].dbo.' + QUOTENAME(@TableName) + ISNULL(@FiltroSql, '')
    EXEC sp_executesql @CursorSubStr

    OPEN sub_cursor
    FETCH NEXT FROM sub_cursor INTO @SubsegmentoActual

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- LÓGICA INTELIGENTE DE FILTRO (EVITA ERROR DE 'AND' HUÉRFANO)
        -- Si ya hay un WHERE, usa AND. Si no, usa WHERE.
        DECLARE @Conector NVARCHAR(10) = CASE WHEN @FiltroSql LIKE '%WHERE%' THEN ' AND ' ELSE ' WHERE ' END
        SET @FiltroFinal = ISNULL(@FiltroSql, '') + @Conector + ' SUBSEGMENTO = ''' + @SubsegmentoActual + ''' '

        /************ INDICADORES ***************/
        IF @TableName IN ('stock_2026_trabajadores', 'stock_2026_pensionados') BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (4,5) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 3) + '' - '' + SUBSEGMENTO
                WHEN ID IN (7,8,9,10,11,12) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 6) + '' - '' + SUBSEGMENTO
                WHEN ID IN (15,16,17,18,19,20,21) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 14) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
        ELSE IF @TableName = 'gastos_financieros' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (3,4,5,6,7,8) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 2) + '' - '' + SUBSEGMENTO
                WHEN ID IN (11,12,13,14,15,16) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 10) + '' - '' + SUBSEGMENTO
                WHEN ID IN (19,20,21,22,23,24) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 18) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
        ELSE IF @TableName = 'stock_2026_lh' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (3,4) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 2) + '' - '' + SUBSEGMENTO
                WHEN ID IN (6,7,8,9,10,11) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' + SUBSEGMENTO
                WHEN ID IN (14,15,16,17,18,19,20) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 12) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'afiliacion_trabajador' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (1,2,3,4) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' + SUBSEGMENTO
                WHEN ID IN (7,8,9,10) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 11) + '' - '' + SUBSEGMENTO
                WHEN ID IN (13,14,15,16) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 17) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'afiliacion_pensionados' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (1,2,3,4,5) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 6) + '' - '' + SUBSEGMENTO
                WHEN ID IN (8,9,10,11,12) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 13) + '' - '' + SUBSEGMENTO
                WHEN ID IN (15,16,17,18,19) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 20) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'ingresos_credito_social' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (3,4) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 2) + '' - '' + SUBSEGMENTO
                WHEN ID IN (6,7) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' + SUBSEGMENTO
                WHEN ID IN (11,12) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 10) + '' - '' + SUBSEGMENTO
				WHEN ID IN (14,15) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 13) + '' - '' + SUBSEGMENTO
				WHEN ID IN (17,18) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 16) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'comision_vta_serv_terc_trx' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (1,2,3) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 4) + '' - '' + SUBSEGMENTO
                WHEN ID IN (8,9) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID =7) + '' - '' + SUBSEGMENTO
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'prepago' BEGIN
            SET @Indicador = '(CASE 
                WHEN ID IN (1,2) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' +  (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 3) + '' - '' + SUBSEGMENTO
				WHEN ID IN (4) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (6,7) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 10) + '' - '' +  (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 8) + '' - '' + SUBSEGMENTO
				WHEN ID IN (9) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 10) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (12,13,14,15,16,17,18,19,20,21,22,23) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 24) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (25,26) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 27) + '' - '' + SUBSEGMENTO		
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'gasto_provisiones' BEGIN
            SET @Indicador = '(CASE 
				WHEN ID IN (1,2,3,4,5,6,7) THEN  '' Total Los Héroes (incluye Hipo y Más Salud) - '' + SUBSEGMENTO	
				WHEN ID IN (9,10,11,12,13,14,15) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 8) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (17,18,19,20,21,22,23) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 16) + '' - '' + SUBSEGMENTO		
                ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = 'trx_ips' BEGIN
            SET @Indicador = '(CASE 
				WHEN ID IN (1,2,3) THEN '' Ingresos IPS Millones $ - '' +  (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 4) + '' - '' + SUBSEGMENTO
				WHEN ID IN (5,6) THEN  '' Ingresos IPS Millones $ - '' + SUBSEGMENTO	
				WHEN ID IN (9,10,11) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 8) + '' - '' +  (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 12) + '' - '' + SUBSEGMENTO				
				WHEN ID IN (13,14,15,16,17) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 8) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (19,20,21,22) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 18) + '' - '' + SUBSEGMENTO	
				ELSE SUBSEGMENTO END)'
        END
		ELSE IF @TableName = '1per' BEGIN
            SET @Indicador = '(CASE 
				
				WHEN ID IN (3,4) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 1) + '' - '' +  (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 2) + '' - '' + SUBSEGMENTO				
				WHEN ID IN (6,7,8,9,10,11,12) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 5) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (14,15,16,17,18) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 13) + '' - '' + SUBSEGMENTO	
				WHEN ID IN (20,21,22,23,24,25,26) THEN (SELECT SUBSEGMENTO FROM ' + QUOTENAME(@TableName) + ' WHERE ID = 19) + '' - '' + SUBSEGMENTO	
				ELSE SUBSEGMENTO END)'
        END

        ELSE IF @TableName IN ('ingresos_seguros', 'n_seguros') BEGIN
            SET @Indicador = ' SUBSEGMENTO '
        END
        ELSE BEGIN
            SET @Indicador = '''' + REPLACE(@IndicadorGrupo, '''', '''''') + ''''
        END

        -- CONSTRUCCIÓN DEL SQL FINAL
        SET @Sql = '
        INSERT INTO [ESTUDIOSCOMERCIALES].dbo.MATRIZPASO
            (FECHA, INDICADORGRUPO, INDICADOR, ID_CAJA_ORIGEN, SEGMENTO, SUBSEGMENTO, VALOR, VERSION, FECHA_CARGA)
        SELECT CAST(CAST(YEAR(FECHA) AS VARCHAR(4)) + ''-'' + 
                 CASE periodo 
                    WHEN ''ENERO'' THEN ''01'' WHEN ''FEBRERO'' THEN ''02'' WHEN ''MARZO'' THEN ''03''
                    WHEN ''ABRIL'' THEN ''04'' WHEN ''MAYO'' THEN ''05'' WHEN ''JUNIO'' THEN ''06''
                    WHEN ''JULIO'' THEN ''07'' WHEN ''AGOSTO'' THEN ''08'' WHEN ''SEPTIEMBRE'' THEN ''09''
                    WHEN ''OCTUBRE'' THEN ''10'' WHEN ''NOVIEMBRE'' THEN ''11'' WHEN ''DICIEMBRE'' THEN ''12''
                 END + ''-01'' AS DATETIME) AS FECHA,
            ''' + REPLACE(@IndicadorGrupo, '''', '''''') + ''' AS INDICADORGRUPO,
            ' + @Indicador + ' AS INDICADOR, 
            ID AS ID_CAJA_ORIGEN, 
            '+ @SegmentoSql +' SUBSEGMENTO,
            monto AS VALOR,
            ''1'' AS VERSION,
            GETDATE() AS FECHA_CARGA
        FROM (
            SELECT ID, SUBSEGMENTO, ENERO, FEBRERO, MARZO, ABRIL, MAYO, JUNIO, 
                   JULIO, AGOSTO, SEPTIEMBRE, OCTUBRE, NOVIEMBRE, DICIEMBRE, FECHA
            FROM [ESTUDIOSCOMERCIALES].dbo.' + QUOTENAME(@TableName) + ' ' + @FiltroFinal + '
        ) AS TablaOrigen    
        UNPIVOT (
            monto FOR periodo IN (ENERO, FEBRERO, MARZO, ABRIL, MAYO, JUNIO, 
                                  JULIO, AGOSTO, SEPTIEMBRE, OCTUBRE, NOVIEMBRE, DICIEMBRE)
        ) AS unpivottable'

        EXEC sp_executesql @Sql
		--SELECT @Sql
        FETCH NEXT FROM sub_cursor INTO @SubsegmentoActual
    END

    CLOSE sub_cursor
    DEALLOCATE sub_cursor

    FETCH NEXT FROM table_cursor INTO @TableName, @IndicadorGrupo
END

CLOSE table_cursor
DEALLOCATE table_cursor

--GO

delete [ESTUDIOSCOMERCIALES].[dbo].[MATRIZ] 
--SELECT * FROM [ESTUDIOSCOMERCIALES].[dbo].[MATRIZ] 
where fecha in (select distinct cast ((concat(year(FECHA),'-',month(FECHA),'-01'))as date) from [ESTUDIOSCOMERCIALES].[dbo].[MATRIZPASO])
--AND INDICADORGRUPO IN (select distinct INDICADORGRUPO from [ESTUDIOSCOMERCIALES].[dbo].[MATRIZPASO])




--SELECT INDICADOR, COUNT(*) from [ESTUDIOSCOMERCIALES].dbo.MATRIZ GROUP BY INDICADOR
INSERT INTO [ESTUDIOSCOMERCIALES].[dbo].[MATRIZ]  ([FECHA],[INDICADORGRUPO],[INDICADOR],[ID_CAJA_ORIGEN],[SEGMENTO],[SUBSEGMENTO],[VALOR],[VERSION],[FECHA_CARGA])
--select INDICADORGRUPO,INDICADOR,ID_CAJA_ORIGEN,SEGMENTO,SUBSEGMENTO,replace(FORMAT(FECHA,'MMM-yy','es-es'),'.','') as FECHA ,VALOR 
SELECT CAST([FECHA] AS DATE) AS [FECHA],[INDICADORGRUPO],[INDICADOR],[ID_CAJA_ORIGEN],[SEGMENTO],[SUBSEGMENTO],[VALOR],[VERSION],[FECHA_CARGA]
from [ESTUDIOSCOMERCIALES].[dbo].[MATRIZPASO] 
order by indicadorgrupo,ID_CAJA_ORIGEN
