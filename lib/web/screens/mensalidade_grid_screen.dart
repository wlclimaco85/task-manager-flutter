import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/mensalidade_model.dart';
import 'baixa_dialog_mensalidade.dart';

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
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => WebBaixaDialogMensalidade(mensalidade: mensalidade),
    );
    if (result == true && context.mounted) {
      setState(() => _chaveReload++);
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
