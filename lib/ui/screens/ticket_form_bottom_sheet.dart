import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/services/chamado_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/data/models/setor_model.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

class TicketFormBottomSheet extends StatefulWidget {
  final String sectorDescricao; // nome do setor vindo do chat

  const TicketFormBottomSheet({super.key, required this.sectorDescricao});

  @override
  State<TicketFormBottomSheet> createState() => _TicketFormBottomSheetState();
}

class _TicketFormBottomSheetState extends State<TicketFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();

  // dropdowns
  String _status = 'ABERTO';
  String _prioridade = 'MEDIA';

  int? _setorId;
  String? _setorDesc;

  bool _submitting = false;
  List<Map<String, dynamic>> _setores = [];

  @override
  void initState() {
    super.initState();
    _carregarSetores();
  }

  Future<void> _carregarSetores() async {
    final itens = await Chamado.loadSetores();
    setState(() {
      _setores = itens;
      // tentar pré-selecionar pelo nome do setor vindo do chat
      final found = _setores.firstWhere(
        (e) =>
            (e['label'] as String).toLowerCase().trim() ==
            widget.sectorDescricao.toLowerCase().trim(),
        orElse: () => {},
      );
      if (found is Map && found.isNotEmpty) {
        _setorId = found['value'] as int;
        _setorDesc = found['label'] as String;
      }
    });
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _setorId == null) return;
    setState(() => _submitting = true);
    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final user = AuthUtility.userInfo?.data;

// Monta o objeto Empresa manualmente, já que Data não tem esse campo
      final empresa = Empresa(
        id: pegarEmpresaLogada(),
      );

// Converte o usuário logado (Data) em Login, se necessário
      final usuarioAbertura = Login(
        id: user?.id ?? 0,
      );

// Cria o Setor apenas com ID, já que o model não tem `descricao`
      final setor = Setor(id: _setorId!);

      final chamado = Chamado(
        titulo: _titulo.text,
        descricao: _descricao.text,
        status: StatusChamadoEnum.fromString(_status),
        prioridade: PrioridadeChamadoEnum.fromString(_prioridade),
        empresa: empresa,
        usuarioAbertura: usuarioAbertura,
        setor: setor,
        dataAbertura: DateTime.now(),
      );
      final criado = await ChamadoCaller().createChamado(chamado, token: token);

      if (mounted) {
        Navigator.pop(context, criado); // volta pro chat com o Chamado criado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Chamado aberto com sucesso (ID ${criado.id})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir chamado: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Abrir Chamado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titulo,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o título'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descricao,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a descrição'
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // Prioridade
                  DropdownButtonFormField<String>(
                    value: _prioridade,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: const [
                      DropdownMenuItem(value: 'BAIXA', child: Text('Baixa')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                      DropdownMenuItem(
                          value: 'URGENTE', child: Text('Urgente')),
                    ],
                    onChanged: (v) =>
                        setState(() => _prioridade = v ?? 'MEDIA'),
                  ),
                  const SizedBox(height: 8),

                  // Status (fixo "ABERTO" mas deixei dropdown se quiser)
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'ABERTO', child: Text('Aberto')),
                      DropdownMenuItem(
                          value: 'EM_ANDAMENTO', child: Text('Em Andamento')),
                      DropdownMenuItem(
                          value: 'FECHADO', child: Text('Fechado')),
                      DropdownMenuItem(
                          value: 'CANCELADO', child: Text('Cancelado')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'ABERTO'),
                  ),
                  const SizedBox(height: 8),

                  // Setor (dinâmico do backend)
                  DropdownButtonFormField<int>(
                    value: _setorId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Setor'),
                    items: _setores.map((e) {
                      return DropdownMenuItem<int>(
                        value: e['value'] as int,
                        child: Text(e['label'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _setorId = v;
                        _setorDesc =
                            _setores.firstWhere((e) => e['value'] == v)['label']
                                as String;
                      });
                    },
                    validator: (v) => v == null ? 'Selecione um setor' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Abrir Chamado'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
