WITH recaudacion_mensual AS (
    SELECT
        TO_CHAR(f.fecha_hora_inicio, 'YYYY-MM') AS mes,
        f.titulo_pelicula,
        SUM(v.cantidad * v.precio_unitario) AS total_recaudado
    FROM ventas v
    INNER JOIN funciones f ON v.id_funcion = f.id_funcion
    WHERE v.estado = 'PAGADA'
    GROUP BY TO_CHAR(f.fecha_hora_inicio, 'YYYY-MM'), f.titulo_pelicula
)
SELECT
    mes,
    titulo_pelicula,
    total_recaudado,
    RANK() OVER (PARTITION BY mes ORDER BY total_recaudado DESC) AS ranking_rank,
    DENSE_RANK() OVER (PARTITION BY mes ORDER BY total_recaudado DESC) AS ranking_dense_rank
FROM recaudacion_mensual
ORDER BY mes ASC, ranking_rank ASC, titulo_pelicula ASC;
