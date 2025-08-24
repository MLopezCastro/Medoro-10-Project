CREATE OR ALTER VIEW dbo.ConCuboSecuenciasBloques_Rango AS
SELECT
    d.*,

    -- 🔑 clave de orden estable (texto: fecha-hora + renglón + OT)
    FORMAT(d.InicioSecuencia,'yyyyMMddHHmmss')
    + RIGHT('0000' + CAST(d.Renglon AS varchar(4)), 4)
    + RIGHT('0000000000' + CAST(d.ID_Limpio AS varchar(10)), 10) AS OrdenGlobalText,

    -- 🔢 índice GLOBAL 1..N (NO se reinicia por día ni por filtro)
    ROW_NUMBER() OVER (
        ORDER BY d.InicioSecuencia, d.Renglon, d.ID_Limpio
    ) AS SecuenciaGlobalSQL
FROM dbo.ConCuboSecuenciasBloques AS d;
GO
