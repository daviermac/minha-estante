import 'package:flutter/material.dart';
import '../../domain/livro.dart';

const _ink = Color(0xFF1B3040);
const _teal = Color(0xFF148E8A);

class EstanteTela extends StatelessWidget {
  const EstanteTela({
    super.key,
    required this.livros,
    required this.onAdicionar,
    required this.onAbrirLivro,
    required this.onSair,
    required this.email,
    this.saindo = false,
  });

  final List<Livro> livros;
  final VoidCallback onAdicionar;
  final ValueChanged<Livro> onAbrirLivro;
  final VoidCallback onSair;
  final String email;
  final bool saindo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Estante'), actions: [
        TextButton.icon(
          onPressed: saindo ? null : onSair,
          icon: saindo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.logout, color: Colors.white),
          label: Text(saindo ? 'Saindo…' : 'Sair',
              style: const TextStyle(color: Colors.white)),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdicionar,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: const TextStyle(color: _teal)),
              const SizedBox(height: 12),
              Text('Sua biblioteca pessoal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 6),
              Text(
                livros.isEmpty
                    ? 'Organize e acompanhe suas próximas leituras.'
                    : '${livros.length} ${livros.length == 1 ? 'livro cadastrado' : 'livros cadastrados'}',
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: livros.isEmpty
                    ? _EstadoVazio(onAdicionar: onAdicionar)
                    : ListView.separated(
                        itemCount: livros.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final livro = livros[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onAbrirLivro(livro),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.menu_book_rounded,
                                        color: _teal, size: 36),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(livro.titulo,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              )),
                                          const SizedBox(height: 4),
                                          Text(livro.autor),
                                          const SizedBox(height: 8),
                                          _StatusChip(status: livro.status),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.onAdicionar});

  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, color: _teal, size: 72),
            const SizedBox(height: 16),
            Text('Sua estante está vazia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            const Text('Cadastre seu primeiro livro para começar.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar livro'),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroLivroTela extends StatefulWidget {
  const CadastroLivroTela({super.key});

  @override
  State<CadastroLivroTela> createState() => _CadastroLivroTelaState();
}

class _CadastroLivroTelaState extends State<CadastroLivroTela> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _autor = TextEditingController();
  final _genero = TextEditingController();
  StatusLeitura? _status;
  int? _nota;

  @override
  void dispose() {
    _titulo.dispose();
    _autor.dispose();
    _genero.dispose();
    super.dispose();
  }

  String? _validarTexto(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) return 'Informe $campo.';
    return null;
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Livro(
        titulo: _titulo.text.trim(),
        autor: _autor.text.trim(),
        genero: _genero.text.trim(),
        status: _status!,
        nota: _nota!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar livro')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Novo livro',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.bold,
                              )),
                  const SizedBox(height: 6),
                  const Text('Preencha os dados para adicionar à sua estante.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titulo,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Título *'),
                    validator: (v) => _validarTexto(v, 'o título'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _autor,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Autor *'),
                    validator: (v) => _validarTexto(v, 'o autor'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _genero,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Gênero *'),
                    validator: (v) => _validarTexto(v, 'o gênero'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StatusLeitura>(
                    value: _status,
                    decoration:
                        const InputDecoration(labelText: 'Status de leitura *'),
                    items: StatusLeitura.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _status = value),
                    validator: (value) =>
                        value == null ? 'Selecione o status de leitura.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _nota,
                    decoration:
                        const InputDecoration(labelText: 'Nota / avaliação *'),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child:
                            Text('${i + 1} ${i == 0 ? 'estrela' : 'estrelas'}'),
                      ),
                    ),
                    onChanged: (value) => setState(() => _nota = value),
                    validator: (value) =>
                        value == null ? 'Selecione uma nota de 1 a 5.' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('* Campos obrigatórios',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar livro'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetalhesLivroTela extends StatelessWidget {
  const DetalhesLivroTela({super.key, required this.livro});

  final Livro livro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            color: _teal, size: 48),
                        const SizedBox(height: 16),
                        Text(livro.titulo,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.bold,
                                )),
                        const SizedBox(height: 4),
                        Text('por ${livro.autor}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _StatusChip(status: livro.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetalheLinha(rotulo: 'Título', valor: livro.titulo),
                        const Divider(height: 28),
                        _DetalheLinha(rotulo: 'Autor', valor: livro.autor),
                        const Divider(height: 28),
                        _DetalheLinha(rotulo: 'Gênero', valor: livro.genero),
                        const Divider(height: 28),
                        _DetalheLinha(
                            rotulo: 'Status de leitura',
                            valor: livro.status.label),
                        const Divider(height: 28),
                        Text('Nota / avaliação',
                            style: TextStyle(color: Colors.blueGrey.shade700)),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < livro.nota
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFCF8D25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetalheLinha extends StatelessWidget {
  const _DetalheLinha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: TextStyle(color: Colors.blueGrey.shade700)),
        const SizedBox(height: 5),
        Text(valor,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            )),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StatusLeitura status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE3F3F1),
      label: Text(status.label,
          style: const TextStyle(color: _teal, fontWeight: FontWeight.w600)),
    );
  }
}
