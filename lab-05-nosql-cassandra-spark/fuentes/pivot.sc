import org.apache.spark.sql.functions._
// Se define el valor cassandraProperties: un diccionario
// con los datos para conectarse al keyspace laboratorio
// de la máquina cassandra
val cassandraProperties = Map("spark.cassandra.connection.host" -> "cassandra",
                        "spark.cassandra.connection.port" -> "9042",
                        "keyspace" -> "laboratorio")

// cargar la tabla hospital al valor laboratory_table
val laboratory_table =
    spark.read.format("org.apache.spark.sql.cassandra").
    options(cassandraProperties).
    option("table","hospital").
	load()

// muestra las 20 primeras filas de la tabla 
laboratory_table.show()


val pivotDF = laboratory_table.groupBy("person").pivot("std_observable_cd").sum("obs_value_nm")
pivotDF.show()
pivotDF.count

// --- Pregunta 9 ---
println("Ejecutando consultas de la Pregunta 9...")

val media_prueba_3255_7 = laboratory_table.filter("std_observable_cd = '3255-7'").select( avg("obs_value_nm")).show()

val media_persona_123498 = laboratory_table.filter("person = 123498").select(avg("obs_value_nm")).show()

val pruebas_mayor_100 = laboratory_table.filter("obs_value_nm >= 100").show()

// --- Pregunta 11 ---
println("Ejecutando consulta de la Pregunta 11...")

val media_prueba_1742_6 = laboratory_table.filter("std_observable_cd = '1742-6'").select(avg("obs_value_nm")).show()

// --- Pregunta 12 ---
println("Ejecutando consultas de la Pregunta 12...")

laboratory_table.createOrReplaceTempView("lab")

val consulta1 = spark.sql("SELECT AVG(obs_value_nm) FROM lab WHERE std_observable_cd = '3255-7'").show()

val consulta2 = spark.sql("SELECT AVG(obs_value_nm) FROM lab WHERE person = 123498").show()

val consulta3 = spark.sql("SELECT * FROM lab WHERE obs_value_nm >= 100").show()

val consulta4 = spark.sql("SELECT AVG(obs_value_nm) FROM lab WHERE std_observable_cd = '1742-6'").show()

// --- Pregunta 13 ---
println("Ejecutando consultas de la Pregunta 13...")

val sql_top_personas = spark.sql("SELECT person, COUNT(*) AS total_pruebas FROM lab GROUP BY person ORDER BY total_pruebas DESC LIMIT 10").show()

val sql_media_por_prueba = spark.sql("SELECT std_observable_cd, AVG(obs_value_nm) AS media_prueba FROM lab GROUP BY std_observable_cd HAVING AVG(obs_value_nm) >= 100 ORDER BY media_prueba DESC").show()
