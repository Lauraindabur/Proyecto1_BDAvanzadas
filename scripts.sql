/* =====================================================================
   PROYECTO 1 - BASES DE DATOS
   =====================================================================
   Integrantes:
   - Ana Isabella Gómez García- aigomezg1@eafit.edu.co
   - Dorian Alejandro Guisao Ospina  - daguisaoo@eafit.edu.co
   - Laura Indabur García- lindaburg@eafit.edu.co ⁠
   - David Quintero Gallego- dquinterg1@eafit.edu.co

   Asignatura: Bases de Datos Avanzadas
   ===================================================================== */
   
   
/* =====================================================================
   PUNTO 1
 */
 
-- Primero buscamos un pacienteID con datos
SELECT PacienteID, DATE(FechaHora) AS Fecha, COUNT(*) AS NumCitas
FROM Citas
GROUP BY PacienteID, DATE(FechaHora)
HAVING COUNT(*) >= 1
LIMIT 1;

-- Punto 1
-- consulta antigua
EXPLAIN 
SELECT CitaID, PacienteID, FechaHora, Estado
FROM Citas
WHERE DATE(FechaHora) = '2024-01-01' AND PacienteID = 1
ORDER BY FechaHora DESC
LIMIT 5;

-- eficiente

EXPLAIN 
SELECT CitaID, PacienteID, FechaHora, Estado
FROM Citas
WHERE PacienteID = 1
  AND FechaHora >= '2024-01-01 00:00:00'
  AND FechaHora <  '2024-01-02 00:00:00'
ORDER BY FechaHora DESC
LIMIT 5;


-- Punto 2
-- consulta antigua
EXPLAIN analyze
SELECT m.MedicoID, m.EspecialidadID
FROM Medicos m
WHERE m.EspecialidadID = 1
  AND m.MedicoID NOT IN (
      SELECT c.MedicoID
      FROM Citas c
      WHERE c.FechaHora >= '2026-02-02' - INTERVAL 1 DAY
  );

--  corregida
EXPLAIN ANALYZE
SELECT m.MedicoID, m.EspecialidadID
FROM Medicos m
WHERE m.EspecialidadID = 1
  AND NOT EXISTS (
      SELECT 1
      FROM Citas c
      WHERE c.MedicoID = m.MedicoID
        AND c.FechaHora >= '2026-02-02'
  );
  
-- Punto 3
-- consulta antigua
EXPLAIN ANALYZE
SELECT c.PacienteID, COUNT(*) AS total_canceladas
FROM Citas c
WHERE YEAR(c.FechaHora) = 2024 AND WEEK(c.FechaHora, 1) = 25
  AND c.Estado = 'Cancelada'
GROUP BY c.PacienteID
ORDER BY total_canceladas DESC
LIMIT 100;

-- corregida
SET @inicio_semana = STR_TO_DATE(CONCAT(2024, ' ', 25, ' Monday'), '%X %V %W');
SET @fin_semana     = DATE_ADD(@inicio_semana, INTERVAL 7 DAY);
SELECT @inicio_semana AS Inicio, @fin_semana AS Fin;
EXPLAIN analyze
SELECT c.PacienteID, COUNT(*) AS total_canceladas
FROM Citas c
WHERE c.FechaHora >= @inicio_semana
  AND c.FechaHora <  @fin_semana
  AND c.Estado = 'Cancelada'
GROUP BY c.PacienteID
ORDER BY total_canceladas DESC
LIMIT 100;

-- Punto 4
-- consulta antigua
EXPLAIN analyze
SELECT p.PagoID, p.CitaID, p.MetodoPago, p.FechaPago
FROM Pagos p
WHERE p.CitaID IN (SELECT CitaID FROM Citas WHERE ConsultorioID = 12)
  AND p.MetodoPago = 'Tarjeta'
  AND p.FechaPago >= '2024-01-01' AND p.FechaPago < '2024-02-01';

-- corregida
EXPLAIN analyze
SELECT p.PagoID, p.CitaID, p.MetodoPago, p.FechaPago
FROM Pagos p
JOIN Citas c ON c.CitaID = p.CitaID
WHERE c.ConsultorioID = 12
  AND p.MetodoPago = 'Tarjeta'
  AND p.FechaPago >= '2024-01-01' AND p.FechaPago < '2024-02-01';
 
 -- punto 5
 -- consulta antigua
 EXPLAIN analyze
 SELECT co.ConsultorioID,
       COUNT(c.CitaID) AS total_citas,
       COUNT(p.PagoID) AS total_pagos,
       MAX(DATE(c.FechaHora)) AS ultima_cita_mes
FROM Consultorios co
LEFT JOIN Citas c ON c.ConsultorioID = co.ConsultorioID
LEFT JOIN Pagos p ON p.CitaID = c.CitaID
WHERE DATE(c.FechaHora) BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY co.ConsultorioID;

 -- corregida 
 EXPLAIN analyze
 SELECT co.ConsultorioID,
       COUNT(DISTINCT c.CitaID) AS total_citas,
       COUNT(DISTINCT p.PagoID) AS total_pagos,
       MAX(c.FechaHora) AS ultima_cita_mes
FROM Consultorios co
LEFT JOIN Citas c
       ON c.ConsultorioID = co.ConsultorioID
      AND c.FechaHora >= '2024-06-01'
      AND c.FechaHora <  '2024-07-01'
LEFT JOIN Pagos p ON p.CitaID = c.CitaID
GROUP BY co.ConsultorioID;

/* =====================================================================
   PUNTO 2
*/

-- Consulta
SELECT PacienteID, COUNT(*) AS TotalRechazados
FROM Pagos
WHERE Estado = 'Rechazado'
  AND FechaPago BETWEEN '2024-01-01' AND '2024-06-30'
GROUP BY PacienteID
ORDER BY TotalRechazados DESC
LIMIT 20;

-- Índice propuesto
CREATE INDEX IX_Pagos_Estado_FechaPago_PacienteID
ON Pagos (Estado, FechaPago, PacienteID);


-- Consulta
SELECT p.PacienteID, p.Nombre, p.Apellido
FROM Pacientes p
WHERE EXISTS (
    SELECT 1
    FROM Citas c1
    JOIN Medicos m ON m.MedicoID = c1.MedicoID
    WHERE c1.PacienteID = p.PacienteID
      AND m.EspecialidadID = 3   -- especialidad de ejemplo, se puede cualquiera de las 12 
)
AND NOT EXISTS (
    SELECT 1
    FROM Citas c2
    WHERE c2.PacienteID = p.PacienteID
      AND c2.FechaHora >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
);

-- Índice propuesto
CREATE INDEX IX_Citas_PacienteID_FechaHora
ON Citas (PacienteID, FechaHora);

-- Consulta
SELECT *
FROM Medicos
WHERE EspecialidadID = 3
  AND Activo = 1;

-- Índice propuesto
CREATE INDEX IX_Medicos_EspecialidadID_Activo
ON Medicos (EspecialidadID, Activo);


-- Consulta
SELECT *
FROM Pagos
WHERE MetodoPago = 'Tarjeta'
  AND Estado = 'Pagado'
  AND FechaPago BETWEEN '2024-01-01' AND '2024-01-31 23:59:59';

-- Índice propuesto
CREATE INDEX IX_Pagos_Metodo_Estado_Fecha
ON Pagos (MetodoPago, Estado, FechaPago);

-- Consulta
SELECT ConsultorioID, COUNT(*) AS TotalCitas
FROM Citas
WHERE FechaHora BETWEEN '2024-01-01' AND '2024-01-31 23:59:59'
GROUP BY ConsultorioID;

-- Índice propuesto
CREATE INDEX IX_Citas_FechaHora_ConsultorioID
ON Citas (FechaHora, ConsultorioID);

/* =====================================================================
   PUNTO 3
*/

/* =====================================================================
   PUNTO 4
*/

