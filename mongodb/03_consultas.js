use("bosque_cinema");

db.resenas_peliculas.aggregate([
  {
    $group: {
      _id: "$id_pelicula",
      promedio_calificacion: { $avg: "$calificacion" },
      numero_resenas: { $sum: 1 }
    }
  },
  {
    $match: {
      numero_resenas: { $gte: 3 }
    }
  },
  {
    $sort: {
      promedio_calificacion: -1
    }
  },
  {
    $project: {
      _id: 0,
      id_pelicula: "$_id",
      promedio_calificacion: { $round: ["$promedio_calificacion", 2] },
      numero_resenas: 1
    }
  }
]);

db.resenas_peliculas.find({
  calificacion: { $lte: 2 },
  respuesta_empresa: { $exists: false }
});

db.resenas_peliculas.aggregate([
  {
    $group: {
      _id: null,
      promedio_general: { $avg: "$calificacion" },
      total: { $sum: 1 }
    }
  }
]);