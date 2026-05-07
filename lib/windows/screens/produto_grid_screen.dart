import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';

class WindowsProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsProdutoGridScreen({super.key, required this.hasPermission});

  /// Carrega lista de empresas para o dropdown
  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'nome': e['nome']})
          .toList();
    }
    return [];
  }

  /// Carrega lista de parceiros para o dropdown
  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'nome': e['nome']})
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    final empresaId = login?.empresa?.id?.toString();
    final parceiroId = login?.parceiro?.id?.toString();

    // Só bloqueia se o usuário logado for parceiro/cliente (tem empresa ou parceiro na sessão)
    final hasEmpresa = empresaId != null && empresaId.isNotEmpty;
    final hasParceiro = parceiroId != null && parceiroId.isNotEmpty;

    final fieldOverrides = <FieldConfigWindows>[
      if (hasEmpresa)
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadEmpresas,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: empresaId,
          enabled: false, // campo bloqueado
        ),
      if (hasParceiro)
        FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadParceiros,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: parceiroId,
          enabled: false, // campo bloqueado
        ),
    ];

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'produto',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: fieldOverrides.isNotEmpty ? fieldOverrides : null,
      // Força filtro de tenant na URL da grid
      extraParams: {
        if (hasEmpresa) 'empId': empresaId,
        if (hasParceiro) 'parceiroId': parceiroId,
        if (hasParceiro) 'clienteId': parceiroId,
      },
    );
  }
}
