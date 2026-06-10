import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart'
    show DynamicGridWindowsScreen, SecurityCheck;
import '../../../utils/tenant_context.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType;
import './comunicado_detalhe_screen.dart';

/// Tela principal de Comunicados.
/// - Apenas botao "Visualizar comunicado" na coluna de acoes (sem botao de editar extra).
/// - Campo Empresa pre-selecionado com a empresa do usuario logado.
/// - Campo Aplicativo pre-selecionado e desabilitado.
/// - Campo ID oculto no INSERT (comportamento automatico do DynamicGridWindowsScreen).
class WebComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  List<FieldConfigWindows> get _fieldOverrides {
    final empresaId = TenantContext.empresaId;
    final aplicativoId = TenantContext.aplicativoId;

    return [
      // Empresa: pre-selecionada com a empresa do usuario logado, desabilitada se ja tiver empresa
      FieldConfigWindows(
        label: 'Empresa',
        fieldName: 'empresa',
        displayFieldName: 'empresa.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownSelectedValue: empresaId?.toString(),
        dropdownFutureBuilder: DropdownHelpers.empresas,
        enabled: empresaId == null,
        isRequired: true,
        fieldOrder: 1,
      ),
      // Aplicativo: pre-selecionado e sempre desabilitado
      FieldConfigWindows(
        label: 'Aplicativo',
        fieldName: 'aplicativo',
        displayFieldName: 'aplicativo.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownSelectedValue: aplicativoId?.toString(),
        dropdownFutureBuilder: DropdownHelpers.aplicativos,
        enabled: false,
        fieldOrder: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'comunicado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: _fieldOverrides,
      // Apenas a acao "Visualizar comunicado" — sem botao de editar duplicado
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.visibility,
          label: 'Visualizar comunicado',
          onPressed: (context, comunicado) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ComunicadoDetalheScreen(comunicado: comunicado),
              ),
            );
          },
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
