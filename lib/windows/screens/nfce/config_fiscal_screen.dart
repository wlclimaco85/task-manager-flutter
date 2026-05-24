import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';

import '../../../services/nfce_service.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/security_matrix.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/nfce/nfce_notice_banner.dart';
import 'nfce_inutilizacao_screen.dart';

/// Tela de configuração fiscal NFC-e.
/// Configurações como CSC, certificado, ambiente, série e UF.
class ConfigFiscalScreen extends StatefulWidget {
  const ConfigFiscalScreen({super.key});

  @override
  State<ConfigFiscalScreen> createState() => _ConfigFiscalScreenState();
}

class _ConfigFiscalScreenState extends State<ConfigFiscalScreen> {
  final NfceService _service = NfceService();
  final _formKey = GlobalKey<FormState>();

  String _uf = 'SP';
  String _ambiente = 'HOMOLOGACAO';
  String _idCsc = '';
  String _csc = '';
  String _serie = '001';
  String _senhaCertificado = '';
  bool _mostrarSenha = false;
  bool _mostrarCsc = false;

  String? _nomeCertificado;
  List<int>? _bytesCertificado;
  int? _configId;

  bool _carregando = false;
  bool _salvando = false;
  bool _verificandoSefaz = false;
  NfceSefazHealthResult? _sefazHealth;

  static const _ufs = [
    'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN',
    'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
  ];

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) return;

    setState(() => _carregando = true);
    try {
      final config = await _service.buscarConfigFiscal(empresaId);
      if (!mounted) return;
      final configuracoes = (config['configuracoes'] is List)
          ? (config['configuracoes'] as List)
              .whereType<Map>()
              .map((item) => item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ))
              .toList()
          : const <Map<String, dynamic>>[];
      final selecionada = configuracoes.cast<Map<String, dynamic>>().firstWhere(
            (item) =>
                (item['uf']?.toString().toUpperCase() ?? '') == _uf &&
                (item['ambiente']?.toString().toUpperCase() ?? '') == _ambiente,
            orElse: () => configuracoes.isNotEmpty
                ? configuracoes.first.cast<String, dynamic>()
                : <String, dynamic>{},
          );
      setState(() {
        _configId = selecionada['id'] is num
            ? (selecionada['id'] as num).toInt()
            : int.tryParse(selecionada['id']?.toString() ?? '');
        _uf = selecionada['uf']?.toString() ?? _uf;
        _ambiente = selecionada['ambiente']?.toString() ?? _ambiente;
        _idCsc = selecionada['idCsc']?.toString() ?? '';
        _csc = selecionada['csc']?.toString() ?? '';
        _serie = selecionada['serieNfce']?.toString() ??
            selecionada['serie']?.toString() ??
            _serie;
      });
    } catch (_) {
      // Config ainda não existe — usa defaults.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarCertificado() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pfx', 'p12'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _nomeCertificado = file.name;
      _bytesCertificado = file.bytes?.toList();
    });
  }

  Future<void> _verificarSefaz() async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    setState(() {
      _verificandoSefaz = true;
      _sefazHealth = null;
    });
    try {
      final result = await _service.verificarSaudeSefaz(
        empresaId: empresaId,
        uf: _uf,
        ambiente: _ambiente,
      );
      if (mounted) setState(() => _sefazHealth = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sefazHealth = NfceSefazHealthResult(
            disponivel: false,
            status: 'DOWN',
            mensagem: 'Falha ao consultar a saúde da SEFAZ: $e',
            uf: _uf,
            ambiente: _ambiente,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _verificandoSefaz = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    setState(() => _salvando = true);
    try {
      if (_bytesCertificado != null && _nomeCertificado != null) {
        if (_senhaCertificado.isEmpty) {
          _mostrarErro(GridTexts.certificatePasswordRequiredBeforeSave);
          return;
        }
        await _service.uploadCertificado(
          fileBytes: _bytesCertificado!,
          fileName: _nomeCertificado!,
          senha: _senhaCertificado,
          empresaId: empresaId,
          uf: _uf,
          ambiente: _ambiente,
        );
      }

      if (_configId == null) {
        _mostrarErro('Nenhuma configuração fiscal ativa foi encontrada para a empresa/UF selecionada.');
        return;
      }

      await _service.salvarConfigFiscal({
        'id': _configId,
        'empresaId': empresaId,
        'uf': _uf,
        'ambiente': _ambiente,
        'idCsc': _idCsc,
        'csc': _csc,
        'serieNfce': int.tryParse(_serie) ?? 1,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuração fiscal salva com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } on NfceException catch (e) {
      _mostrarErro(e.message);
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirInutilizacao() {
    final sec = SecurityMatrix.current();
    if (!sec.canManageFiscalEvents) {
      _mostrarErro('A inutilização está disponível apenas para perfis FISCAL/ADMIN.');
      return;
    }

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      _mostrarErro('Empresa não identificada.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfceInutilizacaoScreen(
          empresaId: empresaId,
          uf: _uf,
          ambiente: _ambiente,
        ),
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Widget _buildEnvironmentBanner() {
    final isProducao = _ambiente == 'PRODUCAO';
    return NfceNoticeBanner(
      icon: isProducao ? Icons.verified_outlined : Icons.warning_amber_rounded,
      backgroundColor: isProducao ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3CD),
      borderColor: isProducao ? const Color(0xFFA5D6A7) : const Color(0xFFFFD54F),
      textColor: isProducao ? const Color(0xFF1B5E20) : const Color(0xFF7A4B00),
      title: isProducao ? 'Produção NFC-e' : 'Homologação NFC-e',
      message: isProducao
          ? 'Ambiente de produção ativo. Revise UF, CSC, certificado e prazo de cancelamento antes de operar o PDV.'
          : 'Ambiente de homologação ativo. Use este fluxo para testes, validações de inutilização e contingência.',
    );
  }

  Widget _buildSefazBanner() {
    if (_verificandoSefaz) {
      return NfceNoticeBanner(
        icon: Icons.sync,
        backgroundColor: GridColors.selectedRow,
        borderColor: const Color(0xFF90CAF9),
        textColor: const Color(0xFF0D47A1),
        title: 'Verificando SEFAZ',
        message: 'Consultando a saúde da SEFAZ para UF $_uf no ambiente $_ambiente.',
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_sefazHealth == null) {
      return NfceNoticeBanner(
        icon: Icons.network_check,
        backgroundColor: const Color(0xFFEAF4FF),
        borderColor: const Color(0xFFB6D4FE),
        textColor: const Color(0xFF0B5CAD),
        title: 'Saúde da SEFAZ',
        message: 'Valide certificado e conectividade do ambiente antes de emitir, cancelar ou regularizar vendas em contingência.',
        trailing: TextButton.icon(
          onPressed: _verificandoSefaz ? null : _verificarSefaz,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0B5CAD)),
          icon: const Icon(Icons.refresh),
          label: const Text('Verificar'),
        ),
      );
    }

    final online = _sefazHealth!.disponivel;
    return NfceNoticeBanner(
      icon: online ? Icons.check_circle_outline : Icons.error_outline,
      backgroundColor: online ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderColor: online ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
      textColor: online ? const Color(0xFF1B5E20) : GridColors.error,
      title: online ? 'SEFAZ disponível' : 'SEFAZ indisponível',
      message: _sefazHealth!.mensagem,
      trailing: TextButton.icon(
        onPressed: _verificandoSefaz ? null : _verificarSefaz,
        style: TextButton.styleFrom(
          foregroundColor: online ? const Color(0xFF1B5E20) : GridColors.error,
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Reverificar'),
      ),
    );
  }

  Widget _buildEventosCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eventos fiscais do épico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GridColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A inutilização já pode ser iniciada pelo app. Cancelamento fica disponível na NFC-e autorizada. Contingência local está pronta; o registro real em EPEC continua dependente do backend.',
              style: TextStyle(height: 1.35),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _abrirInutilizacao,
                  icon: const Icon(Icons.block),
                  label: const Text('Abrir inutilização'),
                ),
                OutlinedButton.icon(
                  onPressed: _verificandoSefaz ? null : _verificarSefaz,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Validar saúde da SEFAZ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração Fiscal NFC-e'),
        backgroundColor: GridColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnvironmentBanner(),
                  const SizedBox(height: 12),
                  _buildSefazBanner(),
                  const SizedBox(height: 12),
                  _buildEventosCard(),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Identificação'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: TenantContext.empresaId?.toString() ?? '—',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Empresa (ID)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.lock_outline, size: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _uf,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      border: OutlineInputBorder(),
                    ),
                    items: _ufs
                        .map((uf) => DropdownMenuItem(value: uf, child: Text(uf)))
                        .toList(),
                    onChanged: (v) => setState(() => _uf = v ?? 'SP'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _ambiente,
                    decoration: const InputDecoration(
                      labelText: 'Ambiente',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'HOMOLOGACAO', child: Text('Homologação')),
                      DropdownMenuItem(value: 'PRODUCAO', child: Text('Produção')),
                    ],
                    onChanged: (v) => setState(() => _ambiente = v ?? 'HOMOLOGACAO'),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'CSC (Código de Segurança do Contribuinte)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _idCsc,
                    decoration: InputDecoration(
                      labelText: 'ID CSC',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarCsc ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _mostrarCsc = !_mostrarCsc),
                      ),
                    ),
                    obscureText: !_mostrarCsc,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o ID CSC.' : null,
                    onSaved: (v) => _idCsc = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _csc,
                    decoration: const InputDecoration(
                      labelText: 'CSC',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: !_mostrarCsc,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o CSC.' : null,
                    onSaved: (v) => _csc = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Certificado Digital A1'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(_nomeCertificado ?? 'Selecionar arquivo .pfx / .p12'),
                    onPressed: _selecionarCertificado,
                  ),
                  if (_nomeCertificado != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Arquivo selecionado: $_nomeCertificado',
                      style: const TextStyle(color: GridColors.secondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: !_mostrarSenha,
                    decoration: InputDecoration(
                      labelText: 'Senha do certificado',
                      hintText: 'Nunca é armazenada em texto puro',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                      ),
                    ),
                    onChanged: (v) => _senhaCertificado = v,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'NFC-e'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _serie,
                    decoration: const InputDecoration(
                      labelText: 'Série NFC-e',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a série.' : null,
                    onSaved: (v) => _serie = v?.trim() ?? '001',
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: _verificandoSefaz
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check),
                        label: const Text('Verificar SEFAZ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _verificandoSefaz ? null : _verificarSefaz,
                      ),
                      OutlinedButton.icon(
                        onPressed: _abrirInutilizacao,
                        icon: const Icon(Icons.block),
                        label: const Text('Inutilização'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Salvar configuração'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _salvando ? null : _salvar,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: GridColors.secondary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}
