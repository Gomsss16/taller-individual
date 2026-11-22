use("bosque_cinema");

db.resenas_peliculas.deleteMany({});

const D = 7;
const N = 30 + D;
const peliculasIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

const textosPositivos = [
  "Muy buena fotografia y excelente sonido envolvente en la sala.",
  "Gran historia, recomendable para ver en pantalla grande.",
  "Excelente atencion del personal y proyeccion muy nitida."
];

const textosNegativos = [
  "El aire acondicionado estaba muy frio y la funcion empezo tarde.",
  "El volumen estuvo demasiado bajo durante toda la pelicula."
];

const documentos = [];

for (let i = 1; i <= N; i++) {
  const calificacion = ((i + D) % 5) + 1;
  const idPelicula = peliculasIds[(i - 1) % peliculasIds.length];
  const texto = calificacion >= 3
    ? textosPositivos[i % textosPositivos.length]
    : textosNegativos[i % textosNegativos.length];
  const fechaResena = new Date(Date.UTC(2026, 10, 1 + (i % 18), 19, 0, 0));

  const doc = {
    id_pelicula: Int32(idPelicula),
    calificacion: Int32(calificacion),
    texto: texto,
    fecha: fechaResena
  };

  if (i % 3 === 0) {
    doc.respuesta_empresa = {
      texto: "Gracias por tu opinion, trabajamos para mejorar tu experiencia.",
      fecha: new Date(fechaResena.getTime() + 86400000)
    };
  }

  documentos.push(doc);
}

db.resenas_peliculas.insertMany(documentos);
print("Total documentos:", db.resenas_peliculas.countDocuments());