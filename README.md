# Taller Individual — Entrega Final (Bases de Datos 2)

- **Estudiante:** Juan David Gómez Villamizar
- **Código estudiantil:** `1019842767`
- **Dato personal ($D$):** `7`
- **Total de reseñas ($N = 30 + D$):** `37`

## Adaptaciones al modelo del Avance 1
1. **A1 (`tipos_boleta`):** En nuestro modelo 3FN, el precio se define en `tipos_boleta.precio` y no en `funciones`, por lo que `auditoria_precios` y el trigger se implementaron sobre `tipos_boleta` usando `id_tipo_boleta`.
2. **A2 (`funciones`):** Nuestra tabla maneja `fecha_hora_inicio` y `fecha_hora_fin` con una restricción de orden temporal, por lo que el procedimiento desplaza ambas marcas conservando la duración original de la función.
3. **A3 y C (`ventas` y `titulo_pelicula`):** No existe tabla `peliculas` ni `boletas`; los títulos se agrupan desde `funciones.titulo_pelicula` (asignando `id_pelicula` determinístico del 1 al 16) y el recaudo se calcula con `cantidad * precio_unitario` sobre ventas en estado `PAGADA`.

## Ejecución del proyecto
1. **PostgreSQL:** Crear la base de datos `bosque_cinema`, cargar los scripts del Avance 1 (`01` a `04`) y ejecutar `postgresql/A1_auditoria_precios.sql`, `postgresql/A2_reprogramar_funcion.sql` y `postgresql/A3_ranking_mensual.sql`.
2. **MongoDB:** Ejecutar en `mongosh` los scripts `mongodb/01_coleccion.js`, `mongodb/02_datos.js` y `mongodb/03_consultas.js` sobre la base `bosque_cinema`.
3. **Integración:** Copiar `integracion/.env.example` a `integracion/.env` con las credenciales correspondientes (`PG_HOST`, `PG_PORT`, `PG_DB`, `PG_USER`, `PG_PASSWORD`, `PG_SSLMODE`, `MONGO_URI`, `MONGO_DB`), instalar dependencias con `pip install -r integracion/requirements.txt` y ejecutar `python integracion/reporte_peliculas.py`.

## Resultados Parte B3 ($D = 7, N = 37$)
- **Promedio general de todas las reseñas:** `3.08` (`114 / 37`)
- **Cantidad de reseñas devueltas por la consulta 2 (`calificacion <= 2` sin `respuesta_empresa`):** `9`

## Justificación del código

### A1. Trigger de auditoría de precios
Uso `AFTER UPDATE` porque audito cambios reales que ya superaron las restricciones y validaciones `BEFORE UPDATE` de `tipos_boleta` (como impedir editar tarifas inactivas). En la línea `IF OLD.precio IS DISTINCT FROM NEW.precio THEN` evito insertar registros cuando se actualiza otra columna o cuando se asigna el mismo precio anterior.

### A2. Procedimiento de reprogramación
Lo implementé como `PROCEDURE` y no como `FUNCTION` porque ejecuta una acción transaccional (`UPDATE`) y valida reglas de negocio sin retornar un conjunto de filas. Si falla alguna de las tres validaciones y se lanza `RAISE EXCEPTION`, PostgreSQL aborta la transacción y revierte cualquier cambio dejado pendiente en `funciones`.

### A3. Consulta con función de ventana
Particiono por `mes` (`PARTITION BY mes`) para que el ranking se reinicie cada mes y compare películas dentro del mismo periodo. En mis datos de `2026-10`, *Duelo en la Frontera* y *El Jardín de Cristal* empatan con `$36,000.00` en el puesto `11`; ante un empate así, `RANK()` saltaría al puesto `13` en la siguiente fila, mientras `DENSE_RANK()` asignaría el `12` sin dejar huecos.

### B1. Colección `resenas_peliculas` con `$jsonSchema`
Escogí `id_pelicula`, `calificacion`, `texto` y `fecha` como obligatorios porque son los datos mínimos para vincular una reseña válida a una película en una fecha, dejando `respuesta_empresa` opcional porque no toda opinión se responde. El validador rechaza documentos con tipos BSON incorrectos (como `double` en vez de `int`), calificaciones fuera de `[1, 5]`, textos vacíos o respuestas incompletas.

### B2. Datos de prueba ($N = 37$)
Generé los 37 documentos con un ciclo `for` de `i = 1` a `37` aplicando `((i + 7) % 5) + 1` para la calificación, `(i - 1) % 14` para ciclar los IDs del 1 al 14 y `i % 3 === 0` para agregar `respuesta_empresa`. Comprobé el cumplimiento verificando `countDocuments() === 37`, el promedio general (`3.08`) y el total de reseñas negativas sin respuesta (`9`).

### B3. Consultas en MongoDB
Ubiqué `$group` primero para calcular promedio y cantidad de reseñas por `id_pelicula`, luego `$match` para filtrar solo grupos con `numero_resenas >= 3`, después `$sort` para ordenar de mayor a menor promedio sobre el conjunto ya filtrado y finalmente `$project` para dar formato limpio y redondeado a la salida.

### C. Integración PostgreSQL + MongoDB
Consulto en PostgreSQL cada película con su recaudo de ventas `PAGADA` y en MongoDB agrupo las reseñas por `id_pelicula` cargándolas en un diccionario en memoria indexado por `id_pelicula`. Luego recorro las películas de PostgreSQL buscando su clave en el diccionario (`resenas_mongo.get(id_pelicula)`); si no existe (como en *Duelo en la Frontera* y *Latidos*), muestro `"sin reseñas"` y `0`.
