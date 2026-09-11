import 'package:flutter/material.dart';
import '../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../utils/app_logger.dart';

class CnabConfigScreen extends StatefulWidget {
  final int? empresaId;
  final int? parceiroId;

  const CnabConfigScreen({super.key, this.empresaId, this.parceiroId});

  @override
  State<CnabConfigScreen> createState() => _CnabConfigScreenState();
}

class _CnabConfigScreenState extends State<CnabConfigScreen> {
  bool _loading = false;
  List<dynamic> _contasBancarias = [];
  int? _selectedContaId;
  Map<String, dynamic> _config = {};

  final _formKey = GlobalKey<FormState>();
  final _layoutCtrl = TextEditingController();
  final _beneficiarioCtrl = TextEditingController();
  final _carteiraCtrl = TextEditingController();
  final _variacaoCtrl = TextEditingController();
  final _transmissaoCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();
  final _sequencialRemessaCtrl = TextEditingController();
  final _sequencialNossoNumeroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContas();
  }

  Future<void> _loadContas() async {
    setState(() => _loading = true);
    try {
      String query = '';
      if (widget.empresaId != null && widget.empresaId! > 0) {
        query = 'empresaId=${widget.empresaId}';
      } else if (widget.parceiroId != null && widget.parceiroId! > 0) {
        query = 'parceiroId=${widget.parceiroId}';
      } else {
        return;
      }
      
      final res = await NetworkCaller().getRequest('${ApiLinks.contasBancarias}?$query');
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'] ?? res.body!['content'] ?? res.body;
        if (data is List) {
          setState(() {
            _contasBancarias = data;
          });
        }
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar contas bancárias', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadConfig(int contaId) async {
    setState(() => _loading = true);
    try {
      final res = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/conta-bancaria-cnab-config/conta/$contaId');
      if (res.isSuccess && res.body != null) {
        _config = res.body!;
        _layoutCtrl.text = _config['layoutCnab']?.toString() ?? '240';
        _beneficiarioCtrl.text = _config['codigoBeneficiario']?.toString() ?? '';
        _carteiraCtrl.text = _config['carteira']?.toString() ?? '';
        _variacaoCtrl.text = _config['variacaoCarteira']?.toString() ?? '';
        _transmissaoCtrl.text = _config['codigoTransmissao']?.toString() ?? '';
        _postoCtrl.text = _config['postoBeneficiario']?.toString() ?? '';
        _sequencialRemessaCtrl.text = _config['sequencialRemessa']?.toString() ?? '1';
        _sequencialNossoNumeroCtrl.text = _config['sequencialNossoNumero']?.toString() ?? '1';
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar config CNAB', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContaId == null) return;
    
    setState(() => _loading = true);
    try {
      final payload = {
        'layoutCnab': _layoutCtrl.text,
        'codigoBeneficiario': _beneficiarioCtrl.text,
        'carteira': _carteiraCtrl.text,
        'variacaoCarteira': _variacaoCtrl.text,
        'codigoTransmissao': _transmissaoCtrl.text,
        'postoBeneficiario': _postoCtrl.text,
        'sequencialRemessa': int.tryParse(_sequencialRemessaCtrl.text) ?? 1,
        'sequencialNossoNumero': int.tryParse(_sequencialNossoNumeroCtrl.text) ?? 1,
      };
      
      final res = await NetworkCaller().postRequest('${ApiLinks.baseUrl}/api/conta-bancaria-cnab-config/conta/$_selectedContaId', payload);
      if (res.isSuccess) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuração salva com sucesso!')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${res.statusCode}')));
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao salvar config CNAB', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _contasBancarias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_contasBancarias.isEmpty) {
      return const Center(child: Text('Nenhuma conta bancária cadastrada para este registro.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecione a Conta Bancária', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedContaId,
            items: _contasBancarias.map((c) {
              final id = c['id'] as int;
              final nome = c['descricao'] ?? c['banco'] ?? 'Conta $id';
              return DropdownMenuItem<int>(
                value: id,
                child: Text('$nome (Ag: ${c['agencia']} CC: ${c['numero']})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedContaId = val);
                _loadConfig(val);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          if (_selectedContaId != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _layoutCtrl.text.isEmpty ? '240' : _layoutCtrl.text,
                        items: const [
                          DropdownMenuItem(value: '240', child: Text('CNAB 240 (Banco do Brasil, Sicoob, etc)')),
                          DropdownMenuItem(value: '400', child: Text('CNAB 400 (Itaú, Bradesco, etc)')),
                        ],
                        onChanged: (val) => setState(() => _layoutCtrl.text = val ?? '240'),
                        decoration: const InputDecoration(labelText: 'Layout CNAB', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _beneficiarioCtrl,
                        decoration: const InputDecoration(labelText: 'Código do Beneficiário / Convênio', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _carteiraCtrl,
                              decoration: const InputDecoration(labelText: 'Carteira', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _variacaoCtrl,
                              decoration: const InputDecoration(labelText: 'Variação da Carteira (BB)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _transmissaoCtrl,
                              decoration: const InputDecoration(labelText: 'Código Transmissão (Itaú)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _postoCtrl,
                              decoration: const InputDecoration(labelText: 'Posto Beneficiário (Sicoob)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sequencialRemessaCtrl,
                              decoration: const InputDecoration(labelText: 'Sequencial Atual da Remessa', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sequencialNossoNumeroCtrl,
                              decoration: const InputDecoration(labelText: 'Sequencial Atual Nosso Número', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar Configuração CNAB'),
                        onPressed: _loading ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
