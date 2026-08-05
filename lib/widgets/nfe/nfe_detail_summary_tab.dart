import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';

/// Tab de Resumo do NfeDetailDialog
/// Exibe: Status, Valores, Tomador, Emitente
class NfeDetailSummaryTab extends StatelessWidget {
  final NfeModel nfe;

  const NfeDetailSummaryTab({super.key, required this.nfe});

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final formatted = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'R\$ $formatted,$decimal';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateTime(DateTime date) {
    final dateStr = _formatDate(date);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
  }

  /// Renders a row com label + value
  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: DesignTokens.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
            child: NfeStatusBadge(
              status: nfe.statusNfe,
              expanded: true,
              breakpoint: Breakpoint.desktop,
            ),
          ),

          const Divider(),

          // Seção: Valores
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Seção de valores',
                  child: Text(
                    'Valores',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow('Subtotal', _formatCurrency(nfe.valores.subtotal)),
                _buildRow('Desconto', _formatCurrency(nfe.valores.desconto)),
                _buildRow('ICMS', _formatCurrency(nfe.valores.icms)),
                _buildRow('PIS', _formatCurrency(nfe.valores.pis)),
                _buildRow('COFINS', _formatCurrency(nfe.valores.cofins)),
                _buildRow('Frete', _formatCurrency(nfe.valores.frete)),
                _buildRow('Seguro', _formatCurrency(nfe.valores.seguro)),
                _buildRow('Total', _formatCurrency(nfe.valores.total), bold: true),
              ],
            ),
          ),

          const Divider(),

          // Seção: Emitente
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Seção de informações do emitente',
                  child: Text(
                    'Emitente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow('CNPJ', nfe.emitente.cnpjCpf),
                _buildRow('Razão Social', nfe.emitente.razaoSocial),
                _buildRow('Série', nfe.serie),
                _buildRow(
                  'Ambiente',
                  nfe.ambiente == 'producao' ? 'Produção' : 'Homologação',
                ),
              ],
            ),
          ),

          const Divider(),

          // Seção: Tomador
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Seção de informações do tomador',
                  child: Text(
                    'Tomador',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow('CNPJ/CPF', nfe.tomador.cnpjCpf),
                _buildRow('Razão Social', nfe.tomador.razaoSocial),
                if (nfe.tomador.endereco != null) ...[
                  _buildRow('Endereço', nfe.tomador.endereco ?? ''),
                  _buildRow('Cidade', nfe.tomador.cidade ?? ''),
                  _buildRow('UF', nfe.tomador.uf ?? ''),
                ],
              ],
            ),
          ),

          const Divider(),

          // Data & Protocolo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
            child: Column(
              children: [
                _buildRow('Data de Emissão', _formatDateTime(nfe.dataHora)),
                if (nfe.protocolo != null)
                  _buildRow('Protocolo', nfe.protocolo ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
