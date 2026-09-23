import 'package:flutter/material.dart';

import '../constants/custom_colors.dart';
import '../models/setor_model.dart';
import '../services/setor_caller.dart';

typedef SetoresLoader = Future<List<Setor>> Function();
typedef LoginSetoresLoader = Future<List<Setor>> Function(int loginId);
typedef LoginSetorUpdater = Future<bool> Function(int loginId, int setorId);

class LoginSetoresDetail extends StatefulWidget {
  final int? loginId;
  final SetoresLoader carregarSetores;
  final LoginSetoresLoader carregarSetoresDoLogin;
  final LoginSetorUpdater vincularSetor;
  final LoginSetorUpdater desvincularSetor;

  LoginSetoresDetail({
    super.key,
    required this.loginId,
    SetoresLoader? carregarSetores,
    LoginSetoresLoader? carregarSetoresDoLogin,
    LoginSetorUpdater? vincularSetor,
    LoginSetorUpdater? desvincularSetor,
  })  : carregarSetores = carregarSetores ?? SetorCaller().fetchAllSetores,
        carregarSetoresDoLogin =
            carregarSetoresDoLogin ?? SetorCaller().fetchSetoresDoLogin,
        vincularSetor =
            vincularSetor ?? SetorCaller().associarSetorAoLogin,
        desvincularSetor =
            desvincularSetor ?? SetorCaller().removerSetorDoLogin;

  @override
  State<LoginSetoresDetail> createState() => _LoginSetoresDetailState();
}

class _LoginSetoresDetailState extends State<LoginSetoresDetail> {
  late Future<void> _future;
  List<Setor> _setores = [];
  Set<int> _iniciais = {};
  Set<int> _selecionados = {};
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<void> _carregar() async {
    final loginId = widget.loginId;
    if (loginId == null || loginId <= 0) return;

    final resultados = await Future.wait([
      widget.carregarSetores(),
      widget.carregarSetoresDoLogin(loginId),
    ]);
    final todos = resultados[0];
    final vinculados = resultados[1];
    final porId = <int, Setor>{};
    for (final setor in [...todos, ...vinculados]) {
      if (setor.id != null) porId[setor.id!] = setor;
    }
    _setores = porId.values.toList()
      ..sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));
    _iniciais = vinculados
        .where((setor) => setor.id != null)
        .map((setor) => setor.id!)
        .toSet();
    _selecionados = {..._iniciais};
  }

  bool get _alterado =>
      _iniciais.length != _selecionados.length ||
      !_iniciais.containsAll(_selecionados);

  Future<void> _salvar() async {
    final loginId = widget.loginId;
    if (loginId == null || !_alterado || _salvando) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });
    final adicionar = _selecionados.difference(_iniciais);
    final remover = _iniciais.difference(_selecionados);
    final resultados = await Future.wait([
      ...adicionar.map((id) => widget.vincularSetor(loginId, id)),
      ...remover.map((id) => widget.desvincularSetor(loginId, id)),
    ]);
    if (!mounted) return;

    if (resultados.any((ok) => !ok)) {
      setState(() {
        _salvando = false;
        _erro = 'Nao foi possivel salvar todos os vinculos de setores.';
      });
      return;
    }

    setState(() {
      _iniciais = {..._selecionados};
      _salvando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setores vinculados com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _mensagem('Falha ao carregar os setores disponiveis.');
        }
        if (widget.loginId == null || widget.loginId! <= 0) {
          return _mensagem('Salve o login antes de vincular setores.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vincular setores',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: GridColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecione os setores existentes que este login pode acessar.',
                    style: TextStyle(
                      color: GridColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _setores.isEmpty
                  ? _mensagem('Nenhum setor disponivel para vinculo.')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _setores.length,
                      itemBuilder: (context, index) {
                        final setor = _setores[index];
                        final setorId = setor.id!;
                        return CheckboxListTile(
                          key: Key('login-setor-$setorId'),
                          value: _selecionados.contains(setorId),
                          title: Text(setor.nome ?? 'Setor #$setorId'),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: GridColors.success,
                          onChanged: _salvando
                              ? null
                              : (marcado) => setState(() {
                                    if (marcado == true) {
                                      _selecionados.add(setorId);
                                    } else {
                                      _selecionados.remove(setorId);
                                    }
                                    _erro = null;
                                  }),
                        );
                      },
                    ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  _erro!,
                  style: const TextStyle(color: GridColors.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _alterado && !_salvando ? _salvar : null,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Salvar vínculos'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mensagem(String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}
