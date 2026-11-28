import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:share_plus/share_plus.dart';

import '../../../utils/file_saver_compat.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/app_logger.dart';
import '../../../widgets/user_banners.dart';
import 'package:flutter/material.dart';
import '../../../models/escrituracao_fiscal_model.dart';
import '../../../models/item_escrituracao_model.dart';
import '../../../services/escrituracao_fiscal_service.dart';
import '../../../utils/grid_texts.dart';

class EscrituracaoDetalheScreen extends StatefulWidget {
  final EscrituracaoFiscal escrituracao;
  final bool cabecalhoMobile;
  /// Substituível em teste.
  final Future<void> Function(String nome, Uint8List bytes)? salvar;

  const EscrituracaoDetalheScreen(
      {super.key, required this.escrituracao, this.cabecalhoMobile = false, this.salvar});

  @override
  State<EscrituracaoDetalheScreen> createState() =>
      _EscrituracaoDetalheScreenState();
}

class _EscrituracaoDetalheScreenState extends State<EscrituracaoDetalheScreen> {
  final _service = EscrituracaoFiscalService();
  late EscrituracaoFiscal _esc;
  List<ItemEscrituracao> _itens = [];
  bool _loading = true;
  bool _actionLoading = false;
  bool _exportando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _esc = widget.escrituracao;
    _loadItens();
  }

  Future<void> _loadItens() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final itens = await _service.itens(_esc.id!);
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _loading = false;
      });
    } catch (e) {
      AppLogger.i.warn('escrituracao_detalhe_screen: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _conferir() async {
    setState(() => _actionLoading = true);
    try {
      final atualizada = await _service.conferir(_esc.id!);
      if (!mounted) return;
      setState(() {
        _esc = atualizada;
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escrituração conferida com sucesso!')),
      );
    } catch (e) {
      AppLogger.i.warn('escrituracao_detalhe_screen: $e');
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao conferir: $e')),
      );
    }
  }

  Future<void> _fechar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar Escrituração'),
        content: const Text(
            'Confirma o fechamento desta escrituração? Após fechada não poderá ser alterada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      final atualizada = await _service.fechar(_esc.id!);
      if (!mounted) return;
      setState(() {
        _esc = atualizada;
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escrituração fechada com sucesso!')),
      );
    } catch (e) {
      AppLogger.i.warn('escrituracao_detalhe_screen: $e');
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fechar: $e')),
      );
    }
  }

  /// Salva o livro em CSV. No celular o arquivo é compartilhado: a pasta do app não é acessível ao usuário.
  Future<void> _exportar() async {
    setState(() => _exportando = true);
    var mensagem = 'Não foi possível exportar a escrituração.';
    try {
      final bytes = await _service.exportar(_esc.id!);
      final nome = 'escrituracao-${_esc.periodo}-${_esc.tipo.toLowerCase()}.csv';
      if (widget.salvar != null) {
        await widget.salvar!(nome, bytes);
        mensagem = 'CSV gerado.';
      } else {
        final caminho =
            await FileSaver.instance.saveFile(name: nome, bytes: bytes, mimeType: MimeType.csv);
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(caminho, name: nome)], sharePositionOrigin: ui.Rect.largest);
          mensagem = '';
        } else {
          mensagem = kIsWeb ? 'CSV gerado.' : 'CSV salvo em $caminho';
        }
      }
    } on EscrituracaoFiscalException catch (e) {
      AppLogger.i.warn('escrituracao_detalhe_screen: $e');
      mensagem = e.message;
    } catch (e, st) {
      AppLogger.i.error('escrituracao_detalhe_screen: falha ao exportar ($e)', st);
    }
    if (!mounted) return;
    setState(() => _exportando = false);
    if (mensagem.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  Widget get _botaoExportar => IconButton(
        tooltip: 'Exportar CSV',
        color: GridColors.textPrimary,
        onPressed: _exportando ? null : _exportar,
        icon: const Icon(Icons.download),
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'ABERTO':
        return GridColors.warningDark;
      case 'CONFERIDO':
        return GridColors.info;
      case 'FECHADO':
        return GridColors.success;
      default:
        return GridColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeConferir = _esc.status == 'ABERTO';
    final podeFechar = _esc.status == 'CONFERIDO';
    final podeAcao = podeConferir || podeFechar;

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      // No celular usa o cabeçalho padrão do app (usuário, avisos e sair).
      appBar: widget.cabecalhoMobile
          ? UserBannerAppBar(
              screenTitle: 'Escrituração ${_esc.periodo}',
              showBackButton: true,
              showFilterButton: false,
              actions: [
                _botaoExportar,
                IconButton(
                  tooltip: 'Atualizar',
                  color: GridColors.textPrimary,
                  onPressed: _loadItens,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
          : AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        title: Text('Escrituração ${_esc.periodo}'),
        actions: [
          _botaoExportar,
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItens,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: GridColors.errorDark),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _loadItens,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadItens,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.list, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Itens (${_itens.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _itens.isEmpty
                            ? const Center(
                                child: Text('Nenhum item encontrado.',
                                    style: TextStyle(color: GridColors.neutral)),
                              )
                            : ListView.separated(
                                itemCount: _itens.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 16),
                                itemBuilder: (_, i) =>
                                    _buildItemCard(_itens[i]),
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: podeAcao
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (podeConferir)
                  FloatingActionButton.extended(
                    heroTag: 'conferir',
                    backgroundColor: GridColors.info,
                    foregroundColor: GridColors.textPrimary,
                    onPressed: _actionLoading ? null : _conferir,
                    icon: _actionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: GridColors.textPrimary),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Conferir'),
                  ),
                if (podeFechar) ...[
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'fechar',
                    backgroundColor: GridColors.success,
                    foregroundColor: GridColors.textPrimary,
                    onPressed: _actionLoading ? null : _fechar,
                    icon: _actionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: GridColors.textPrimary),
                          )
                        : const Icon(Icons.lock_outline),
                    label: const Text('Fechar'),
                  ),
                ],
              ],
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _statusColor(_esc.status).withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_esc.periodo} — ${_esc.tipo}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(_esc.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _statusColor(_esc.status).withValues(alpha: 0.5)),
                ),
                child: Text(
                  _esc.statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(_esc.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Documentos', '${_esc.totalDocumentos ?? 0}'),
          _infoRow('Valor Total',
              'R\$ ${_esc.valorTotal?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Base ICMS',
              'R\$ ${_esc.valorBaseIcms?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Valor ICMS',
              'R\$ ${_esc.valorIcms?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Base IBS',
              'R\$ ${_esc.valorBaseIbs?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Valor IBS',
              'R\$ ${_esc.valorIbs?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Base CBS',
              'R\$ ${_esc.valorBaseCbs?.toStringAsFixed(2) ?? '0,00'}'),
          _infoRow('Valor CBS',
              'R\$ ${_esc.valorCbs?.toStringAsFixed(2) ?? '0,00'}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: GridColors.neutral)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemEscrituracao item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.status == 'OK'
            ? GridColors.success.withValues(alpha: 0.15)
            : GridColors.errorDark.withValues(alpha: 0.15),
        child: Icon(
          item.status == 'OK' ? Icons.check : Icons.warning,
          color: item.status == 'OK' ? GridColors.success : GridColors.errorDark,
          size: 20,
        ),
      ),
      title: Text(
        item.chaveAcesso != null
            ? 'NF-e ${item.chaveAcesso!.substring(item.chaveAcesso!.length - 6)}'
            : 'Item #${item.id ?? item.nfeId ?? item.escrituracaoId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.cfop != null || item.ncm != null)
            Text('CFOP: ${item.cfop ?? '-'}  NCM: ${item.ncm ?? '-'}',
                style: const TextStyle(fontSize: 12)),
          if (item.valor != null)
            Text('Valor: R\$ ${item.valor!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12)),
          if (item.inconsistencia != null &&
              item.inconsistencia!.isNotEmpty)
            Text(
              item.inconsistencia!,
              style: const TextStyle(fontSize: 11, color: GridColors.errorDark),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (item.status == 'OK' ? GridColors.success : GridColors.errorDark)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (item.status == 'OK' ? GridColors.success : GridColors.errorDark)
                .withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          item.statusLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: item.status == 'OK' ? GridColors.success : GridColors.errorDark,
          ),
        ),
      ),
    );
  }
}
