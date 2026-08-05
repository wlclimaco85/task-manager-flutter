import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tab de Ações do NfeDetailDialog
/// Renderiza botões contextuais conforme status da NFe
/// Estados:
/// - PENDENTE: Emitir
/// - AUTORIZADA: Cancelar, Download PDF, Download XML
/// - CANCELADA: Download PDF/XML apenas
/// - Sempre: Enviar por Email
class NfeDetailActionsTab extends StatefulWidget {
  final NfeModel nfe;

  const NfeDetailActionsTab({super.key, required this.nfe});

  @override
  State<NfeDetailActionsTab> createState() => _NfeDetailActionsTabState();
}

class _NfeDetailActionsTabState extends State<NfeDetailActionsTab> {
  bool _isLoading = false;

  /// Mostra dialog de carregamento
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Fecha dialog de carregamento
  void _hideLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Renderiza um botão de ação primária
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
          ),
          icon: isLoading ? const SizedBox.shrink() : Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  /// Renderiza um botão de ação secundária
  Widget _buildSecondaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  /// Handle: Emitir NFe
  Future<void> _handleEmitir() async {
    try {
      L.d('[NfeDetailActionsTab] Emitindo NFe ${widget.nfe.id}');
      _showLoadingDialog(context, 'Emitindo NF-e...');

      // TODO: Chamar API para emitir
      await Future.delayed(const Duration(seconds: 1));

      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NF-e emitida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      L.e('[NfeDetailActionsTab] Erro ao emitir: $e');
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao emitir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle: Cancelar NFe
  Future<void> _handleCancelar() async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NF-e #${widget.nfe.id} - ${widget.nfe.numero}'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo do cancelamento *',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Mínimo 15 caracteres',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (motivoCtrl.text.trim().length < 15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motivo deve ter pelo menos 15 caracteres'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      L.d('[NfeDetailActionsTab] Cancelando NFe ${widget.nfe.id}');
      _showLoadingDialog(context, 'Cancelando NF-e...');

      // TODO: Chamar API para cancelar
      await Future.delayed(const Duration(seconds: 1));

      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NF-e cancelada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Fecha dialog após sucesso
      }
    } catch (e) {
      L.e('[NfeDetailActionsTab] Erro ao cancelar: $e');
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle: Download PDF
  Future<void> _handleDownloadPdf() async {
    try {
      L.d('[NfeDetailActionsTab] Baixando PDF NFe ${widget.nfe.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baixando PDF...')),
      );

      // TODO: Chamar API para baixar DANFE
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF baixado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      L.e('[NfeDetailActionsTab] Erro ao baixar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle: Download XML
  Future<void> _handleDownloadXml() async {
    try {
      L.d('[NfeDetailActionsTab] Baixando XML NFe ${widget.nfe.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baixando XML...')),
      );

      // TODO: Chamar API para baixar XML
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XML baixado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      L.e('[NfeDetailActionsTab] Erro ao baixar XML: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle: Enviar por Email
  Future<void> _handleEnviarEmail() async {
    final emailCtrl = TextEditingController();
    final emailsCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar NF-e por Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email do destinatário *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Emails adicionais (separados por vírgula)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (emailCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email é obrigatório'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      L.d('[NfeDetailActionsTab] Enviando email NFe ${widget.nfe.id}');
      _showLoadingDialog(context, 'Enviando email...');

      // TODO: Chamar API para enviar email
      await Future.delayed(const Duration(seconds: 1));

      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      L.e('[NfeDetailActionsTab] Erro ao enviar email: $e');
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.nfe.statusNfe;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Seção de ações da NFe',
            child: Text(
              'Ações',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Ação: Emitir (apenas se PENDENTE)
          if (status == NfeStatus.pendente)
            _buildActionButton(
              label: 'Emitir NF-e',
              icon: Icons.check_circle,
              onPressed: _handleEmitir,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            ),

          // Ação: Cancelar (apenas se AUTORIZADA)
          if (status == NfeStatus.autorizada)
            _buildActionButton(
              label: 'Cancelar NF-e',
              icon: Icons.cancel,
              onPressed: _handleCancelar,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),

          // Downloads
          _buildSecondaryActionButton(
            label: 'Download PDF (DANFE)',
            icon: Icons.picture_as_pdf,
            onPressed: _handleDownloadPdf,
          ),

          _buildSecondaryActionButton(
            label: 'Download XML',
            icon: Icons.code,
            onPressed: _handleDownloadXml,
          ),

          // Email
          _buildSecondaryActionButton(
            label: 'Enviar por Email',
            icon: Icons.email,
            onPressed: _handleEnviarEmail,
          ),

          const SizedBox(height: 16),
          Text(
            'Status: ${status.toString()}',
            style: const TextStyle(fontSize: 11, color: DesignTokens.textMuted),
          ),
        ],
      ),
    );
  }
}
