import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';

/// Tab de Impostos do NfeDetailDialog
/// Exibe: Breakdown consolidado de ICMS, IPI, PIS, COFINS, CSLL, INSS
class NfeDetailImpostosTab extends StatelessWidget {
  final NfeModel nfe;

  const NfeDetailImpostosTab({super.key, required this.nfe});

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

  /// Renderiza uma linha de imposto com cor diferenciada
  Widget _buildImpostoRow(String nome, double valor, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nome,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            _formatCurrency(valor),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final impostos = nfe.valores;

    // Calcula total de impostos
    final totalImpostos = impostos.icms +
        impostos.pis +
        impostos.cofins +
        impostos.ipi +
        impostos.csll +
        impostos.inss;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Seção de impostos',
            child: Text(
              'Resumo de Impostos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),

          // ICMS
          if (impostos.icms > 0)
            _buildImpostoRow(
              'ICMS',
              impostos.icms,
              color: Colors.blue,
            ),

          // IPI
          if (impostos.ipi > 0)
            _buildImpostoRow(
              'IPI',
              impostos.ipi,
              color: Colors.green,
            ),

          // PIS
          if (impostos.pis > 0)
            _buildImpostoRow(
              'PIS',
              impostos.pis,
              color: Colors.orange,
            ),

          // COFINS
          if (impostos.cofins > 0)
            _buildImpostoRow(
              'COFINS',
              impostos.cofins,
              color: Colors.purple,
            ),

          // CSLL
          if (impostos.csll > 0)
            _buildImpostoRow(
              'CSLL',
              impostos.csll,
              color: Colors.red,
            ),

          // INSS
          if (impostos.inss > 0)
            _buildImpostoRow(
              'INSS',
              impostos.inss,
              color: Colors.pink,
            ),

          const Divider(),

          // Total de Impostos
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de Impostos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatCurrency(totalImpostos),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.primary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Alíquota efetiva
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alíquota Efetiva',
                  style: TextStyle(fontSize: 12, color: DesignTokens.textMuted),
                ),
                Text(
                  '${(totalImpostos / nfe.valores.subtotal * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
