# Portafolio de sistemas de bases de datos avanzadas

Repositorio con soluciones de ingeniería enfocadas en la administración de SGBD, modelado avanzado, arquitecturas distribuidas federadas, persistencia ORM y procesamiento masivo en ecosistemas NoSQL/Big Data.

---

## Módulo 1: Infraestructura y modelado relacional avanzado

Administración avanzada, refuerzo de seguridad, extensión del modelo relacional e integración de sistemas gestores de bases de datos independientes y heterogéneos.

| Laboratorio | Carpeta | Descripción Técnica y Hallazgos | Stack |
| :--- | :--- | :--- | :--- |
| **Lab 01** | [`lab-01-sgbd-seguridad`](./lab-01-sgbd-seguridad) | Despliegue de entornos aislados y refuerzo de seguridad de motores relacionales.<br>🔹 **Objetivo:** Implementar control de accesos estricto (RBAC) mediante gestión avanzada de roles y diseñar políticas automatizadas de copias de seguridad (*backups*). | Docker, PostgreSQL, Oracle XE, SSH |
| **Lab 02** | [`lab-02-orientacion-objetos`](./lab-02-orientacion-objetos) | Integración de lógica de negocio compleja directamente en el motor de la base de datos mediante extensiones orientadas a objetos.<br>🔹 **Control:** Creación de tipos de datos de usuario (UDTs), herencia y programación de *Triggers* avanzados para la validación de restricciones de integridad relacional. | Oracle SQL, PL/SQL, UDTs |
| **Lab 03** | [`lab-03-bd-federadas`](./lab-03-bd-federadas) | Diseño de una arquitectura de datos distribuida mediante la interconexión de sistemas heterogéneos independientes.<br>🔹 **Hallazgo:** Auditoría del sistema origen para la detección y resolución de fallos críticos de integridad referencial, normalización y entidades aisladas. | Oracle Server, PostgreSQL, DB Links |

---

## Módulo 2: Persistencia de aplicaciones y ecosistemas Big Data

Implementación de capas de abstracción de datos para el desarrollo de software y modelado distribuido NoSQL orientado al procesamiento masivo de grandes volúmenes de información.

| Laboratorio | Carpeta | Descripción Técnica y Resultados | Stack |
| :--- | :--- | :--- | :--- |
| **Lab 04** | [`lab-04-persistencia-jpa`](./lab-04-jpa-persistence) | Mapeo objeto-relacional (ORM) de arquitecturas complejas de software mediante ingeniería directa e inversa.<br>🔹 **Comparativa:** Análisis de rendimiento y traza de ejecución de consultas abstractas (JPQL) frente a la eficiencia de consultas optimizadas en SQL Nativo. | Java, Maven, Hibernate / JPA |
| **Lab 05** | [`lab-05-nosql-cassandra-spark`](./lab-05-nosql-cassandra-spark) | Arquitectura de almacenamiento no relacional distribuido y explotación masiva de datos en paralelo.<br>🔹 **Optimización:** Modelado NoSQL orientado a consultas mediante el diseño de claves de partición y ordenación (*Clustering Keys*), procesadas con Spark. | Apache Cassandra, Apache Spark, CQL, Docker |

---

## Tecnologías Principales
* **Lenguajes:** SQL, PL/SQL, CQL (Cassandra Query Language), Java.
* **Motores / Frameworks:** PostgreSQL, Oracle XE, Apache Cassandra, Apache Spark, Hibernate (Jakarta Persistence).
* **Conceptos:** Modelado NoSQL, arquitecturas federadas, mapeo objeto-relacional (ORM), refuerzo de seguridad, contenedores (Docker).
