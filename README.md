# Evaluación Parcial 1: Infraestructura como Código[cite: 2]

## Datos de los Estudiantes[cite: 2]
* **Nombres:** Francisco Flefil y Javier Caro
* **Carrera:** Ingeniería en Infraestructuras Tecnológicas (Duoc UC)
* **Asignatura:** Infraestructura como código I (AUY1103)[cite: 2]

## Evidencias de Validación (Etapa 3)[cite: 2]
A continuación, se presentan las capturas que validan el correcto funcionamiento de los recursos desplegados:

* **1. Acceso al servidor Web:** Validación de acceso vía internet al servidor web alojado en la instancia Linux[cite: 2].
  *(Reemplaza esta línea con tu imagen: `![Validación Web](./capturas/web.png)`)*

* **2. Acceso a la base de datos RDS:** Conexión exitosa a MySQL (flefil-caro-db) utilizando un IDE con la credencial creada[cite: 2].
  *(Reemplaza esta línea con tu imagen: `![Validación RDS](./capturas/rds.png)`)*

* **3. Almacenamiento S3:** Carga de una imagen en el bucket público (flefil-caro-cdn-bucket) y acceso validado desde el equipo local[cite: 2].
  *(Reemplaza esta línea con tu imagen: `![Validación S3](./capturas/s3.png)`)*

## Persistencia de Datos (Etapa 4)[cite: 2]
**a) Justificación de la técnica:**
Para garantizar la persistencia de datos ante un evento de destrucción (terraform destroy), se implementó una estrategia declarativa nativa de Terraform[cite: 2]. 
Se utilizaron los meta-argumentos `skip_final_snapshot = false`, `final_snapshot_identifier` y `deletion_protection = true`[cite: 2]. 
Esta técnica automatiza la creación de un respaldo exacto antes de permitir la eliminación, garantizando la recuperación de la información sin depender de operaciones manuales fuera del código[cite: 2].

**b) Evidencia del ciclo completo:**
Capturas demostrando el aprovisionamiento, la ejecución de terraform destroy con la conservación del respaldo, y la restauración exitosa del recurso[cite: 2].
  *(Reemplaza esta línea con tu imagen: `![Ciclo Persistencia](./capturas/ciclo.png)`)*

**c) Análisis de alternativa NO recomendada:**
Una alternativa no recomendada es el uso del comando `terraform state rm <recurso>`[cite: 2]. Este comando elimina el recurso del archivo de estado local sin borrarlo de la nube. 
Constituye una mala práctica de IaC porque genera recursos huérfanos, provocando un drift permanente entre el estado de Terraform y la infraestructura real, además de perder la reproducibilidad 
del entorno[cite: 2].
