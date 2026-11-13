import 'package:flutter/material.dart';
import '../../data/livro_repository.dart';
import '../../domain/livro.dart';

const _ink = Color(0xFF1B3040);
const _teal = Color(0xFF148E8A);

/// Tela principal da área autenticada: lista os livros do usuário.
///
/// É StatefulWidget porque guarda o estado local da busca e do filtro.
/// Os livros em si chegam prontos do Firestore pela [LibraryArea].
class EstanteTela extends StatefulWidget {
  const EstanteTela({
    super.key,
    required this.livros,
    required this.onAdicionar,
    required this.onAbrirLivro,
    required this.onSair,
    required this.email,
    this.erro,
    this.onTentarNovamente,
    this.saindo = false,
  });

  /// Nulo enquanto os dados do Firestore estão carregando.
  final List<Livro>? livros;
  final String? erro;
  final VoidCallback? onTentarNovamente;
  final VoidCallback onAdicionar;
  final ValueChanged<Livro> onAbrirLivro;
  final VoidCallback onSair;
  final String email;
  final bool saindo;

  @override
  State<EstanteTela> createState() => _EstanteTelaState();
}

class _EstanteTelaState extends State<EstanteTela> {
  String _busca = '';
  StatusLeitura? _filtro; // null = todos os status

  /// Aplica busca (título ou autor) e filtro de status sobre a lista.
  List<Livro> _filtrar(List<Livro> livros) {
    final termo = _busca.trim().toLowerCase();
    return livros.where((livro) {
      final combinaStatus = _filtro == null || livro.status == _filtro;
      final combinaBusca = termo.isEmpty ||
          livro.titulo.toLowerCase().contains(termo) ||
          livro.autor.toLowerCase().contains(termo);
      return combinaStatus && combinaBusca;
    }).toList();
  }

  String _resumo(List<Livro> livros) {
    if (livros.isEmpty) return 'Organize e acompanhe suas próximas leituras.';
    final lidos =
        livros.where((l) => l.status == StatusLeitura.concluido).length;
    final total = livros.length == 1
        ? '1 livro cadastrado'
        : '${livros.length} livros cadastrados';
    return '$total · $lidos concluído${lidos == 1 ? '' : 's'}';
  }

  /// Decide o que mostrar: erro, loading, estado vazio ou a lista.
  Widget _conteudo() {
    if (widget.erro != null) {
      return _EstadoErro(
          mensagem: widget.erro!, onTentarNovamente: widget.onTentarNovamente);
    }
    final livros = widget.livros;
    if (livros == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando sua estante…'),
        ]),
      );
    }
    if (livros.isEmpty) return _EstadoVazio(onAdicionar: widget.onAdicionar);

    final visiveis = _filtrar(livros);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar por título ou autor',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (texto) => setState(() => _busca = texto),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: _filtro == null,
            onSelected: (_) => setState(() => _filtro = null),
          ),
          for (final status in StatusLeitura.values)
            ChoiceChip(
              label: Text(status.label),
              selected: _filtro == status,
              onSelected: (_) => setState(() => _filtro = status),
            ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: visiveis.isEmpty
              ? const Center(
                  child: Text('Nenhum livro encontrado com esses filtros.'))
              : ListView.separated(
                  itemCount: visiveis.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _LivroCard(
                    livro: visiveis[index],
                    onTap: () => widget.onAbrirLivro(visiveis[index]),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Estante'), actions: [
        TextButton.icon(
          onPressed: widget.saindo ? null : widget.onSair,
          icon: widget.saindo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.logout, color: Colors.white),
          label: Text(widget.saindo ? 'Saindo…' : 'Sair',
              style: const TextStyle(color: Colors.white)),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAdicionar,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.email, style: const TextStyle(color: _teal)),
              const SizedBox(height: 12),
              Text('Sua biblioteca pessoal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 6),
              Text(_resumo(widget.livros ?? const []),
                  style: TextStyle(color: Colors.blueGrey.shade700)),
              const SizedBox(height: 20),
              Expanded(child: _conteudo()),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivroCard extends StatelessWidget {
  const _LivroCard({required this.livro, required this.onTap});

  final Livro livro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: _teal, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(children: [
                      _StatusChip(status: livro.status),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          size: 18, color: Color(0xFFCF8D25)),
                      Text(' ${livro.nota}'),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, this.onTentarNovamente});

  final String mensagem;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Color(0xFFB3261E), size: 64),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (onTentarNovamente != null)
              OutlinedButton.icon(
                onPressed: onTentarNovamente,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
          ],
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

/// Formulário usado para CREATE (livro nulo) e UPDATE (livro preenchido).
class FormularioLivroTela extends StatefulWidget {
  const FormularioLivroTela({super.key, this.livro, required this.onSalvar});

  final Livro? livro;
  final Future<void> Function(Livro livro) onSalvar;

  @override
  State<FormularioLivroTela> createState() => _FormularioLivroTelaState();
}

class _FormularioLivroTelaState extends State<FormularioLivroTela> {
  final _formKey = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.livro?.titulo);
  late final _autor = TextEditingController(text: widget.livro?.autor);
  late final _genero = TextEditingController(text: widget.livro?.genero);
  late StatusLeitura? _status = widget.livro?.status;
  late int? _nota = widget.livro?.nota;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.livro != null;

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

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.onSalvar(Livro(
        titulo: _titulo.text.trim(),
        autor: _autor.text.trim(),
        genero: _genero.text.trim(),
        status: _status!,
        nota: _nota!,
      ));
      if (mounted) Navigator.of(context).pop(true);
    } on LivroFailure catch (failure) {
      if (mounted) setState(() => _erro = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_editando ? 'Editar livro' : 'Cadastrar livro')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(_editando ? 'Editar livro' : 'Novo livro',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.bold,
                              )),
                  const SizedBox(height: 6),
                  Text(_editando
                      ? 'Altere os dados e salve para atualizar sua estante.'
                      : 'Preencha os dados para adicionar à sua estante.'),
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
                    initialValue: _status,
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
                    initialValue: _nota,
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
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(_erro!,
                        style: const TextStyle(color: Color(0xFFB3261E))),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(_salvando
                        ? 'Salvando…'
                        : _editando
                            ? 'Salvar alterações'
                            : 'Salvar livro'),
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

class DetalhesLivroTela extends StatefulWidget {
  const DetalhesLivroTela({
    super.key,
    required this.livro,
    required this.onEditar,
    required this.onExcluir,
  });

  final Livro livro;
  final VoidCallback onEditar;
  final Future<void> Function() onExcluir;

  @override
  State<DetalhesLivroTela> createState() => _DetalhesLivroTelaState();
}

class _DetalhesLivroTelaState extends State<DetalhesLivroTela> {
  bool _excluindo = false;

  Future<void> _confirmarExclusao() async {
    if (_excluindo) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir livro?'),
        content: Text(
            '“${widget.livro.titulo}” será removido definitivamente da sua estante.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _excluindo = true);
    try {
      await widget.onExcluir();
    } on LivroFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final livro = widget.livro;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro'), actions: [
        IconButton(
          tooltip: 'Editar',
          onPressed: _excluindo ? null : widget.onEditar,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Excluir',
          onPressed: _excluindo ? null : _confirmarExclusao,
          icon: _excluindo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.delete_outline),
        ),
      ]),
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
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _excluindo ? null : widget.onEditar,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar livro'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB3261E)),
                      onPressed: _excluindo ? null : _confirmarExclusao,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(_excluindo ? 'Excluindo…' : 'Excluir livro'),
                    ),
                  ),
                ]),
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
