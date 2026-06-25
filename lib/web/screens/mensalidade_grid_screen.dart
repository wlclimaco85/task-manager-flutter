import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/mensalidade_model.dart';

class WebMensalidadeGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const WebMensalidadeGridScreen({super.key, required this.hasPermission});

  @override
  State<WebMensalidadeGridScreen> createState() =>
      _WebMensalidadeGridScreenState();
}

class _WebMensalidadeGridScreenState extends State<WebMensalidadeGridScreen> {
  // Chave para forçar rebuild do GenericGridScreen após baixa
  int _chaveReload = 0;

  Future<void> _darBaixa(BuildContext context, Mensalidade mensalidade) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Baixa'),
        content: const Text(
          'Confirmar baixa desta mensalidade? '
          'A data de pagamento será definida como hoje.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final payload = mensalidade.toJson()
      ..['dtPagamento'] = DateTime.now().toIso8601String();

    final url = TenantContext.applyToUrl(
      ApiLinks.updateMensalidade(mensalidade.id.toString()),
    );

    try {
      final resposta = await http.put(
        Uri.parse(url),
        headers: TenantContext.jsonHeaders,
        body: jsonEncode(payload),
      );

      if (!context.mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baixa registrada com sucesso.'),
            backgroundColor: Color(0xFF18B86A),
          ),
        );
        setState(() => _chaveReload++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar baixa: ${resposta.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha na requisição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirBoleto(Mensalidade mensalidade) async {
    final uri = Uri.parse(mensalidade.urlBoleto!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Mensalidade>(
      key: ValueKey(_chaveReload),
      title: "Mensalidades",
      fetchEndpoint: ApiLinks.allMensalidades,
      createEndpoint: ApiLinks.createMensalidade,
      updateEndpoint: ApiLinks.updateMensalidade(":id"),
      deleteEndpoint: ApiLinks.deleteMensalidade(":id"),
      fromJson: (json) => Mensalidade.fromJson(json),
      toJson: (m) => m.toJson(),
      hasPermission: widget.hasPermission,
      fieldConfigs: Mensalidade.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dtPagamento',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'mensalidades',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
      customActions: () => [
        CustomAction<Mensalidade>(
          icon: Icons.check_circle_outline,
          label: 'Dar Baixa',
          isVisible: (m) => m.dtPagamento == null,
          onPressed: (ctx, m) => _darBaixa(ctx, m),
        ),
        CustomAction<Mensalidade>(
          icon: Icons.picture_as_pdf,
          label: 'Boleto',
          isVisible: (m) =>
              m.urlBoleto != null && m.urlBoleto!.isNotEmpty,
          onPressed: (ctx, m) => _abrirBoleto(m),
        ),
      ],
    );
  }
}
