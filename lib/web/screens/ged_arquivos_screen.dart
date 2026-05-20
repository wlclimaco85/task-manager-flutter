import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType, GridColors;

class GedArquivosScreen extends StatelessWidget {
  final String? moduloOrigem;
  final int? idOrigem;
  final String? nomeOrigem;
  final int? empresaId;

  const GedArquivosScreen({
    super.key,
    this.moduloOrigem,
    this.idOrigem,
    this.nomeOrigem,
    this.empresaId,
  });

  Map<String, dynamic> get _extraParams {
    final params = <String, dynamic>{};
    final empresa = empresaId ?? TenantContext.empresaId;
    final parceiro = TenantContext.parceiroId;

    if (empresa != null) params['empresaId'] = empresa;
    if (parceiro != null) params['parceiroId'] = parceiro;
    if (moduloOrigem != null && moduloOrigem!.isNotEmpty) {
      params['modulo'] = moduloOrigem;
    }
    if (idOrigem != null) params['idOrigem'] = idOrigem;

    return params;
  }

  List<FieldConfigWindows> get _fieldOverrides {
    final empresa = empresaId ?? TenantContext.empresaId;
    final parceiro = TenantContext.parceiroId;

    return [
      FieldConfigWindows(
        label: 'Empresa',
        fieldName: 'empresa',
        displayFieldName: 'empresa.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownSelectedValue: empresa,
        dropdownFutureBuilder: DropdownHelpers.empresas,
        enabled: empresa == null,
        isRequired: true,
      ),
      FieldConfigWindows(
        label: 'Parceiro',
        fieldName: 'parceiro',
        displayFieldName: 'parceiro.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownSelectedValue: parceiro,
        dropdownFutureBuilder: DropdownHelpers.parceiros,
        enabled: parceiro == null,
      ),
      FieldConfigWindows(
        label: 'Diretorio',
        fieldName: 'diretorio',
        displayFieldName: 'diretorio.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownFutureBuilder: () => DropdownHelpers.load(
          ApiLinks.allDiretorios,
          displayField: 'nome',
        ),
      ),
      const FieldConfigWindows(
        label: 'Modulo',
        fieldName: 'modulo',
        isInForm: false,
        isVisibleByDefault: false,
        enabled: false,
      ),
      const FieldConfigWindows(
        label: 'ID Origem',
        fieldName: 'idOrigem',
        isInForm: false,
        isVisibleByDefault: false,
        enabled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final extraParams = _extraParams;

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'arquivo',
      hasPermission: (_) => true,
      fromJson: (json) => json,
      toJson: (arquivo) => arquivo,
      fetchEndpointOverride: ApiLinks.allArquivos,
      createEndpointOverride: ApiLinks.createArquivo,
      updateEndpointOverride: ApiLinks.updateArquivo(':id'),
      deleteEndpointOverride: ApiLinks.deleteArquivo(':id'),
      extraParams: extraParams.isEmpty ? null : extraParams,
      fieldOverrides: _fieldOverrides,
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.download,
          label: 'Baixar',
          onPressed: _baixarArquivo,
          isVisible: (arquivo) => arquivo['id'] != null,
        ),
      ],
    );
  }

  Future<void> _baixarArquivo(
    BuildContext context,
    Map<String, dynamic> arquivo,
  ) async {
    final id = arquivo['id']?.toString();
    if (id == null || id.isEmpty) return;

    final nome = (arquivo['fileName'] ??
            arquivo['nome'] ??
            arquivo['filename'] ??
            'arquivo_$id')
        .toString();

    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final response = await http.get(
        Uri.parse(ApiLinks.downloadArquivo(id)),
        headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
      );

      if (!context.mounted) return;
      if (response.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: nome,
          bytes: response.bodyBytes,
        );
        _snack(context, 'Download concluido: $nome');
      } else {
        _snack(
          context,
          'Erro ao baixar arquivo: ${response.statusCode}',
          error: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Erro ao baixar arquivo: $e', error: true);
      }
    }
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? GridColors.error : GridColors.success,
        content: Text(message),
      ),
    );
  }
}
