import os
import psycopg2
from pymongo import MongoClient
from dotenv import load_dotenv

ruta_env = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
load_dotenv(ruta_env)


def obtener_recaudacion_postgres():
    conexion = psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=os.getenv("PG_PORT", "5432"),
        dbname=os.getenv("PG_DB", "bosque_cinema"),
        user=os.getenv("PG_USER", "postgres"),
        password=os.getenv("PG_PASSWORD", ""),
        sslmode=os.getenv("PG_SSLMODE", "prefer")
    )
    consulta = """
        WITH peliculas_pg AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY MIN(f.id_funcion))::INTEGER AS id_pelicula,
                f.titulo_pelicula AS titulo,
                COALESCE(SUM(CASE WHEN v.estado = 'PAGADA' THEN v.cantidad * v.precio_unitario ELSE 0 END), 0) AS total_recaudado
            FROM funciones f
            LEFT JOIN ventas v ON f.id_funcion = v.id_funcion
            GROUP BY f.titulo_pelicula
        )
        SELECT id_pelicula, titulo, total_recaudado
        FROM peliculas_pg
        ORDER BY total_recaudado DESC, titulo ASC;
    """
    with conexion:
        with conexion.cursor() as cursor:
            cursor.execute(consulta)
            filas = cursor.fetchall()
    conexion.close()
    return filas


def obtener_metricas_mongo():
    cliente = MongoClient(os.getenv("MONGO_URI", "mongodb://localhost:27017"))
    db = cliente[os.getenv("MONGO_DB", "bosque_cinema")]
    pipeline = [
        {
            "$group": {
                "_id": "$id_pelicula",
                "promedio": {"$avg": "$calificacion"},
                "cantidad": {"$sum": 1}
            }
        }
    ]
    resultados = db.resenas_peliculas.aggregate(pipeline)
    mapa_resenas = {}
    for doc in resultados:
        mapa_resenas[doc["_id"]] = {
            "promedio": round(doc["promedio"], 2),
            "cantidad": doc["cantidad"]
        }
    cliente.close()
    return mapa_resenas


def main():
    peliculas_pg = obtener_recaudacion_postgres()
    resenas_mongo = obtener_metricas_mongo()

    encabezado = f"{'TITULO':<36} | {'RECAUDADO':>14} | {'PROMEDIO':>12} | {'RESENAS':>8}"
    print(encabezado)
    print("-" * len(encabezado))

    for id_pelicula, titulo, total_recaudado in peliculas_pg:
        info_mongo = resenas_mongo.get(id_pelicula)
        if info_mongo:
            promedio_txt = f"{info_mongo['promedio']:.2f}"
            cantidad_txt = str(info_mongo["cantidad"])
        else:
            promedio_txt = "sin reseñas"
            cantidad_txt = "0"

        print(f"{titulo:<36} | {total_recaudado:>14,.2f} | {promedio_txt:>12} | {cantidad_txt:>8}")


if __name__ == "__main__":
    main()