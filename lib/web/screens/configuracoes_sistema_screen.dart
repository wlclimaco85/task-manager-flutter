import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../services/tela_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

const _primary = Color(0xFF93070A);
const _green   = Color(0xFF005826);
const _bg      = Color(0xFFF5F5F5);
const _white   = Colors.white;
const _border  = Color(0xFFDDDDDD);

class ConfiguracoesSistemaScreen extends StatefulWidget {
  const ConfiguracoesSistemaScreen({super.key});
  @override
  State<ConfiguracoesSistemaScreen> createState() => _ConfiguracoesSistemaScreenState();
}

class _ConfiguracoesSistemaScreenState extends State<ConfiguracoesSistemaScreen> {
  final Map<String, dynamic> _resultados = {};
  final Map<String, bool> _loading = {};
  int? _seedEmpresaId;
  int _seedQuantidade = 20;
  int _seedMeses = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: _white, elevation: 2,
        title: const Row(children: [
          Icon(Icons.settings_applications, size: 20), SizedBox(width: 8),
          Text('Configuracoes do Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('Geracao de Telas', Icons.table_chart_outlined, [
            _actionCard(id: 'gerar_telas_full', title: 'Gerar Telas (Full Reset)',
              subtitle: 'Limpa e recria todas as telas. POST /api/telas/generate?forceUpdate=true&fullReset=true',
              icon: Icons.refresh, color: _primary, onTap: _gerarTelasFullReset),
            _actionCard(id: 'gerar_telas_update', title: 'Atualizar Telas (Force Update)',
              subtitle: 'Atualiza telas existentes. POST /api/telas/generate?forceUpdate=true',
              icon: Icons.update, color: Colors.orange.shade700, onTap: _gerarTelasUpdate),
            _actionCard(id: 'regenerar_telas', title: 'Regenerar Telas (Admin)',
              subtitle: 'Limpa controle de versao e regenera. POST /api/admin/regenerar-telas',
              icon: Icons.auto_fix_high, color: Colors.blue.shade700, onTap: _regenerarTelas),
            _actionCard(id: 'limpar_cache_telas', title: 'Limpar Cache de Telas (Local)',
              subtitle: 'Remove o cache local do Flutter. As telas serao recarregadas da API no proximo acesso.',
              icon: Icons.cleaning_services, color: Colors.teal.shade700, onTap: _limparCacheTelas),
          ]),
          const SizedBox(height: 20),
          _section('Dados de Teste (Mock)', Icons.data_array, [_seedCard()]),
          const SizedBox(height: 20),
          _section('Noticias', Icons.newspaper, [
            _actionCard(id: 'limpar_baixar_noticias', title: 'Limpar e Baixar Noticias',
              subtitle: 'Apaga todas as noticias e baixa novamente de todas as fontes',
              icon: Icons.refresh, color: Colors.blue.shade700, onTap: _limparEBaixarNoticias),
            _actionCard(id: 'apagar_noticias', title: 'Apagar Todas as Noticias',
              subtitle: 'Remove todas as noticias e imagens do banco (sem baixar novamente)',
              icon: Icons.delete_forever, color: Colors.red.shade700, onTap: _apagarNoticias),
          ]),
          const SizedBox(height: 20),
          _JobsSection(baseUrl: ApiLinks.baseUrl),
          const SizedBox(height: 20),
          _section('Banco de Dados', Icons.storage_outlined, [
            _actionCard(id: 'db_status', title: 'Status do Banco',
              subtitle: 'Verifica estado das colunas e sequencias. GET /api/admin/db-status',
              icon: Icons.health_and_safety_outlined, color: _green, onTap: _dbStatus),
            _actionCard(id: 'fix_db', title: 'Corrigir Banco (Fix DB)',
              subtitle: 'Aplica correcoes de colunas, FKs e sequencias. POST /api/admin/fix-db',
              icon: Icons.build_outlined, color: Colors.purple.shade700, onTap: _fixDb),
            _deleteEmpresaCard(),
          ]),
          const SizedBox(height: 20),
          if (_resultados.isNotEmpty) _buildResultados(),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _primary, size: 18), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
      ]),
      const SizedBox(height: 8),
      ...children,
    ]);
  }

  Widget _actionCard({required String id, required String title, required String subtitle,
      required IconData icon, required Color color, required VoidCallback onTap}) {
    final isLoading = _loading[id] == true;
    final resultado = _resultados[id];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
      child: ListTile(
        leading: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (resultado != null) ...[const SizedBox(height: 4), _resultadoCard(id, resultado)],
        ]),
        trailing: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
            : ElevatedButton(onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Executar')),
      ),
    );
  }

  Widget _seedCard() {
    final isLoading = _loading['seed'] == true;
    final resultado = _resultados['seed'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.science_outlined, color: Colors.teal, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gerar Dados Mock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Popula: Parceiros, Funcionarios, Pontos, NF-e, Chamados, Contas, Comunicados',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(initialValue: '',
            decoration: const InputDecoration(labelText: 'Empresa ID (vazio = criar nova)',
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => _seedEmpresaId = v.trim().isEmpty ? null : int.tryParse(v))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(initialValue: '$_seedQuantidade',
            decoration: const InputDecoration(labelText: 'Quantidade base',
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => _seedQuantidade = int.tryParse(v) ?? 20)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(initialValue: '$_seedMeses',
            decoration: const InputDecoration(labelText: 'Meses de historico',
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => _seedMeses = int.tryParse(v) ?? 6)),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _gerarSeed,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                : const Icon(Icons.play_arrow),
            label: Text(isLoading ? 'Gerando...' : 'Gerar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
        ]),
        if (resultado != null) ...[const SizedBox(height: 8), _resultadoCard('seed', resultado)],
      ])),
    );
  }

  Widget _buildResultados() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      const Text('Ultimos Resultados', style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
      const SizedBox(height: 8),
      ..._resultados.entries.map((e) => _resultadoCard(e.key, e.value)),
    ]);
  }

  Widget _resultadoCard(String id, dynamic resultado) {
    final texto = _resultadoTexto(resultado);
    final cor = _resultadoColor(resultado);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: cor.withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: cor.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            Icon(resultado is Map && resultado['error'] != null ? Icons.error_outline : Icons.check_circle_outline,
                color: cor, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(id, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cor))),
            IconButton(icon: const Icon(Icons.copy, size: 16), tooltip: 'Copiar', color: cor,
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: texto));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado'), duration: Duration(seconds: 2)));
              }),
          ]),
        ),
        Container(constraints: const BoxConstraints(maxHeight: 300), padding: const EdgeInsets.all(12),
          child: Scrollbar(
            child: SingleChildScrollView(child: SelectableText(texto,
              style: TextStyle(fontSize: 12, color: cor, fontFamily: 'monospace', height: 1.5))))),
      ]),
    );
  }

  Color _resultadoColor(dynamic r) {
    if (r is Map && (r['status'] == 'ok' || r['status'] == 'success')) return _green;
    if (r is Map && r['error'] != null) return _primary;
    if (r is String && r.toLowerCase().contains('erro')) return _primary;
    return Colors.blue.shade700;
  }

  String _resultadoTexto(dynamic r) {
    if (r is Map) { try { return const JsonEncoder.withIndent('  ').convert(r); } catch (_) { return r.toString(); } }
    return r.toString();
  }

  Future<void> _gerarTelasFullReset() async => _executar('gerar_telas_full', () async {
    final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/telas/generate', {'forceUpdate': true, 'forceRebuild': true, 'fullReset': true});
    // Limpa cache local de telas para forçar reload do banco
    await TelaService.clearAllTelaCache();
    return resp;
  });

  Future<void> _gerarTelasUpdate() async => _executar('gerar_telas_update', () async {
    final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/telas/generate', {'forceUpdate': true});
    await TelaService.clearAllTelaCache();
    return resp;
  });

  Future<void> _regenerarTelas() async => _executar('regenerar_telas', () async {
    final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/admin/regenerar-telas', {});
    await TelaService.clearAllTelaCache();
    return resp;
  });

  Future<void> _limparCacheTelas() async {
    setState(() => _loading['limpar_cache_telas'] = true);
    try {
      await TelaService.clearAllTelaCache();
      setState(() => _resultados['limpar_cache_telas'] = {'status': 'ok', 'message': 'Cache de telas limpo com sucesso. Recarregue a pagina (F5).'});
    } catch (e) {
      setState(() => _resultados['limpar_cache_telas'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['limpar_cache_telas'] = false);
    }
  }

  Future<void> _dbStatus() async {
    setState(() => _loading['db_status'] = true);
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/admin/db-status');
      setState(() => _resultados['db_status'] = resp.statusCode == 200
          ? jsonDecode(resp.body) : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) { setState(() => _resultados['db_status'] = {'error': e.toString()}); }
    finally { setState(() => _loading['db_status'] = false); }
  }

  Future<void> _fixDb() async => _executar('fix_db', () =>
      TenantContext.post('${ApiLinks.baseUrl}/api/admin/fix-db', {}));

  Future<void> _limparEBaixarNoticias() async => _executar('limpar_baixar_noticias', () =>
      TenantContext.post('${ApiLinks.baseUrl}/api/admin/jobs/noticias-limpar-e-baixar', {}));

  Future<void> _apagarNoticias() async {
    setState(() => _loading['apagar_noticias'] = true);
    try {
      final resp = await TenantContext.delete('${ApiLinks.baseUrl}/api/admin/jobs/noticias-apagar');
      setState(() => _resultados['apagar_noticias'] = resp.statusCode == 200
          ? jsonDecode(resp.body) : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) { setState(() => _resultados['apagar_noticias'] = {'error': e.toString()}); }
    finally { setState(() => _loading['apagar_noticias'] = false); }
  }

  // ── Apagar Empresa Mock ─────────────────────────────────────────────────
  int? _deleteEmpresaId;

  Widget _deleteEmpresaCard() {
    final isLoading = _loading['delete_empresa'] == true;
    final resultado = _resultados['delete_empresa'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.delete_forever, color: _primary, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Apagar Empresa Mock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Remove TODOS os dados de uma empresa (parceiros, logins, NF-e, chamados, contas, etc)',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'ID da Empresa para apagar',
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _deleteEmpresaId = int.tryParse(v)))),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isLoading || _deleteEmpresaId == null ? null : _deletarEmpresa,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                : const Icon(Icons.delete),
            label: Text(isLoading ? 'Apagando...' : 'Apagar'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
        ]),
        if (resultado != null) ...[const SizedBox(height: 8), _resultadoCard('delete_empresa', resultado)],
      ])),
    );
  }

  Future<void> _deletarEmpresa() async {
    if (_deleteEmpresaId == null) return;
    setState(() => _loading['delete_empresa'] = true);
    try {
      // Usa http.delete direto (sem TenantContext) para nao sobrescrever o empresaId
      final token = AuthUtility.userInfo?.token;
      final resp = await http.delete(
        Uri.parse('${ApiLinks.baseUrl}/api/admin/seed?empresaId=$_deleteEmpresaId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      setState(() => _resultados['delete_empresa'] = resp.statusCode == 200
          ? jsonDecode(resp.body) : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) { setState(() => _resultados['delete_empresa'] = {'error': e.toString()}); }
    finally { setState(() => _loading['delete_empresa'] = false); }
  }

  Future<void> _gerarSeed() async {
    setState(() => _loading['seed'] = true);
    try {
      final params = StringBuffer('quantidade=$_seedQuantidade&meses=$_seedMeses');
      if (_seedEmpresaId != null) params.write('&empresaId=$_seedEmpresaId');
      final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/admin/seed?$params', {});
      setState(() => _resultados['seed'] = resp.statusCode == 200
          ? jsonDecode(resp.body) : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) { setState(() => _resultados['seed'] = {'error': e.toString()}); }
    finally { setState(() => _loading['seed'] = false); }
  }

  Future<void> _executar(String id, Future<dynamic> Function() fn) async {
    setState(() => _loading[id] = true);
    try {
      final resp = await fn();
      dynamic body; try { body = jsonDecode(resp.body); } catch (_) { body = resp.body; }
      setState(() => _resultados[id] = resp.statusCode < 300 ? body : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) { setState(() => _resultados[id] = {'error': e.toString()}); }
    finally { setState(() => _loading[id] = false); }
  }
}

// ── Controle de Jobs ──────────────────────────────────────────────────────────
class _JobsSection extends StatefulWidget {
  final String baseUrl;
  const _JobsSection({required this.baseUrl});
  @override
  State<_JobsSection> createState() => _JobsSectionState();
}

class _JobsSectionState extends State<_JobsSection> {
  final Map<String, Map<String, dynamic>> _ultimaExec = {};
  bool _carregando = true;
  final Map<String, bool> _executando = {};
  final Map<String, List<Map<String, dynamic>>> _historicos = {};
  final Set<String> _historicoAberto = {};
  final Set<String> _erroAberto = {};

  static const _jobsMeta = [
    {'nome': 'ContabeisScraperJob',      'label': 'Scraping Contabeis.com.br',   'cron': 'Diario 08:00'},
    {'nome': 'ContabeisReprocessarImagens', 'label': 'Reprocessar Imagens Contabeis', 'cron': 'Manual'},
    {'nome': 'PontoVerificacaoJob',      'label': 'Verificacao de Pontos',        'cron': 'Diario 00:00'},
    {'nome': 'ObrigacaoFiscalJob',       'label': 'Obrigacoes Fiscais (diario)',   'cron': 'Diario 06:00'},
    {'nome': 'ObrigacaoFiscalJobMensal', 'label': 'Obrigacoes Fiscais (mensal)',   'cron': '1o dia do mes 08:00'},
    {'nome': 'ScrapeNewsInvesting',      'label': 'Scraping Investing.com',       'cron': 'A cada hora'},
    {'nome': 'ScrapeNewsAgroLink',       'label': 'Scraping AgroLink',            'cron': 'A cada hora'},
    {'nome': 'ScrapeNewsCNN',            'label': 'Scraping CNN Brasil',          'cron': 'A cada hora'},
    {'nome': 'ScrapeCotacaoESALQ',       'label': 'Cotacao ESALQ',                'cron': 'A cada hora'},
    {'nome': 'AtualizarCotacao',         'label': 'Atualizar Cotacoes',           'cron': 'Seg-Sex a cada hora'},
    {'nome': 'ScrapeCotacaoDollar',      'label': 'Cotacao Dolar',                'cron': 'Seg-Sex a cada hora'},
  ];

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/admin/jobs');
      if (resp.statusCode == 200) {
        final map = <String, Map<String, dynamic>>{};
        for (final j in (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>()) {
          map[j['jobNome'] as String] = j;
        }
        if (mounted) setState(() => _ultimaExec.addAll(map));
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _executar(String nome) async {
    setState(() => _executando[nome] = true);
    try {
      final resp = await TenantContext.post('${widget.baseUrl}/api/admin/jobs/$nome/executar', {});
      if (resp.statusCode < 300) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Job $nome iniciado'), backgroundColor: _green));
        await Future.delayed(const Duration(seconds: 3));
        await _carregar();
        if (_historicoAberto.contains(nome)) await _carregarHistorico(nome);
      } else {
        // Mostra dialog com textarea copiavel para o erro HTTP
        if (mounted) _mostrarErroDialog(context, 'Erro ao executar $nome', resp.body);
      }
    } catch (e) {
      if (mounted) _mostrarErroDialog(context, 'Erro ao executar $nome', e.toString());
    } finally {
      if (mounted) setState(() => _executando[nome] = false);
    }
  }

  void _mostrarErroDialog(BuildContext context, String titulo, String erro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.error_outline, color: _primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 14, color: _primary))),
        ]),
        content: SizedBox(
          width: 600,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Botao copiar
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copiar(context, erro),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copiar tudo', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _primary)),
            ),
            // Textarea scrollavel
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _primary.withValues(alpha: 0.25))),
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(erro,
                    style: const TextStyle(fontSize: 11, color: _primary,
                        fontFamily: 'monospace', height: 1.5))))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _carregarHistorico(String nome) async {
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/admin/jobs/$nome/historico');
      if (resp.statusCode == 200 && mounted)
        setState(() => _historicos[nome] = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  void _toggleHistorico(String nome) async {
    if (_historicoAberto.contains(nome)) { setState(() => _historicoAberto.remove(nome)); return; }
    await _carregarHistorico(nome);
    if (mounted) setState(() => _historicoAberto.add(nome));
  }

  void _toggleErro(String nome) => setState(() {
    if (_erroAberto.contains(nome)) _erroAberto.remove(nome); else _erroAberto.add(nome);
  });

  void _copiar(BuildContext ctx, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Copiado'), duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.schedule, color: _primary, size: 18), const SizedBox(width: 8),
        const Text('Controle de Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
        const Spacer(),
        if (_carregando)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
        else
          IconButton(icon: const Icon(Icons.refresh, size: 18), tooltip: 'Atualizar', onPressed: _carregar, color: _primary),
      ]),
      const SizedBox(height: 8),
      ..._jobsMeta.map((meta) => _jobCard(context, meta)),
    ]);
  }

  Widget _jobCard(BuildContext context, Map<String, dynamic> meta) {
    final nome = meta['nome'] as String;
    final label = meta['label'] as String;
    final cron = meta['cron'] as String;
    final ultima = _ultimaExec[nome];
    final status = ultima?['status'] as String?;
    final inicio = ultima?['inicio'] as String?;
    final duracaoMs = ultima?['duracaoMs'];
    final mensagem = ultima?['mensagem'] as String?;
    final erro = ultima?['erro'] as String?;
    final executando = _executando[nome] == true;
    final histAberto = _historicoAberto.contains(nome);
    final erroAberto = _erroAberto.contains(nome);

    Color cor = Colors.grey.shade400;
    IconData icone = Icons.radio_button_unchecked;
    if (status == 'SUCESSO')         { cor = _green;          icone = Icons.check_circle; }
    else if (status == 'ERRO')       { cor = _primary;        icone = Icons.error; }
    else if (status == 'EXECUTANDO') { cor = Colors.orange;   icone = Icons.sync; }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cor.withValues(alpha: 0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // linha principal
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icone, color: cor, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 11, color: Colors.grey), const SizedBox(width: 3),
                Text(cron, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 8),
                if (status != null)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold)))
                else
                  const Text('Nunca executado', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
              if (inicio != null)
                Text('Ultima: ${_fmt(inicio)}${duracaoMs != null ? '  -  ${duracaoMs}ms' : ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (status == 'SUCESSO' && mensagem != null && mensagem.isNotEmpty)
                Text(mensagem, style: const TextStyle(fontSize: 11, color: _green),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(histAberto ? Icons.expand_less : Icons.history, size: 18),
                tooltip: 'Historico', color: Colors.blue.shade600, onPressed: () => _toggleHistorico(nome)),
              executando
                  ? const SizedBox(width: 36, height: 36,
                      child: Padding(padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primary)))
                  : IconButton(icon: const Icon(Icons.play_circle_outline, size: 22),
                      tooltip: 'Executar agora', color: _green, onPressed: () => _executar(nome)),
            ]),
          ]),
        ),

        // ── Erro com textarea copiavel ────────────────────────────────────────
        if (status == 'ERRO' && erro != null && erro.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: InkWell(
              onTap: () => _toggleErro(nome),
              child: Row(children: [
                Icon(erroAberto ? Icons.expand_less : Icons.expand_more, size: 14, color: _primary),
                const SizedBox(width: 4),
                Text(erroAberto ? 'Ocultar erro' : 'Ver erro completo',
                    style: const TextStyle(fontSize: 11, color: _primary,
                        decoration: TextDecoration.underline)),
              ]),
            ),
          ),
          if (erroAberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _primary.withValues(alpha: 0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // header com botao copiar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 0),
                    child: Row(children: [
                      const Text('Erro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _copiar(context, erro),
                        icon: const Icon(Icons.copy, size: 13),
                        label: const Text('Copiar', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: _primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero)),
                    ]),
                  ),
                  // textarea scrollavel e selecionavel
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: SelectableText(erro,
                          style: const TextStyle(fontSize: 11, color: _primary,
                              fontFamily: 'monospace', height: 1.5))))),
                ]),
              ),
            ),
        ],

        // ── Historico expandido ───────────────────────────────────────────────
        if (histAberto) ...[
          const Divider(height: 1, indent: 12, endIndent: 12),
          Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Text('Ultimas execucoes',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          if (_historicos[nome] == null || _historicos[nome]!.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text('Nenhum historico disponivel.', style: TextStyle(fontSize: 11, color: Colors.grey)))
          else
            ..._historicos[nome]!.map((h) => _historicoRow(context, h)),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }

  Widget _historicoRow(BuildContext context, Map<String, dynamic> h) {
    final status = h['status'] as String? ?? '';
    final cor = status == 'SUCESSO' ? _green : status == 'ERRO' ? _primary : Colors.orange;
    final inicio = h['inicio'] as String?;
    final duracao = h['duracaoMs'];
    final msg = (h['mensagem'] ?? h['erro'] ?? '').toString();
    final erroCompleto = h['erro'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(status == 'SUCESSO' ? Icons.check_circle : status == 'ERRO' ? Icons.cancel : Icons.sync,
              size: 12, color: cor),
          const SizedBox(width: 6),
          Text(inicio != null ? _fmt(inicio) : '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
            child: Text(status, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold))),
          if (duracao != null) ...[
            const SizedBox(width: 6),
            Text('${duracao}ms', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
          if (msg.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(child: Text(msg, style: TextStyle(fontSize: 10, color: cor),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          if (status == 'ERRO' && erroCompleto != null)
            IconButton(icon: const Icon(Icons.copy, size: 12), tooltip: 'Copiar erro',
              color: _primary, padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => _copiar(context, erroCompleto)),
        ]),
        // textarea do erro no historico
        if (status == 'ERRO' && erroCompleto != null)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 2, bottom: 4),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _primary.withValues(alpha: 0.2))),
              child: Scrollbar(child: SingleChildScrollView(
                child: SelectableText(erroCompleto,
                  style: const TextStyle(fontSize: 10, color: _primary,
                      fontFamily: 'monospace', height: 1.4)))))),
      ]),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}

