import 'package:flutter/material.dart';
import '../widgets/generic_grid_windows_screen.dart' show GridColors;

class NfeXmlPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool confirming;

  const NfeXmlPreviewWidget({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.confirming = false,
  });

  String? _get(String key) => data[key]?.toString();
  String? _getNested(String outer, String inner) {
    final o = data[outer];
    if (o is Map) return o[inner]?.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final numero = _get('numero') ?? _get('nNF') ?? '-';
    final serie = _get('serie') ?? '-';
    final chave = _get('chave') ?? '-';
    final dhEmi = _get('dhEmi') ?? '-';
    final emitenteNome = _getNested('emitente', 'nome') ??
        _getNested('emitente', 'xNome') ??
        _getNested('empresa', 'nome') ??
        '-';
    final emitenteCnpj = _getNested('emitente', 'cnpj') ??
        _getNested('emitente', 'CNPJ') ??
        _getNested('empresa', 'cnpj') ??
        '-';
    final destNome = _getNested('destinatario', 'nome') ??
        _getNested('destinatario', 'xNome') ??
        _getNested('parceiro', 'nome') ??
        '-';
    final destCnpj = _getNested('destinatario', 'cnpj') ??
        _getNested('destinatario', 'CNPJ') ??
        _getNested('parceiro', 'cnpj') ??
        '-';
    final vTotal = _get('vTotal') ??
        _get('vNF') ??
        _get('total') ??
        _get('valorTotal') ??
        '-';
    final qtdItens = _get('qtdItens') ??
        _get('quantidadeItens') ??
        (data['itens'] is List ? '${(data['itens'] as List).length}' : '-');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: GridColors.secondary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Preview da NF-e',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Número', numero),
            _buildField('Série', serie),
            _buildField('Chave de Acesso', chave),
            _buildField('Data de Emissão', dhEmi),
            const Divider(height: 24),
            _buildSectionHeader('Emitente'),
            _buildField('Razão Social', emitenteNome),
            _buildField('CNPJ', emitenteCnpj),
            const Divider(height: 24),
            _buildSectionHeader('Destinatário'),
            _buildField('Nome', destNome),
            _buildField('CNPJ', destCnpj),
            const Divider(height: 24),
            _buildField('Valor Total', vTotal),
            _buildField('Quantidade de Itens', qtdItens),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                  onPressed: confirming ? null : onConfirm,
                  icon: confirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(confirming ? 'Importando...' : 'Confirmar Importação'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: confirming ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: GridColors.secondary,
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
