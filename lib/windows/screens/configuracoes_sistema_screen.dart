import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../services/tela_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/searchable_dropdown.dart';

const _primary = GridColors.primary;
const _green   = GridColors.secondary;
const _bg      = GridColors.pageBackground;
const _white   = GridColors.textPrimary;
const _border  = GridColors.borderSubtle;

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
          Text(GridTexts.systemSettingsTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section(GridTexts.screenGeneration, Icons.table_chart_outlined, [
            _actionCard(id: 'gerar_telas_full', title: GridTexts.generateScreensFullReset,
              subtitle: GridTexts.generateScreensFullResetDesc,
              icon: Icons.refresh, color: _primary, onTap: _gerarTelasFullReset),
            _actionCard(id: 'gerar_telas_update', title: GridTexts.updateScreensForce,
              subtitle: GridTexts.updateScreensForceDesc,
              icon: Icons.update, color: GridColors.warningDark, onTap: _gerarTelasUpdate),
            _actionCard(id: 'regenerar_telas', title: GridTexts.regenerateScreensAdmin,
              subtitle: GridTexts.regenerateScreensAdminDesc,
              icon: Icons.auto_fix_high, color: GridColors.info, onTap: _regenerarTelas),
            _actionCard(id: 'limpar_cache_telas', title: GridTexts.clearScreensCache,
              subtitle: GridTexts.clearScreensCacheDesc,
              icon: Icons.cleaning_services, color: GridColors.secondaryDark, onTap: _limparCacheTelas),
          ]),
          const SizedBox(height: 20),
          _section(GridTexts.mockTestData, Icons.data_array, [_seedCard()]),
          const SizedBox(height: 20),
          _section(GridTexts.news, Icons.newspaper, [
            _actionCard(id: 'limpar_baixar_noticias', title: GridTexts.clearAndDownloadNews,
              subtitle: GridTexts.clearAndDownloadNewsDesc,
              icon: Icons.refresh, color: GridColors.info, onTap: _limparEBaixarNoticias),
            _actionCard(id: 'apagar_noticias', title: GridTexts.deleteAllNews,
              subtitle: GridTexts.deleteAllNewsDesc,
              icon: Icons.delete_forever, color: GridColors.error, onTap: _apagarNoticias),
          ]),
          const SizedBox(height: 20),
          _JobsSection(baseUrl: ApiLinks.baseUrl),
          const SizedBox(height: 20),
          _section(GridTexts.database, Icons.storage_outlined, [
            _actionCard(id: 'db_status', title: GridTexts.databaseStatus,
              subtitle: GridTexts.databaseStatusDesc,
              icon: Icons.health_and_safety_outlined, color: _green, onTap: _dbStatus),
            _actionCard(id: 'fix_db', title: GridTexts.fixDatabase,
              subtitle: GridTexts.fixDatabaseDesc,
              icon: Icons.build_outlined, color: GridColors.statusClosed, onTap: _fixDb),
            _actionCard(id: 'reset_database', title: GridTexts.resetDatabase,
              subtitle: GridTexts.resetDatabaseDesc,
              icon: Icons.delete_sweep, color: GridColors.errorDark, onTap: _confirmResetDatabase),
            _deleteEmpresaCard(),
          ]),
          const SizedBox(height: 20),
          _ImportacaoSection(baseUrl: ApiLinks.baseUrl),
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
          Text(subtitle, style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
          if (resultado != null) ...[const SizedBox(height: 4), _resultadoCard(id, resultado)],
        ]),
        trailing: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
            : ElevatedButton(onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12)),
                child: const Text(GridTexts.execute)),
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
            decoration: BoxDecoration(color: GridColors.secondaryDark.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.science_outlined, color: GridColors.secondaryDark, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GridTexts.generateMockData, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(GridTexts.generateMockDataDesc,
                style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(initialValue: '',
            decoration: const InputDecoration(labelText: GridTexts.companyIdOptionalCreate,
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => _seedEmpresaId = v.trim().isEmpty ? null : int.tryParse(v))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(initialValue: '$_seedQuantidade',
            decoration: const InputDecoration(labelText: GridTexts.baseQuantity,
              border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            onChanged: (v) => _seedQuantidade = int.tryParse(v) ?? 20)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(initialValue: '$_seedMeses',
            decoration: const InputDecoration(labelText: GridTexts.historyMonths,
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
            label: Text(isLoading ? GridTexts.generating : GridTexts.generate),
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.secondaryDark, foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
        ]),
        if (resultado != null) ...[const SizedBox(height: 8), _resultadoCard('seed', resultado)],
      ])),
    );
  }

  Widget _buildResultados() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      const Text(GridTexts.latestResults, style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
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
            IconButton(icon: const Icon(Icons.copy, size: 16), tooltip: GridTexts.copy, color: cor,
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: texto));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(GridTexts.copied), duration: Duration(seconds: 2)));
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
    return GridColors.info;
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
            Text(GridTexts.deleteMockCompany, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(GridTexts.deleteMockCompanyDesc,
                style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            decoration: const InputDecoration(
              labelText: GridTexts.companyIdToDelete,
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
            label: Text(isLoading ? GridTexts.deleting : GridTexts.delete),
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

  Future<void> _confirmResetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: GridColors.error, size: 24),
          SizedBox(width: 8),
          Text(GridTexts.resetDatabase, style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(GridTexts.irreversibleWarning, style: TextStyle(color: GridColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 12),
          Text(GridTexts.permanentDeleteWarning),
          SizedBox(height: 8),
          Text(GridTexts.permanentDeleteItemCompanies),
          Text(GridTexts.permanentDeleteItemFinance),
          Text(GridTexts.permanentDeleteItemDocs),
          Text(GridTexts.permanentDeleteItemAccounting),
          Text(GridTexts.permanentDeleteItemOthers),
          SizedBox(height: 12),
          Text(GridTexts.controlTablesPreserved),
          SizedBox(height: 12),
          Text(GridTexts.typeResetToConfirm),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.error, foregroundColor: GridColors.textPrimary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(GridTexts.confirmReset),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _executar('reset_database', () =>
        TenantContext.post('${ApiLinks.baseUrl}/api/admin/reset-database', {}));
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(GridTexts.jobStarted(nome)), backgroundColor: _green));
        }
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
                label: const Text(GridTexts.copyAll, style: TextStyle(fontSize: 12)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(GridTexts.close)),
        ],
      ),
    );
  }

  Future<void> _carregarHistorico(String nome) async {
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/admin/jobs/$nome/historico');
      if (resp.statusCode == 200 && mounted) {
        setState(() => _historicos[nome] = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  void _toggleHistorico(String nome) async {
    if (_historicoAberto.contains(nome)) { setState(() => _historicoAberto.remove(nome)); return; }
    await _carregarHistorico(nome);
    if (mounted) setState(() => _historicoAberto.add(nome));
  }

  void _toggleErro(String nome) => setState(() {
    if (_erroAberto.contains(nome)) {
      _erroAberto.remove(nome);
    } else {
      _erroAberto.add(nome);
    }
  });

  void _copiar(BuildContext ctx, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text(GridTexts.copied), duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.schedule, color: _primary, size: 18), const SizedBox(width: 8),
        const Text(GridTexts.jobsControlTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
        const Spacer(),
        if (_carregando)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
        else
          IconButton(icon: const Icon(Icons.refresh, size: 18), tooltip: GridTexts.refresh, onPressed: _carregar, color: _primary),
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

    Color cor = GridColors.disabledBackground;
    IconData icone = Icons.radio_button_unchecked;
    if (status == 'SUCESSO')         { cor = _green;          icone = Icons.check_circle; }
    else if (status == 'ERRO')       { cor = _primary;        icone = Icons.error; }
    else if (status == 'EXECUTANDO') { cor = GridColors.warning;   icone = Icons.sync; }

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
                const Icon(Icons.timer_outlined, size: 11, color: GridColors.textMuted), const SizedBox(width: 3),
                Text(cron, style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
                const SizedBox(width: 8),
                if (status != null)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold)))
                else
                  const Text(GridTexts.neverExecuted, style: TextStyle(fontSize: 10, color: GridColors.textMuted)),
              ]),
              if (inicio != null)
                Text(GridTexts.lastExecution(_fmt(inicio), duracaoMs),
                    style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
              if (status == 'SUCESSO' && mensagem != null && mensagem.isNotEmpty)
                Text(mensagem, style: const TextStyle(fontSize: 11, color: _green),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(histAberto ? Icons.expand_less : Icons.history, size: 18),
                tooltip: GridTexts.jobHistoryTooltip, color: GridColors.info, onPressed: () => _toggleHistorico(nome)),
              executando
                  ? const SizedBox(width: 36, height: 36,
                      child: Padding(padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primary)))
                  : IconButton(icon: const Icon(Icons.play_circle_outline, size: 22),
                      tooltip: GridTexts.executeNow, color: _green, onPressed: () => _executar(nome)),
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
                      const Text(GridTexts.errorTitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _copiar(context, erro),
                        icon: const Icon(Icons.copy, size: 13),
                        label: const Text(GridTexts.copy, style: TextStyle(fontSize: 11)),
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
            child: const Text(GridTexts.latestExecutions,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GridColors.textMuted))),
          if (_historicos[nome] == null || _historicos[nome]!.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(GridTexts.noHistoryAvailable, style: TextStyle(fontSize: 11, color: GridColors.textMuted)))
          else
            ..._historicos[nome]!.map((h) => _historicoRow(context, h)),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }

  Widget _historicoRow(BuildContext context, Map<String, dynamic> h) {
    final status = h['status'] as String? ?? '';
    final cor = status == 'SUCESSO' ? _green : status == 'ERRO' ? _primary : GridColors.warning;
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
          Text(inicio != null ? _fmt(inicio) : '-', style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
            child: Text(status, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold))),
          if (duracao != null) ...[
            const SizedBox(width: 6),
            Text('${duracao}ms', style: const TextStyle(fontSize: 10, color: GridColors.textMuted)),
          ],
          if (msg.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(child: Text(msg, style: TextStyle(fontSize: 10, color: cor),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          if (status == 'ERRO' && erroCompleto != null)
            IconButton(icon: const Icon(Icons.copy, size: 12), tooltip: GridTexts.copyError,
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

// ── Importacao CSV ────────────────────────────────────────────────────────────
class _ImportacaoSection extends StatefulWidget {
  final String baseUrl;
  const _ImportacaoSection({required this.baseUrl});
  @override
  State<_ImportacaoSection> createState() => _ImportacaoSectionState();
}

class _ImportacaoSectionState extends State<_ImportacaoSection> {
  // ── Empresa / Parceiro selecionados ───────────────────────────────────────
  // Listas carregadas da API
  List<Map<String, dynamic>> _empresas  = [];
  List<Map<String, dynamic>> _parceiros = [];
  bool _loadingEmpresas  = false;
  bool _loadingParceiros = false;

  // Valores selecionados nos dropdowns (null = usar o do TenantContext)
  String? _empresaIdSelecionada;
  String? _parceiroIdSelecionado;

  // ── Estado Contas a Pagar ─────────────────────────────────────────────────
  PlatformFile? _arquivoCP;
  bool _importandoCP = false;
  bool _upsertCP = false;
  Map<String, dynamic>? _resultadoCP;
  bool _mapeamentoExpandidoCP = false;
  final Map<String, TextEditingController> _ctrlCP = {
    'colDescricao':      TextEditingController(text: 'historico'),
    'colValor':          TextEditingController(text: 'vlr_do_desdobramento'),
    'colVencimento':     TextEditingController(text: 'dt_vencimento'),
    'colParceiro':       TextEditingController(text: 'parceiro'),
    'colFormaPagamento': TextEditingController(text: 'forma_pagamento'),
    'colStatus':         TextEditingController(text: 'status'),
    'colNumeroNota':     TextEditingController(text: 'nro_nota'),
    'colObservacao':     TextEditingController(text: 'observacao'),
    'colDataBaixa':      TextEditingController(text: ''),
    'colValorBaixa':     TextEditingController(text: ''),
    'colValorMulta':     TextEditingController(text: ''),
    'colValorJuros':     TextEditingController(text: ''),
    'colValorDesconto':  TextEditingController(text: ''),
    'colParceiroDev':    TextEditingController(text: ''),
    'colContaBancaria':  TextEditingController(text: ''),
  };

  // ── Estado Contas a Receber ───────────────────────────────────────────────
  PlatformFile? _arquivoCR;
  bool _importandoCR = false;
  bool _upsertCR = false;
  Map<String, dynamic>? _resultadoCR;
  bool _mapeamentoExpandidoCR = false;
  final Map<String, TextEditingController> _ctrlCR = {
    'colDescricao':      TextEditingController(text: 'historico'),
    'colValor':          TextEditingController(text: 'vlr_do_desdobramento'),
    'colVencimento':     TextEditingController(text: 'dt_vencimento'),
    'colParceiro':       TextEditingController(text: 'parceiro'),
    'colFormaPagamento': TextEditingController(text: 'forma_pagamento'),
    'colStatus':         TextEditingController(text: 'status'),
    'colNumeroNota':     TextEditingController(text: 'nro_nota'),
    'colObservacao':     TextEditingController(text: 'observacao'),
    'colDataBaixa':      TextEditingController(text: ''),
    'colValorBaixa':     TextEditingController(text: ''),
    'colValorMulta':     TextEditingController(text: ''),
    'colValorJuros':     TextEditingController(text: ''),
    'colValorDesconto':  TextEditingController(text: ''),
    'colParceiroDev':    TextEditingController(text: ''),
    'colContaBancaria':  TextEditingController(text: ''),
  };

  static const _camposMapeamento = [
    {'key': 'colDescricao',      'label': 'Coluna Descricao *'},
    {'key': 'colValor',          'label': 'Coluna Valor *'},
    {'key': 'colVencimento',     'label': 'Coluna Vencimento *'},
    {'key': 'colParceiro',       'label': 'Coluna Parceiro'},
    {'key': 'colFormaPagamento', 'label': 'Coluna Forma Pagamento'},
    {'key': 'colStatus',         'label': 'Coluna Status'},
    {'key': 'colNumeroNota',     'label': 'Coluna Numero Nota'},
    {'key': 'colObservacao',     'label': 'Coluna Observacao'},
    {'key': 'colDataBaixa',      'label': 'Coluna Data Baixa'},
    {'key': 'colValorBaixa',     'label': 'Coluna Valor Baixa'},
    {'key': 'colValorMulta',     'label': 'Coluna Valor Multa'},
    {'key': 'colValorJuros',     'label': 'Coluna Valor Juros'},
    {'key': 'colValorDesconto',  'label': 'Coluna Valor Desconto'},
    {'key': 'colParceiroDev',    'label': 'Coluna Parceiro Dev'},
    {'key': 'colContaBancaria',  'label': 'Coluna Conta Bancaria'},
  ];

  @override
  void initState() {
    super.initState();
    // Sempre carrega empresas — mesmo quando fixada pelo login,
    // precisamos da lista para resolver o nome a exibir no campo bloqueado.
    _carregarEmpresas();
    // Sempre carrega parceiros filtrados pela empresa (do contexto ou aguarda seleção)
    if (TenantContext.hasEmpresa) {
      _carregarParceiros(TenantContext.empresaId.toString());
    }
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _loadingEmpresas = true);
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/empresa');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body['data'] is List) {
          lista = body['data'] as List;
        }
        if (mounted) {
          setState(() => _empresas = lista
            .map<Map<String, dynamic>>((e) => {'id': e['id'].toString(), 'nome': e['nome']?.toString() ?? ''})
            .toList());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingEmpresas = false);
  }

  Future<void> _carregarParceiros([String? empresaId]) async {
    setState(() { _loadingParceiros = true; _parceiros = []; _parceiroIdSelecionado = null; });
    try {
      // Usa empresa do contexto, ou a passada como parâmetro, ou carrega todos
      final empId = empresaId
          ?? (TenantContext.hasEmpresa ? TenantContext.empresaId.toString() : null);

      final url = empId != null
          ? '${widget.baseUrl}/api/parceiro/empresa/$empId'
          : '${widget.baseUrl}/api/parceiro';

      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        // /empresa/{id} retorna body['data']['dados'] ou body['data'] direto
        if (body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body['data'] is List) {
          lista = body['data'] as List;
        } else if (body is List) {
          lista = body;
        }
        if (mounted) {
          setState(() => _parceiros = lista
            .map<Map<String, dynamic>>((e) => {'id': e['id'].toString(), 'nome': e['nome']?.toString() ?? ''})
            .toList());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingParceiros = false);
  }

  @override
  void dispose() {
    for (final c in _ctrlCP.values) {
      c.dispose();
    }
    for (final c in _ctrlCR.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Colunas detectadas no CSV após seleção
  List<String> _colunasCP = [];
  List<String> _colunasCR = [];

  Future<void> _selecionarArquivo(bool isCP) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // Detecta colunas localmente (fallback rápido)
      final colunasLocal = _detectarColunas(file.bytes);
      setState(() {
        if (isCP) {
          _arquivoCP = file;
          _resultadoCP = null;
          _colunasCP = colunasLocal;
          _autoMapear(_ctrlCP, colunasLocal);
        } else {
          _arquivoCR = file;
          _resultadoCR = null;
          _colunasCR = colunasLocal;
          _autoMapear(_ctrlCR, colunasLocal);
        }
      });

      // Chama o preview da API para detecção precisa (suporta tab, BOM, etc.)
      try {
        final resp = await TenantContext.postMultipart(
          '${widget.baseUrl}/api/importacao/preview',
          fileBytes: file.bytes!,
          fileName: file.name,
          fileField: 'arquivo',
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          final colunas = (body['colunas'] as List?)?.cast<String>() ?? colunasLocal;
          if (mounted) {
            setState(() {
            if (isCP) {
              _colunasCP = colunas;
              _autoMapear(_ctrlCP, colunas);
            } else {
              _colunasCR = colunas;
              _autoMapear(_ctrlCR, colunas);
            }
          });
          }
        }
      } catch (_) {
        // Mantém detecção local se API falhar
      }
    }
  }

  /// Lê o cabeçalho do CSV e retorna os nomes das colunas
  List<String> _detectarColunas(List<int>? bytes) {
    if (bytes == null) return [];
    try {
      final texto = String.fromCharCodes(bytes).replaceAll('\uFEFF', '');
      final primeiraLinha = texto.split(RegExp(r'\r?\n')).first;
      final sep = primeiraLinha.contains(';') ? ';' : ',';
      return primeiraLinha.split(sep).map((c) => c.trim().replaceAll('"', '')).where((c) => c.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  /// Normaliza string igual ao backend: minúsculo, sem acentos, underscore
  String _normalizar(String s) {
    const acentos = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const semAcento = 'aaaaaaeeeeiiiioooooouuuuyyñcAAAAAAEEEEIIIIOOOOOUUUUYNC';
    var r = s.toLowerCase();
    for (var i = 0; i < acentos.length; i++) {
      r = r.replaceAll(acentos[i], semAcento[i]);
    }
    return r.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Tenta mapear automaticamente as colunas detectadas para os campos conhecidos
  void _autoMapear(Map<String, TextEditingController> ctrl, List<String> colunas) {
    // Mapa de sinônimos: campo → lista de possíveis nomes normalizados
    final sinonimos = <String, List<String>>{
      'colDescricao':      ['descricao', 'description', 'historico', 'lancamento', 'titulo', 'nome', 'descricao_tipo_de_titulo', 'descricao_natureza'],
      'colValor':          ['valor', 'value', 'montante', 'total', 'vlr', 'vl', 'valor_liquido', 'vlr_do_desdobramento'],
      'colVencimento':     ['vencimento', 'data_vencimento', 'dt_vencimento', 'datavencimento', 'due_date', 'venc', 'dt_prevista_p_baixa'],
      'colParceiro':       ['parceiro', 'fornecedor', 'cliente', 'partner', 'vendor', 'supplier', 'nome_parceiro_parceiro', 'nome_fantasia_empresa'],
      'colFormaPagamento': ['forma_pagamento', 'formapagamento', 'payment_method', 'pagamento', 'forma', 'tipo_operacao', 'descricao_tipo_de_operacao'],
      'colStatus':         ['status', 'situacao', 'state', 'tipo_de_movimento'],
      'colNumeroNota':     ['numero_nota', 'numeronota', 'nota', 'nf', 'nfe', 'invoice', 'documento', 'nro_nota', 'nro_duplicata'],
      'colObservacao':     ['observacao', 'obs', 'observation', 'nota', 'comentario', 'observacao_padrao'],
      'colDataBaixa':      ['data_baixa', 'dt_baixa', 'databaixa', 'dtbaixa', 'data_pagamento', 'dt_pagamento', 'data_recebimento', 'dt_recebimento', 'data_quitacao'],
      'colValorBaixa':     ['valor_baixa', 'vlr_baixa', 'valor_pago', 'vlr_pago', 'valor_recebido', 'vlr_recebido', 'valor_liquido', 'vlr_liquido'],
      'colValorMulta':     ['valor_multa', 'vlr_multa', 'multa', 'vl_multa'],
      'colValorJuros':     ['valor_juros', 'vlr_juros', 'juros', 'vl_juros', 'juro'],
      'colValorDesconto':  ['valor_desconto', 'vlr_desconto', 'desconto', 'vl_desconto'],
      'colParceiroDev':    ['parceiro_dev', 'parceiro_devedor', 'devedor', 'parceiro_rec', 'recebedor', 'nome_parceiro_dev'],
      'colContaBancaria':  ['conta_bancaria', 'conta', 'banco', 'bank_account', 'conta_id', 'nome_conta'],
    };

    final colunasNorm = colunas.map((c) => _normalizar(c)).toList();

    for (final entry in sinonimos.entries) {
      final campo = entry.key;
      final candidatos = entry.value;
      for (final candidato in candidatos) {
        final idx = colunasNorm.indexWhere((cn) => cn == candidato || cn.contains(candidato) || candidato.contains(cn));
        if (idx >= 0) {
          ctrl[campo]?.text = colunas[idx]; // usa o nome original da coluna
          break;
        }
      }
    }
  }

  Future<void> _importar(bool isCP) async {
    final arquivo = isCP ? _arquivoCP : _arquivoCR;
    if (arquivo == null || arquivo.bytes == null) return;

    // empId vem do TenantContext (injetado automaticamente por applyToUrl),
    // ou do dropdown quando o usuário não tem empresa no contexto.
    final empIdCtx  = TenantContext.hasEmpresa  ? TenantContext.empresaId?.toString()  : _empresaIdSelecionada;
    final parIdCtx  = TenantContext.hasParceiro ? TenantContext.parceiroId?.toString() : _parceiroIdSelecionado;

    if (empIdCtx == null) {
      _mostrarErro('Selecione uma empresa antes de importar.');
      return;
    }

    setState(() { if (isCP) {
      _importandoCP = true;
    } else {
      _importandoCR = true;
    } });

    try {
      final ctrl     = isCP ? _ctrlCP : _ctrlCR;
      final endpoint = isCP ? 'conta-pagar' : 'conta-receber';

      // Monta URL com todos os parâmetros necessários.
      // empId: se não está no TenantContext (applyToUrl não injeta), passa manualmente.
      // parId: SEMPRE passa quando disponível — applyToUrl passa parceiroId/parcId mas
      //         o endpoint de importação usa parId para vincular empresa/parceiro ao registro.
      var url = '${widget.baseUrl}/api/importacao/$endpoint';
      final upsert = isCP ? _upsertCP : _upsertCR;
      {
        final uri = Uri.parse(url);
        final params = Map<String, String>.from(uri.queryParameters);
        if (!TenantContext.hasEmpresa) params['empId'] = empIdCtx;
        // parId: vincula parceiro ao registro importado (independente do TenantContext)
        if (parIdCtx != null) params['parId'] = parIdCtx;
        if (upsert) params['upsert'] = 'true';
        url = uri.replace(queryParameters: params).toString();
      }

      // Apenas campos de mapeamento de colunas vão no form-data
      final fields = <String, String>{};
      for (final entry in ctrl.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          fields[entry.key] = entry.value.text.trim();
        }
      }

      final resp = await TenantContext.postMultipart(
        url,
        fileBytes: arquivo.bytes!,
        fileName: arquivo.name,
        fileField: 'arquivo',
        fields: fields,
      );

      dynamic body;
      try { body = jsonDecode(resp.body); } catch (_) { body = {'error': resp.body}; }

      setState(() {
        if (isCP) {
          _resultadoCP = resp.statusCode < 300 ? body : {'error': 'HTTP ${resp.statusCode}: ${resp.body}'};
        } else {
          _resultadoCR = resp.statusCode < 300 ? body : {'error': 'HTTP ${resp.statusCode}: ${resp.body}'};
        }

        // Se 100% ignorado, abre o mapeamento automaticamente para o usuário corrigir
        if (resp.statusCode < 300 && body is Map) {
          final s = body['sucesso'] as int? ?? 0;
          final e = body['erros']   as int? ?? 0;
          final ig = body['ignorados'] as int? ?? 0;
          if (s == 0 && e == 0 && ig > 0) {
            if (isCP) {
              _mapeamentoExpandidoCP = true;
            } else {
              _mapeamentoExpandidoCR = true;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        if (isCP) {
          _resultadoCP = {'error': e.toString()};
        } else {
          _resultadoCR = {'error': e.toString()};
        }
      });
    } finally {
      setState(() { if (isCP) {
        _importandoCP = false;
      } else {
        _importandoCR = false;
      } });
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _primary));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.upload_file, color: _primary, size: 18), SizedBox(width: 8),
        Text(GridTexts.csvImportTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
      ]),
      const SizedBox(height: 10),

      // ── Seleção de Empresa e Parceiro ─────────────────────────────────
      Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(GridTexts.importDestination,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              GridTexts.importDestinationDesc,
              style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
            const SizedBox(height: 12),
            Row(children: [
              // ── Empresa ──────────────────────────────────────────────
              Expanded(child: _buildDropdownEmpresa()),
              const SizedBox(width: 12),
              // ── Parceiro ─────────────────────────────────────────────
              Expanded(child: _buildDropdownParceiro()),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      _importCard(
        isCP: true,
        titulo: GridTexts.importAccountsPayable,
        subtitulo: GridTexts.importAccountsPayableDesc,
        arquivo: _arquivoCP,
        importando: _importandoCP,
        upsert: _upsertCP,
        resultado: _resultadoCP,
        mapeamentoExpandido: _mapeamentoExpandidoCP,
        onToggleMapeamento: () => setState(() => _mapeamentoExpandidoCP = !_mapeamentoExpandidoCP),
        onToggleUpsert: () => setState(() => _upsertCP = !_upsertCP),
        ctrl: _ctrlCP,
      ),
      const SizedBox(height: 12),
      _importCard(
        isCP: false,
        titulo: GridTexts.importAccountsReceivable,
        subtitulo: GridTexts.importAccountsReceivableDesc,
        arquivo: _arquivoCR,
        importando: _importandoCR,
        upsert: _upsertCR,
        resultado: _resultadoCR,
        mapeamentoExpandido: _mapeamentoExpandidoCR,
        onToggleMapeamento: () => setState(() => _mapeamentoExpandidoCR = !_mapeamentoExpandidoCR),
        onToggleUpsert: () => setState(() => _upsertCR = !_upsertCR),
        ctrl: _ctrlCR,
      ),
    ]);
  }

  // ── Dropdown Empresa ──────────────────────────────────────────────────────
  Widget _buildDropdownEmpresa() {
    final fixo = TenantContext.hasEmpresa;
    final empresaIdCtx = TenantContext.empresaId?.toString();

    // Label do valor fixo (do contexto)
    String? labelFixo;
    if (fixo && empresaIdCtx != null) {
      // Tenta achar o nome na lista carregada; se não tiver, mostra o ID
      final found = _empresas.where((e) => e['id'] == empresaIdCtx).firstOrNull;
      labelFixo = found?['nome'] as String? ?? GridTexts.companyById(empresaIdCtx);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.business, size: 14, color: GridColors.textMuted),
        const SizedBox(width: 4),
        const Text(GridTexts.companyLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (fixo) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)),
            child: const Text(GridTexts.fromLogin, style: TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.bold))),
        ],
      ]),
      const SizedBox(height: 4),
      if (fixo)
        // Campo desabilitado mostrando a empresa do login
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: GridColors.textMuted.withValues(alpha: 0.10),
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: GridColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(labelFixo ?? GridTexts.companyFromLogin,
              style: const TextStyle(fontSize: 13, color: GridColors.textMuted))),
          ]),
        )
      else
        // Dropdown editável
        _loadingEmpresas
            ? const SizedBox(height: 44,
                child: Center(child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary))))
            : SearchableDropdownField(
                label: GridTexts.companyLabel,
                value: _empresaIdSelecionada,
                items: _empresas,
                valueField: 'id',
                displayField: 'nome',
                hintText: GridTexts.selectCompany,
                onChanged: (v) {
                  setState(() => _empresaIdSelecionada = v);
                  // Recarrega parceiros filtrados pela empresa selecionada
                  if (!TenantContext.hasParceiro && v != null) {
                    _carregarParceiros(v);
                  }
                },
              ),
    ]);
  }

  // ── Dropdown Parceiro ─────────────────────────────────────────────────────
  Widget _buildDropdownParceiro() {
    final fixo = TenantContext.hasParceiro;
    final parceiroIdCtx = TenantContext.parceiroId?.toString();

    String? labelFixo;
    if (fixo && parceiroIdCtx != null) {
      final found = _parceiros.where((e) => e['id'] == parceiroIdCtx).firstOrNull;
      labelFixo = found?['nome'] as String? ?? GridTexts.partnerById(parceiroIdCtx);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.person_outline, size: 14, color: GridColors.textMuted),
        const SizedBox(width: 4),
        const Text(GridTexts.partnerOptional, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (fixo) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)),
            child: const Text(GridTexts.fromLogin, style: TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.bold))),
        ],
      ]),
      const SizedBox(height: 4),
      if (fixo)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: GridColors.textMuted.withValues(alpha: 0.10),
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: GridColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(labelFixo ?? GridTexts.partnerFromLogin,
              style: const TextStyle(fontSize: 13, color: GridColors.textMuted))),
          ]),
        )
      else
        _loadingParceiros
            ? const SizedBox(height: 44,
                child: Center(child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary))))
            : SearchableDropdownField(
                label: GridTexts.partnerLabel,
                value: _parceiroIdSelecionado,
                items: _parceiros,
                valueField: 'id',
                displayField: 'nome',
                hintText: GridTexts.noneOptional,
                nullable: true,
                nullLabel: GridTexts.noneOptional,
                onChanged: (v) => setState(() => _parceiroIdSelecionado = v),
              ),
    ]);
  }

  Widget _importCard({
    required bool isCP,
    required String titulo,
    required String subtitulo,
    required PlatformFile? arquivo,
    required bool importando,
    required bool upsert,
    required Map<String, dynamic>? resultado,
    required bool mapeamentoExpandido,
    required VoidCallback onToggleMapeamento,
    required VoidCallback onToggleUpsert,
    required Map<String, TextEditingController> ctrl,
  }) {
    final cor = isCP ? Colors.indigo.shade700 : Colors.teal.shade700;
    final icone = isCP ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cor.withValues(alpha: 0.35))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icone, color: cor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitulo, style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 14),

          // ── Seleção de arquivo ─────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(6),
                  color: GridColors.textMuted.withValues(alpha: 0.06)),
                child: Row(children: [
                  const Icon(Icons.attach_file, size: 16, color: GridColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    arquivo != null ? arquivo.name : GridTexts.noFileSelected,
                    style: TextStyle(fontSize: 13,
                      color: arquivo != null ? Colors.black87 : GridColors.textMuted),
                    overflow: TextOverflow.ellipsis)),
                  if (arquivo != null) ...[
                    const SizedBox(width: 8),
                    Text('${(arquivo.size / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
                  ],
                ]),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: importando ? null : () => _selecionarArquivo(isCP),
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text(GridTexts.selectCsv),
              style: OutlinedButton.styleFrom(
                foregroundColor: cor,
                side: BorderSide(color: cor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
          ]),

          // ── Colunas detectadas no CSV ──────────────────────────────────
          if ((isCP ? _colunasCP : _colunasCR).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cor.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.table_chart_outlined, size: 13, color: cor),
                  const SizedBox(width: 5),
                  Expanded(child: Text(
                    GridTexts.detectedColumnsUseAsDescription,
                    style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w500))),
                ]),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: (isCP ? _colunasCP : _colunasCR).map((col) => Tooltip(
                    message: GridTexts.useColumnAsDescription(col),
                    child: InkWell(
                      onTap: () {
                        // Preenche o campo de descrição com o nome desta coluna
                        ctrl['colDescricao']?.text = col;
                        // Abre o mapeamento para o usuário ver o que foi preenchido
                        if (!mapeamentoExpandido) onToggleMapeamento();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(GridTexts.columnSetAsDescription(col)),
                          duration: const Duration(seconds: 2),
                          backgroundColor: cor));
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: cor.withValues(alpha: 0.25))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(col, style: TextStyle(fontSize: 11, color: cor)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_downward, size: 10, color: cor.withValues(alpha: 0.6)),
                        ])),
                    ),
                  )).toList()),
              ]),
            ),
          ],
          const SizedBox(height: 10),

          // ── Mapeamento de colunas (expansível) ─────────────────────────
          InkWell(
            onTap: onToggleMapeamento,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cor.withValues(alpha: 0.2))),
              child: Row(children: [
                Icon(Icons.tune, size: 15, color: cor),
                const SizedBox(width: 6),
                Text(GridTexts.csvColumnMapping,
                  style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(mapeamentoExpandido ? Icons.expand_less : Icons.expand_more, size: 18, color: cor),
              ]),
            ),
          ),
          if (mapeamentoExpandido) ...[
            const SizedBox(height: 10),
            // Instrução contextual
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GridColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GridColors.info.withValues(alpha: 0.25))),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: GridColors.info),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  GridTexts.mappingInstruction,
                  style: const TextStyle(fontSize: 11, color: GridColors.info))),
              ]),
            ),
            const SizedBox(height: 10),
            // Se temos colunas detectadas, mostra dropdown; senão, campo de texto
            Wrap(spacing: 10, runSpacing: 10,
              children: _camposMapeamento.map((campo) {
                final colunas = isCP ? _colunasCP : _colunasCR;
                return SizedBox(
                  width: 220,
                  child: colunas.isNotEmpty
                    // Dropdown pesquisável com as colunas do CSV
                    ? SearchableDropdownField(
                        label: campo['label'] as String,
                        value: colunas.contains(ctrl[campo['key']]?.text)
                            ? ctrl[campo['key']]?.text
                            : null,
                        items: colunas
                            .map((c) => <String, dynamic>{'id': c, 'nome': c})
                            .toList(),
                        valueField: 'id',
                        displayField: 'nome',
                        hintText: GridTexts.doNotImport,
                        nullable: true,
                        nullLabel: GridTexts.doNotImport,
                        onChanged: (v) =>
                            setState(() => ctrl[campo['key']]?.text = v ?? ''),
                      )
                    // Fallback: campo de texto livre
                    : TextFormField(
                        controller: ctrl[campo['key']],
                        decoration: InputDecoration(
                          labelText: campo['label'],
                          labelStyle: const TextStyle(fontSize: 11),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        style: const TextStyle(fontSize: 12)),
                );
              }).toList()),
          ],
          const SizedBox(height: 12),

          // ── Opção Upsert ───────────────────────────────────────────────
          InkWell(
            onTap: onToggleUpsert,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: upsert
                    ? GridColors.warning.withValues(alpha: 0.08)
                    : GridColors.textMuted.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: upsert
                        ? GridColors.warning.withValues(alpha: 0.35)
                        : _border)),
              child: Row(children: [
                Icon(upsert ? Icons.sync_alt : Icons.add_circle_outline,
                  size: 16, color: upsert ? GridColors.warning : GridColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(upsert ? GridTexts.upsertMode : GridTexts.insertOnlyMode,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: upsert ? GridColors.warning : GridColors.textMuted)),
                  Text(
                    upsert ? GridTexts.upsertModeDesc : GridTexts.insertOnlyModeDesc,
                    style: const TextStyle(fontSize: 10, color: GridColors.textMuted)),
                ])),
                Switch(
                  value: upsert,
                  onChanged: (_) => onToggleUpsert(),
                  activeThumbColor: GridColors.warning,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ]),
            ),
          ),
          const SizedBox(height: 10),

          // ── Botão importar ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (arquivo == null || importando) ? null : () => _importar(isCP),
              icon: importando
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                  : const Icon(Icons.upload),
              label: Text(importando ? GridTexts.importing : GridTexts.importAction),
              style: ElevatedButton.styleFrom(
                backgroundColor: cor, foregroundColor: _white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          ),

          // ── Resultado ─────────────────────────────────────────────────
          if (resultado != null) ...[
            const SizedBox(height: 14),
            _buildResultadoImportacao(resultado, cor),
          ],
        ]),
      ),
    );
  }

  Widget _buildResultadoImportacao(Map<String, dynamic> resultado, Color cor) {
    final erro = resultado['error'];
    if (erro != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _primary.withValues(alpha: 0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: _primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(erro.toString(),
            style: const TextStyle(fontSize: 12, color: _primary, fontFamily: 'monospace'))),
        ]),
      );
    }

    final sucesso   = resultado['sucesso']   as int? ?? 0;
    final erros     = resultado['erros']     as int? ?? 0;
    final ignorados = resultado['ignorados'] as int? ?? 0;
    final total     = resultado['total']     as int? ?? (sucesso + erros + ignorados);
    final novosParceiros = resultado['novosParceiros'] as int? ?? 0;
    final novasFormas    = resultado['novasFormasPagamento'] as int? ?? 0;
    final detalhes  = (resultado['detalhes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final colunasCSV = (resultado['colunasCSV'] as List?)?.cast<String>() ?? [];
    final avisoMapeamento = resultado['avisoMapeamento'] as String?;

    // 100% ignorado = mapeamento errado
    final tudo100Ignorado = total > 0 && sucesso == 0 && erros == 0 && ignorados == total;
    final temErros = erros > 0 || tudo100Ignorado;
    final corStatus = tudo100Ignorado ? _primary : (temErros ? GridColors.warning : _green);

    return Container(
      decoration: BoxDecoration(
        color: corStatus.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: corStatus.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Cabeçalho ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: corStatus.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            Icon(tudo100Ignorado ? Icons.error_outline
                : (temErros ? Icons.warning_amber_rounded : Icons.check_circle),
              color: corStatus, size: 18),
            const SizedBox(width: 8),
            Text(
              tudo100Ignorado ? GridTexts.noRecordImported
                  : GridTexts.importCompleted,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: corStatus)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 15),
              tooltip: GridTexts.copyResult,
              color: corStatus,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                final txt = GridTexts.resultSummary(
                  total,
                  sucesso,
                  erros,
                  ignorados,
                  novosParceiros,
                  novasFormas,
                );
                Clipboard.setData(ClipboardData(text: txt));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(GridTexts.copied), duration: Duration(seconds: 2)));
              }),
          ]),
        ),

        // ── Aviso de mapeamento incorreto ────────────────────────────────
        if (avisoMapeamento != null) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _primary.withValues(alpha: 0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: _primary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: SelectableText(avisoMapeamento,
                style: const TextStyle(fontSize: 11, color: _primary, height: 1.5))),
            ]),
          ),
        ],

        // ── Chips de contagem ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Wrap(spacing: 10, runSpacing: 8, children: [
            _chip(GridTexts.totalLabel, total, GridColors.textMuted),
            _chip(GridTexts.importedLabel, sucesso, _green),
            if (erros > 0) _chip(GridTexts.errorsLabel, erros, _primary),
            if (ignorados > 0) _chip(GridTexts.ignoredLabel, ignorados, GridColors.warning),
            if (novosParceiros > 0) _chip(GridTexts.newPartnersLabel, novosParceiros, GridColors.info),
            if (novasFormas > 0) _chip(GridTexts.newPaymentFormsLabel, novasFormas, GridColors.statusClosed),
          ]),
        ),

        // ── Avisos de criação automática ─────────────────────────────────
        if (novosParceiros > 0) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GridColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GridColors.warning.withValues(alpha: 0.35))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: GridColors.warningDark, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                GridTexts.autoPartnersCreated(novosParceiros),
                style: const TextStyle(fontSize: 11, color: GridColors.warningDark, height: 1.5))),
            ]),
          ),
        ],
        if (novasFormas > 0) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GridColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GridColors.info.withValues(alpha: 0.25))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: GridColors.info, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                GridTexts.autoPaymentFormsCreated(novasFormas),
                style: const TextStyle(fontSize: 11, color: GridColors.info, height: 1.5))),
            ]),
          ),
        ],

        // ── Colunas detectadas no CSV (do backend) ───────────────────────
        if (colunasCSV.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(children: [
              Icon(Icons.table_chart_outlined, size: 13, color: GridColors.textMuted),
              const SizedBox(width: 5),
              Text(GridTexts.csvColumnsRead(colunasCSV.join(', ')),
                style: const TextStyle(fontSize: 11, color: GridColors.textMuted, fontStyle: FontStyle.italic)),
            ]),
          ),
        ],

        // ── Detalhes (erros e ignorados) ─────────────────────────────────
        if (detalhes.any((d) => d['status'] != 'sucesso')) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(children: [
              const Text(GridTexts.errorIgnoredDetails,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GridColors.textMuted)),
              const SizedBox(width: 8),
              // Mostra só as primeiras 20 linhas para não travar
              if (detalhes.where((d) => d['status'] != 'sucesso').length > 20)
                Text(GridTexts.showingFirst20(detalhes.where((d) => d['status'] != 'sucesso').length),
                  style: const TextStyle(fontSize: 10, color: GridColors.textMuted)),
              const Spacer(),
              // ── Botão copiar todos os erros ──────────────────────────
              TextButton.icon(
                onPressed: () {
                  final todos = detalhes.where((d) => d['status'] != 'sucesso').toList();
                  final texto = todos.map((d) =>
                    GridTexts.lineStatusMessage(d['linha'], d['status'], d['mensagem'])).join('\n');
                  Clipboard.setData(ClipboardData(text: texto));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(GridTexts.errorsCopied(todos.length)),
                    duration: const Duration(seconds: 2),
                    backgroundColor: GridColors.textMuted));
                },
                icon: const Icon(Icons.copy_all, size: 14),
                label: Text(
                  GridTexts.copyAllCount(detalhes.where((d) => d['status'] != 'sucesso').length),
                  style: const TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: GridColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            ])),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                itemCount: detalhes.where((d) => d['status'] != 'sucesso').take(20).length,
                itemBuilder: (_, i) {
                  final d = detalhes.where((d) => d['status'] != 'sucesso').take(20).toList()[i];
                  final st = d['status'] as String? ?? '';
                  final corD = st == 'erro' ? _primary : GridColors.warning;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(st == 'erro' ? Icons.cancel : Icons.info_outline,
                        size: 13, color: corD),
                      const SizedBox(width: 6),
                      Text(GridTexts.linePrefix(d['linha']),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: corD)),
                      Expanded(child: SelectableText(d['mensagem']?.toString() ?? '',
                        style: TextStyle(fontSize: 11, color: corD))),
                    ]),
                  );
                },
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _chip(String label, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$valor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: cor)),
      ]),
    );
  }
}

