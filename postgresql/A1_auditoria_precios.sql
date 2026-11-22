CREATE TABLE IF NOT EXISTS auditoria_precios (
    id SERIAL PRIMARY KEY,
    id_tipo_boleta INTEGER NOT NULL,
    precio_anterior NUMERIC(10, 2) NOT NULL,
    precio_nuevo NUMERIC(10, 2) NOT NULL,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_tipo_boleta FOREIGN KEY (id_tipo_boleta)
        REFERENCES tipos_boleta (id_tipo_boleta)
);

CREATE OR REPLACE FUNCTION fn_auditar_precio()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.precio IS DISTINCT FROM NEW.precio THEN
        INSERT INTO auditoria_precios (id_tipo_boleta, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (NEW.id_tipo_boleta, OLD.precio, NEW.precio, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditar_precio ON tipos_boleta;

CREATE TRIGGER trg_auditar_precio
AFTER UPDATE ON tipos_boleta
FOR EACH ROW
EXECUTE FUNCTION fn_auditar_precio();

SELECT id_tipo_boleta, nombre, precio FROM tipos_boleta WHERE id_tipo_boleta = 1;

UPDATE tipos_boleta SET precio = 19500.00 WHERE id_tipo_boleta = 1;
SELECT * FROM auditoria_precios;

UPDATE tipos_boleta SET precio = 19500.00 WHERE id_tipo_boleta = 1;
SELECT * FROM auditoria_precios;