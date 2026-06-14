import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Widget de boleto para Contas a Pagar e Contas a Receber.
///
/// Exibe botão de upload (se ainda não houver boleto) e botão de download
/// (se já houver link de boleto). Segue padrão banco digital: sem fundo rosa,
/// ícone `receipt`, botão verde para upload e azul para download.
///
/// Uso:
/// ```dart
/// BoletoWidget(
///   lancamentoId: conta.id!,
///   lancamentoTipo: 'PAGAR',  // ou 'RECEBER'
///   boletoLink: conta.boletoLink,
/// )
/// ```
class BoletoWidget extends StatefulWidget {
  final int lancamentoId;

  /// 'PAGAR' ou 'RECEBER'
  final String lancamentoTipo;

  /// Link do boleto já existente (pode ser nulo).
  final String? boletoLink;

  const BoletoWidget({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
    this.boletoLink,
  });

  @override
  State<BoletoWidget> createState() => _BoletoWidgetState();
}

class _BoletoWidgetState extends State<BoletoWidget> {
  bool _enviando = false;
  bool _baixando = false;
  String? _erro;
  String? _linkAtual;

  @override
  void initState() {
    super.initState();
    _linkAtual = widget.boletoLink;
  }

  String get _uploadEndpoint {
    final base = ApiLinks.baseUrl;
    if (widget.lancamentoTipo == 'PAGAR') {
      return '$base/boletobancos/rest/boleto/upload?contaPagarId=${widget.lancamentoId}';
    }
    return '$base/boletobancos/rest/boleto/upload?contaReceberId=${widget.lancamentoId}';
  }

  Future<void> _fazerUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final arquivo = result.files.first;
    final bytes = arquivo.bytes;
    if (bytes == null) {
      _mostrarErro('Não foi possível ler o arquivo.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
      request.headers.addAll(TenantContext.headers);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: arquivo.name,
      ));

      if (TenantContext.empresaId != null) {
        request.fields['empId'] = TenantContext.empresaId.toString();
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final data = jsonDecode(body);
        final link = data['boletoLink'] ??
            data['link'] ??
            data['url'] ??
            data['boletoUrl'] ??
            '';
        setState(() => _linkAtual = link.toString());
        _snack('Boleto enviado com sucesso!', sucesso: true);
      } else {
        _mostrarErro('Erro ao enviar boleto (${streamed.statusCode}).');
      }
    } catch (e) {
      _mostrarErro('Erro: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _fazerDownload() async {
    if (_linkAtual == null || _linkAtual!.isEmpty) return;

    setState(() {
      _baixando = true;
      _erro = null;
    });

    try {
      // Tenta abrir como URL direta no browser
      final uri = Uri.tryParse(_linkAtual!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Fallback: baixa os bytes e abre localmente (mobile/desktop)
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        uri!,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        if (kIsWeb) {
          _snack('Download iniciado', sucesso: true);
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/boleto_${widget.lancamentoId}.pdf');
          await file.writeAsBytes(resp.bodyBytes);
          final fileUri = Uri.file(file.path);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        _mostrarErro('Erro ao baixar boleto (${resp.statusCode}).');
      }
    } catch (e) {
      _mostrarErro('Erro ao abrir boleto: $e');
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    setState(() => _erro = msg);
    _snack(msg, sucesso: false);
  }

  void _snack(String msg, {required bool sucesso}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: sucesso ? GridColors.success : GridColors.error,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temBoleto = _linkAtual != null && _linkAtual!.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_erro != null) _buildBannerErro(),
                if (!temBoleto) _buildEstadoSemBoleto(),
                if (temBoleto) _buildEstadoComBoleto(),
                const SizedBox(height: 12),
                _buildBotoes(temBoleto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GridColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt, color: GridColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boleto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Upload ou download do arquivo de boleto',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF757575)),
            tooltip: 'Fechar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerErro() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: GridColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(color: GridColors.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: GridColors.error),
            onPressed: () => setState(() => _erro = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoSemBoleto() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum boleto anexado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Envie um arquivo PDF para anexar o boleto.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoComBoleto() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boleto disponível',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Text(
                  'Clique em "Abrir boleto" para visualizar.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1976D2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoes(bool temBoleto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão upload — sempre disponível para substituir
        ElevatedButton.icon(
          onPressed: (_enviando || _baixando) ? null : _fazerUpload,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload_file, size: 20),
          label: Text(
            _enviando
                ? 'Enviando...'
                : (temBoleto ? 'Substituir boleto' : 'Enviar boleto (PDF)'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        if (temBoleto) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: (_enviando || _baixando) ? null : _fazerDownload,
            icon: _baixando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.open_in_browser, size: 20),
            label: Text(
              _baixando ? 'Abrindo...' : 'Abrir boleto',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }
}
