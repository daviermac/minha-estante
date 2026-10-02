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
    required this.titulo,
    required this.autor,
    required this.genero,
    required this.status,
    required this.nota,
  });

  final String titulo;
  final String autor;
  final String genero;
  final StatusLeitura status;
  final int nota;
}
