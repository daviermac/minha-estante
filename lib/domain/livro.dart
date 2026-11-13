enum StatusLeitura { queroLer, lendo, concluido }

extension StatusLeituraTexto on StatusLeitura {
  String get label => switch (this) {
        StatusLeitura.queroLer => 'Quero ler',
        StatusLeitura.lendo => 'Lendo',
        StatusLeitura.concluido => 'Concluído',
      };
}

class Livro {
  const Livro({
    this.id,
    required this.titulo,
    required this.autor,
    required this.genero,
    required this.status,
    required this.nota,
  });

  /// Identificador do documento no Firestore. É nulo antes de ser salvo.
  final String? id;
  final String titulo;
  final String autor;
  final String genero;
  final StatusLeitura status;
  final int nota;

  Livro copyWith({String? id}) => Livro(
        id: id ?? this.id,
        titulo: titulo,
        autor: autor,
        genero: genero,
        status: status,
        nota: nota,
      );

  /// Campos editáveis gravados no Firestore (sem datas e sem UID).
  Map<String, Object> toMap() => {
        'title': titulo,
        'author': autor,
        'genre': genero,
        'status': status.name,
        'rating': nota,
      };

  factory Livro.fromMap(String id, Map<String, dynamic> data) => Livro(
        id: id,
        titulo: data['title'] as String? ?? '',
        autor: data['author'] as String? ?? '',
        genero: data['genre'] as String? ?? '',
        status: StatusLeitura.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => StatusLeitura.queroLer,
        ),
        nota: ((data['rating'] as num?)?.toInt() ?? 1).clamp(1, 5),
      );
}
