# MEDORO 10 – Secuencias y Bloques por OT

> **Objetivo:** incorporar dos vistas nuevas para consolidar eventos en *bloques de producción/preparación por OT y por día*, generar un índice de secuencia global estable y habilitar ordenamientos/controles robustos desde Power BI.

---

## 🧱 Vistas incluidas

1. **`dbo.ConCuboSecuenciasBloques`**  
   Colapsa filas de `ConCubo3AñosSecFlag` en **bloques por OT** cuando la misma OT continúa sin intercalarse otra distinta, a **nivel de día**.  
   Devuelve totales (buenos/malos/horas), rangos de inicio/fin del bloque, *sort key* estable y *rankings* por día.

2. **`dbo.ConCuboSecuenciasBloques_Rango`**  
   Extiende la anterior agregando `OrdenGlobalText` (clave de ordenamiento textual) y `SecuenciaGlobalSQL` (índice global 1..N que no se reinicia por día ni por filtros).

---

## 📦 Fuente de datos y supuestos clave
- Base: **`ConCubo3AñosSecFlag`** (eventos ya corregidos de fecha y con flags).  
- Se descartan filas sin `Inicio_Corregido` o `Fin_Corregido`.  
- Se suman métricas: `HorasProd`, `HorasPrep`, `HorasPara`, `HorasMant`, `CantBuenos`, `CantMalos`.  
- **Cambio de OT** detectado con `LAG(ID_Limpio)` particionado por `Renglon` y ordenado por `Inicio_Corregido`.  
- **Agrupación diaria:** cada bloque es por **OT + Renglón + Día**.  
- Enriquecimiento con `saccod1` desde `TablaVinculadaUNION` (vía `TRY_CAST(OP AS INT)` e `ISNUMERIC(OP)=1`).  

---

## 🔑 Campos principales (salida)

### `ConCuboSecuenciasBloques`
- `Renglon`, `ID`, `ID_Limpio`, `saccod1`  
- `CodProducto`, `FechaSecuencia`, `InicioSecuencia`, `FinSecuencia`  
- Totales: `BuenosTotal`, `MalosTotal`, `HorasProd`, `HorasPrep`, `HorasPara`, `HorasMant`  
- `FilasColapsadas` (conteo de filas originales dentro del bloque)  
- **Ordenación y control por día:**  
  - `NumeroBloqueDiaSQL`: ordinal global del día (todas las máquinas)  
  - `NumeroBloqueDiaPorRenglonSQL`: ordinal del día por renglón  
- **`SortKey`**: bigint creciente por (hora + renglón + OT)

### `ConCuboSecuenciasBloques_Rango` (además)
- `OrdenGlobalText`: `yyyyMMddHHmmss` + `Renglon(4)` + `ID_Limpio(10)`  
- `SecuenciaGlobalSQL`: `ROW_NUMBER()` global por `(InicioSecuencia, Renglon, ID_Limpio)`  

---

## ❓ ¿Por qué dos vistas y no una?
- **`ConCuboSecuenciasBloques`** es la **vista base** para analítica diaria y KPIs por bloque.  
- **`ConCuboSecuenciasBloques_Rango`** agrega llaves/índices **globales** para controles de rango y ordenamientos en Power BI.  

---

## 📊 Uso en Power BI
- Usar `ConCuboSecuenciasBloques` como **tabla de hechos** (bloques).  
- Ordenar siempre por `SortKey` para mantener narrativa temporal.  
- KPIs recomendados:  
  - `%Preparación = SUM(HorasPrep)/SUM(HorasProd)`  
  - `%Parada = SUM(HorasPara)/SUM(HorasProd)`  
- Para navegación secuencial: usar `ConCuboSecuenciasBloques_Rango` con `SecuenciaGlobalSQL`.  

---

## 📝 Changelog (Medoro 10)
- ✅ Nueva vista `ConCuboSecuenciasBloques` con consolidación diaria por bloques y sort key estable.  
- ✅ Nueva vista `ConCuboSecuenciasBloques_Rango` con índice global y clave textual.  
- ✅ Guía de integración con Power BI y validaciones SQL.  

---

## 👤 Autor
**Marcelo F. López Castro**  
_SQL Server · Power BI · Data Analytics_

