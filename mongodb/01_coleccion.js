use("bosque_cinema");

db.resenas_peliculas.drop();

db.createCollection("resenas_peliculas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_pelicula", "calificacion", "texto", "fecha"],
      properties: {
        id_pelicula: {
          bsonType: "int"
        },
        calificacion: {
          bsonType: "int",
          minimum: 1,
          maximum: 5
        },
        texto: {
          bsonType: "string",
          minLength: 1
        },
        fecha: {
          bsonType: "date"
        },
        respuesta_empresa: {
          bsonType: "object",
          required: ["texto", "fecha"],
          properties: {
            texto: {
              bsonType: "string",
              minLength: 1
            },
            fecha: {
              bsonType: "date"
            }
          }
        }
      }
    }
  }
});

db.resenas_peliculas.insertOne({
  id_pelicula: Int32(1),
  calificacion: Int32(5),
  texto: "Excelente sonido y comodidad en la sala Roble.",
  fecha: new Date("2026-11-10T19:00:00Z"),
  respuesta_empresa: {
    texto: "Muchas gracias por visitar Bosque Cinema.",
    fecha: new Date("2026-11-11T09:00:00Z")
  }
});

db.resenas_peliculas.insertOne({
  id_pelicula: Int32(1),
  calificacion: Int32(6),
  texto: "Documento invalido porque la calificacion supera 5.",
  fecha: new Date("2026-11-10T19:00:00Z")
});