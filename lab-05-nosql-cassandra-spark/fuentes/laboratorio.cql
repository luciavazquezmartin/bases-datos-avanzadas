CREATE KEYSPACE IF NOT EXISTS laboratorio WITH REPLICATION =
{ 'class': 'SimpleStrategy',
'replication_factor': '1'
};

CREATE TABLE laboratorio.hospital (
    std_observable_cd text,
    person int,
    std_observable_st text,
    obs_value_nm float,
    PRIMARY KEY ((std_observable_cd), person)
) WITH CLUSTERING ORDER BY (person ASC);


// carga de datos con COPY
COPY laboratorio.hospital (person, std_observable_cd, std_observable_st, obs_value_nm)
FROM '/data/dataset.csv' 
WITH HEADER = TRUE AND DELIMITER = ';';

// --- Pregunta 4 ---

println("Ejecutando consulta de la Pregunta 4...")

SELECT DISTINCT std_observable_cd FROM laboratorio.hospital;

// -- Pregunta 7 ---

println("Ejecutando consultas de la Pregunta 7...")

SELECT AVG(obs_value_nm) FROM laboratorio.hospital WHERE std_observable_cd = '3255-7';

SELECT AVG(obs_value_nm) FROM laboratorio.hospital WHERE person = 123498 ALLOW FILTERING;

SELECT * FROM laboratorio.hospital WHERE obs_value_nm >= 100 ALLOW FILTERING;