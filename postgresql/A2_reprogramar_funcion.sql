CREATE OR REPLACE PROCEDURE sp_reprogramar_funcion(
    p_id_funcion INTEGER,
    p_nueva_fecha TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_sala INTEGER;
    v_duracion INTERVAL;
    v_conflictos INTEGER;
BEGIN
    SELECT id_sala, (fecha_hora_fin - fecha_hora_inicio)
    INTO v_id_sala, v_duracion
    FROM funciones
    WHERE id_funcion = p_id_funcion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La funcion con ID % no existe.', p_id_funcion;
    END IF;

    IF p_nueva_fecha <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La nueva fecha (%) debe ser posterior a la fecha y hora actual.', p_nueva_fecha;
    END IF;

    SELECT COUNT(*)
    INTO v_conflictos
    FROM funciones
    WHERE id_sala = v_id_sala
      AND id_funcion <> p_id_funcion
      AND estado <> 'CANCELADA'
      AND (
          fecha_hora_inicio = p_nueva_fecha
          OR (p_nueva_fecha < fecha_hora_fin AND (p_nueva_fecha + v_duracion) > fecha_hora_inicio)
      );

    IF v_conflictos > 0 THEN
        RAISE EXCEPTION 'La sala % ya tiene otra funcion programada en esa fecha y hora (%).', v_id_sala, p_nueva_fecha;
    END IF;

    UPDATE funciones
    SET fecha_hora_inicio = p_nueva_fecha,
        fecha_hora_fin = p_nueva_fecha + v_duracion
    WHERE id_funcion = p_id_funcion;
END;
$$;

SELECT id_funcion, id_sala, titulo_pelicula, fecha_hora_inicio, fecha_hora_fin
FROM funciones
WHERE id_funcion = 17;

CALL sp_reprogramar_funcion(17, '2026-12-20 18:00:00');

SELECT id_funcion, id_sala, titulo_pelicula, fecha_hora_inicio, fecha_hora_fin
FROM funciones
WHERE id_funcion = 17;

CALL sp_reprogramar_funcion(99999, '2026-12-20 18:00:00');

CALL sp_reprogramar_funcion(17, '2025-05-10 15:00:00');

CALL sp_reprogramar_funcion(18, '2026-12-20 18:00:00');
