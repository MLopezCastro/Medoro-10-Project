CREATE OR ALTER VIEW dbo.ConCuboSecuenciasBloques AS
WITH VU AS (
    SELECT TRY_CAST(OP AS INT) AS ID_Limpio, MIN(saccod1) AS saccod1
    FROM dbo.TablaVinculadaUNION
    WHERE ISNUMERIC(OP)=1
    GROUP BY TRY_CAST(OP AS INT)
),
Base AS (
    SELECT
        s.Renglon, s.ID, s.ID_Limpio,
        s.Inicio_Corregido, s.Fin_Corregido,
        CAST(ISNULL(s.CantidadBuenosProducida,0) AS DECIMAL(18,4)) AS CantBuenos,
        CAST(ISNULL(s.CantidadMalosProducida ,0) AS DECIMAL(18,4)) AS CantMalos,
        CAST(ISNULL(s.Horas_Produccion       ,0) AS DECIMAL(18,6)) AS HorasProd,
        CAST(ISNULL(s.Horas_Preparacion      ,0) AS DECIMAL(18,6)) AS HorasPrep,
        CAST(ISNULL(s.Horas_Parada           ,0) AS DECIMAL(18,6)) AS HorasPara,
        CAST(ISNULL(s.Horas_Mantenimiento    ,0) AS DECIMAL(18,6)) AS HorasMant,
        s.CodProducto
    FROM dbo.ConCubo3AñosSecFlag s
    WHERE s.Inicio_Corregido IS NOT NULL AND s.Fin_Corregido IS NOT NULL
),
Marcado AS (
    SELECT *,
        CASE WHEN LAG(ID_Limpio) OVER (PARTITION BY Renglon ORDER BY Inicio_Corregido)=ID_Limpio
             THEN 0 ELSE 1 END AS CambioID
    FROM Base
),
Grupos AS (
    SELECT *,
        SUM(CambioID) OVER (PARTITION BY Renglon ORDER BY Inicio_Corregido
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS GrupoOT
    FROM Marcado
),
Dia AS (
    SELECT
        Renglon, ID, ID_Limpio, GrupoOT,
        CONVERT(date, Inicio_Corregido) AS FechaSecuencia,
        MIN(Inicio_Corregido) AS InicioSecuencia,
        MAX(Fin_Corregido)    AS FinSecuencia,
        MAX(CodProducto)      AS CodProducto_Bloque,
        SUM(CantBuenos)       AS BuenosTotal,
        SUM(CantMalos)        AS MalosTotal,
        SUM(HorasProd)        AS HorasProd,
        SUM(HorasPrep)        AS HorasPrep,
        SUM(HorasPara)        AS HorasPara,
        SUM(HorasMant)        AS HorasMant,
        COUNT(*)              AS FilasColapsadas
    FROM Grupos
    GROUP BY Renglon, GrupoOT, ID, ID_Limpio, CONVERT(date, Inicio_Corregido)
)
SELECT
    d.Renglon, d.ID, d.ID_Limpio,
    d.CodProducto_Bloque AS CodProducto,
    d.FechaSecuencia,
    CONVERT(varchar(16), d.InicioSecuencia, 120) AS FechaSecuenciaTextoHora, -- YYYY-MM-DD HH:MM
    d.InicioSecuencia, d.FinSecuencia,
    d.BuenosTotal, d.MalosTotal, d.HorasProd, d.HorasPrep, d.HorasPara, d.HorasMant,
    d.FilasColapsadas,

    -- Números fijos por DÍA (útiles para control)
    ROW_NUMBER() OVER (
        PARTITION BY d.FechaSecuencia
        ORDER BY d.InicioSecuencia, d.Renglon, d.ID_Limpio
    ) AS NumeroBloqueDiaSQL,

    ROW_NUMBER() OVER (
        PARTITION BY d.FechaSecuencia, d.Renglon
        ORDER BY d.InicioSecuencia, d.ID_Limpio
    ) AS NumeroBloqueDiaPorRenglonSQL,

    -- 🔑 SortKey estable para ordenar/rankear desde PBI (crece con hora+renglón+OT)
    CAST(FORMAT(d.InicioSecuencia,'yyyyMMddHHmmss') AS bigint) * 10000000000
      + CAST(d.Renglon AS bigint) * 1000000000
      + CAST(d.ID_Limpio AS bigint)                 AS SortKey,

    VU.saccod1
FROM Dia d
LEFT JOIN VU ON VU.ID_Limpio = d.ID_Limpio;
GO
