import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import '../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

/// Helper centralizado para carregar dropdowns comuns
class DropdownHelpers {
  static Future<List<Map<String, dynamic>>> load(
    String url, {
    String displayField = 'nome',
  }) async {
    try {
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) return [];
      dynamic raw = resp.body;
      List lista = [];
      if (raw is List) {
        lista = raw;
      } else if (raw is Map) {
        final d = raw['data'] ?? raw['dados'] ?? raw['items'] ?? raw['content'];
        if (d is List) {
          lista = d;
        } else if (d is Map) {
          final inner = d['content'] ?? d['dados'] ?? d['items'];
          if (inner is List) lista = inner;
        }
      }
      return lista.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        if (item[displayField] == null ||
            item[displayField].toString().isEmpty) {
          item[displayField] = item['nome'] ??
              item['descricao'] ??
              item['codigo'] ??
              item['name'] ??
              item['id']?.toString() ??
              '';
        }
        return item;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Loaders específicos ----
  static Future<List<Map<String, dynamic>>> empresas() =>
      load(ApiLinks.allEmpresas, displayField: 'nome');

  static Future<List<Map<String, dynamic>>> parceiros() =>
      load(ApiLinks.allParceiros, displayField: 'nome');

  /// Carrega parceiros filtrados pela empresa fornecida.
  /// Se [empresaId] for nulo ou vazio, retorna todos os parceiros.
  static Future<List<Map<String, dynamic>>> parceirosPorEmpresa(
      String? empresaId) {
    if (empresaId == null || empresaId.isEmpty) return parceiros();
    return load(ApiLinks.allParceirosPorEmp(empresaId), displayField: 'nome');
  }

  static Future<List<Map<String, dynamic>>> aplicativos() =>
      load('${ApiLinks.baseUrl}/api/aplicativo', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> setores() =>
      load('${ApiLinks.baseUrl}/api/setor', displayField: 'descricao');

  static Future<List<Map<String, dynamic>>> regimes() =>
      load('${ApiLinks.baseUrl}/api/regime_tributario', displayField: 'codigo');

  static Future<List<Map<String, dynamic>>> formasPagamento() =>
      load('${ApiLinks.baseUrl}/api/forma_pagamento',
          displayField: 'descricao');

  static Future<List<Map<String, dynamic>>> paises() =>
      load('${ApiLinks.baseUrl}/api/pais', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> estados() =>
      load('${ApiLinks.baseUrl}/api/estados', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> cidades() =>
      load('${ApiLinks.baseUrl}/api/cidade', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> contasBancarias() async {
    final lista = await load(
      '${ApiLinks.baseUrl}/api/contas-bancaria',
      displayField: 'nome',
    );
    return lista.map((item) {
      final descricao = item['descricao']?.toString().trim() ?? '';
      final banco = item['banco']?.toString().trim() ?? '';
      final numero = item['numero']?.toString().trim() ?? '';
      final bancoNumero = [
        if (banco.isNotEmpty) banco,
        if (numero.isNotEmpty) numero,
      ].join(' - ');
      final nome = [
        if (descricao.isNotEmpty) descricao,
        if (bancoNumero.isNotEmpty) bancoNumero,
      ].join(' • ');
      if (nome.isNotEmpty) {
        item['nome'] = nome;
      }
      return item;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> gruposMusculares() =>
      load('${ApiLinks.baseUrl}/api/grupos-musculares', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> tiposExercicio() =>
      load('${ApiLinks.baseUrl}/api/tipo_exercicios', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> cargos() =>
      load('${ApiLinks.baseUrl}/api/cargo', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> departamentos() =>
      load('${ApiLinks.baseUrl}/api/departamento', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> horariosFunc() =>
      load('${ApiLinks.baseUrl}/api/horarioFunc', displayField: 'nome');

  // ---- FieldConfigWindows prontos ----

  /// Campo empresa: pré-selecionado e disabled quando usuário tem empresa em cache.
  /// Se não tem empresa em cache, mostra dropdown normal.
  static FieldConfigWindows empresaField({bool required = false}) {
    final cachedEmpresaId = TenantContext.empresaId;
    return FieldConfigWindows(
      label: 'Empresa', fieldName: 'empresa',
      displayFieldName: 'empresa.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id', dropdownDisplayField: 'nome',
      // Se tem empresa em cache → disabled (não pode trocar)
      enabled: cachedEmpresaId == null,
      isInForm: true, isFilterable: true,
      isRequired: required,
      // Pré-seleciona com o id da empresa do usuário logado
      dropdownSelectedValue: cachedEmpresaId,
      dropdownFutureBuilder: empresas,
    );
  }

  /// Campo parceiro: só aparece no form quando usuário tem parceiro em cache.
  /// Se não tem parceiro em cache, retorna campo suprimido (isInForm: false).
  static FieldConfigWindows parceiroField({bool required = false}) {
    final cachedParceiroId = TenantContext.parceiroId;
    if (cachedParceiroId == null) {
      // Sem parceiro em cache → suprime o campo do form
      return const FieldConfigWindows(
        label: 'Parceiro',
        fieldName: 'parceiro',
        isInForm: false,
        isVisibleByDefault: false,
        enabled: false,
      );
    }
    return FieldConfigWindows(
      label: 'Parceiro', fieldName: 'parceiro',
      displayFieldName: 'parceiro.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id', dropdownDisplayField: 'nome',
      // Pré-selecionado e disabled com o parceiro do usuário logado
      enabled: false,
      isInForm: true, isFilterable: true,
      isRequired: required,
      dropdownSelectedValue: cachedParceiroId,
      dropdownFutureBuilder: parceiros,
    );
  }

  /// Campo parceiro específico para cadastros financeiros.
  /// Quando o usuário já está escopado por parceiro, o campo vem travado.
  /// Quando não está escopado, filtra parceiros pela empresa selecionada
  /// (cascade automático via dependsOnField: 'empresa').
  static FieldConfigWindows parceiroFieldScopedOrSelectable({
    bool required = false,
  }) {
    final cachedParceiroId = TenantContext.parceiroId;
    return FieldConfigWindows(
      label: 'Parceiro',
      fieldName: 'parceiro',
      displayFieldName: 'parceiro.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      enabled: cachedParceiroId == null,
      isInForm: true,
      isFilterable: true,
      isRequired: required,
      dropdownSelectedValue: cachedParceiroId,
      // Cascade: quando livre (sem parceiro fixo), filtra pelo campo 'empresa'
      dependsOnField: cachedParceiroId == null ? 'empresa' : null,
      dropdownFutureBuilderWithParam:
          cachedParceiroId == null ? parceirosPorEmpresa : null,
    );
  }

  static FieldConfigWindows aplicativoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Aplicativo',
        fieldName: 'aplicativo',
        displayFieldName: 'aplicativo.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: aplicativos,
      );

  static FieldConfigWindows setorField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Setor',
        fieldName: 'setor',
        displayFieldName: 'setor.descricao',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'descricao',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: setores,
      );

  static FieldConfigWindows regimeField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Regime Tributário',
        fieldName: 'regime',
        displayFieldName: 'regime.codigo',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'codigo',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: regimes,
      );

  static FieldConfigWindows formaPagamentoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Forma de Pagamento',
        fieldName: 'formaPagamento',
        displayFieldName: 'formaPagamento.descricao',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'descricao',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: formasPagamento,
      );

  static FieldConfigWindows contaBancariaField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Conta Bancária',
        fieldName: 'contaBaixa',
        displayFieldName: 'contaBaixa.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: contasBancarias,
      );

  static FieldConfigWindows grupoMuscularField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Grupo Muscular',
        fieldName: 'grupoMuscular',
        displayFieldName: 'grupoMuscular.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: gruposMusculares,
      );

  static FieldConfigWindows codGrupoMuscularField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Grupo Muscular',
        fieldName: 'codGrupMusc',
        displayFieldName: 'codGrupMusc',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isFilterable: true,
        isRequired: required,
        dropdownFutureBuilder: gruposMusculares,
        fieldOrder: 20,
      );

  static FieldConfigWindows codTipoExercicioField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Tipo de Exercicio',
        fieldName: 'codTipoExerc',
        displayFieldName: 'codTipoExerc',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isFilterable: true,
        isRequired: required,
        dropdownFutureBuilder: tiposExercicio,
        fieldOrder: 30,
      );

  static FieldConfigWindows cargoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Cargo',
        fieldName: 'cargo',
        displayFieldName: 'cargo.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: cargos,
      );

  static FieldConfigWindows departamentoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Departamento',
        fieldName: 'departamento',
        displayFieldName: 'departamento.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: departamentos,
      );

  static FieldConfigWindows horarioFuncField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Horário',
        fieldName: 'horarioFunc',
        displayFieldName: 'horarioFunc.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: horariosFunc,
      );
}
