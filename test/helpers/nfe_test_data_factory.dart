import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';

/// Factory para gerar dados fictícios (test doubles) para NFes
///
/// Fornece métodos para criar NfeModel, NfeTomadorModel, ValoresNfeModel
/// com valores padrão consistentes, permitindo customização parcial.
///
/// Uso:
/// ```dart
/// final nfe = NfeTestDataFactory.createNfe(numero: '000002');
/// final nfes = NfeTestDataFactory.createNfeList(10);
/// ```
class NfeTestDataFactory {
  // ============================================================================
  // CONSTANTES PADRÃO
  // ============================================================================

  static const String _defaultCnpjEmitente = '12345678901234';
  static const String _defaultCnpjCliente = '98765432109876';
  static const int _defaultEmpresaId = 200001;
  static const String _defaultUf = 'SP';
  static const String _defaultAmbiente = 'HOMOLOGACAO';

  // ============================================================================
  // NFE MODEL FACTORY
  // ============================================================================

  /// Cria NfeModel com valores padrão customizáveis
  ///
  /// Parâmetros:
  /// - [id]: ID único (padrão: 1)
  /// - [numero]: Número da NFe (padrão: '000001')
  /// - [serie]: Série da NFe (padrão: 1)
  /// - [status]: Status da NFe (padrão: pendente)
  /// - [razaoSocial]: Razão social do cliente (padrão: 'Cliente XYZ Ltda')
  /// - [subtotal]: Valor subtotal (padrão: 1000.0)
  /// - [cnpjEmitente]: CNPJ da empresa (padrão: constante)
  /// - [empresaId]: ID da empresa (padrão: constante)
  static NfeModel createNfe({
    int id = 1,
    String numero = '000001',
    int serie = 1,
    NfeStatus status = NfeStatus.pendente,
    String razaoSocial = 'Cliente XYZ Ltda',
    double subtotal = 1000.0,
    String cnpjEmitente = _defaultCnpjEmitente,
    int empresaId = _defaultEmpresaId,
    String uf = _defaultUf,
    String ambiente = _defaultAmbiente,
    DateTime? dataHora,
  }) {
    dataHora ??= DateTime.now();

    return NfeModel(
      id: id,
      numero: numero,
      serie: serie,
      statusNfe: status,
      empresaId: empresaId,
      cnpjEmitente: cnpjEmitente,
      uf: uf,
      ambiente: ambiente,
      dataHora: dataHora,
      tomador: NfeTomadorModel(
        cnpjCpf: _defaultCnpjCliente,
        razaoSocial: razaoSocial,
        endereco: 'Rua Teste, 123',
        numero: '123',
        bairro: 'Centro',
        cep: '01234567',
        uf: uf,
        municipio: 'São Paulo',
      ),
      valores: ValoresNfeModel(
        subtotal: subtotal,
        totalIcms: (subtotal * 0.18).toDouble(),
        totalPis: (subtotal * 0.065).toDouble(),
        totalCofins: (subtotal * 0.30).toDouble(),
        desconto: 0,
        total: (subtotal * 1.545).toDouble(),
      ),
      itens: [],
      criadoEm: dataHora,
    );
  }

  /// Cria lista de NFes com IDs e números sequenciais
  ///
  /// Usa [count] para determinar quantidade
  /// Alterna status entre pendente e autorizada
  static List<NfeModel> createNfeList(
    int count, {
    String baseNumero = '000001',
    NfeStatus? defaultStatus,
  }) {
    return List.generate(
      count,
      (i) => createNfe(
        id: i + 1,
        numero: (int.parse(baseNumero) + i).toString().padLeft(6, '0'),
        status: defaultStatus ??
            (i % 2 == 0 ? NfeStatus.pendente : NfeStatus.autorizada),
        razaoSocial: 'Cliente ${i + 1} LTDA',
        subtotal: 1000.0 + (i * 100.0),
      ),
    );
  }

  /// Cria lista de NFes por status específico
  ///
  /// Útil para testes de filtro por status
  static List<NfeModel> createNfeListByStatus(
    int count,
    NfeStatus status,
  ) =>
      List.generate(
        count,
        (i) => createNfe(
          id: i + 1,
          numero: '00000${i + 1}'.padLeft(6, '0'),
          status: status,
          razaoSocial: 'Cliente ${i + 1} LTDA',
        ),
      );

  // ============================================================================
  // TOMADOR MODEL FACTORY
  // ============================================================================

  /// Cria NfeTomadorModel com dados padrão
  static NfeTomadorModel createTomador({
    String cnpjCpf = _defaultCnpjCliente,
    String razaoSocial = 'Cliente Padrão Ltda',
    String endereco = 'Rua Teste, 123',
    String numero = '123',
    String bairro = 'Centro',
    String cep = '01234567',
    String uf = _defaultUf,
    String municipio = 'São Paulo',
  }) =>
      NfeTomadorModel(
        cnpjCpf: cnpjCpf,
        razaoSocial: razaoSocial,
        endereco: endereco,
        numero: numero,
        bairro: bairro,
        cep: cep,
        uf: uf,
        municipio: municipio,
      );

  // ============================================================================
  // VALORES NFE FACTORY
  // ============================================================================

  /// Cria ValoresNfeModel com cálculos automáticos
  ///
  /// Calcula automaticamente:
  /// - totalIcms = subtotal * 18%
  /// - totalPis = subtotal * 6.5%
  /// - totalCofins = subtotal * 30%
  /// - total = subtotal + impostos - desconto
  static ValoresNfeModel createValores({
    double subtotal = 1000.0,
    double icmsPercent = 0.18,
    double pisPercent = 0.065,
    double cofinsPercent = 0.30,
    double desconto = 0,
  }) {
    final totalIcms = subtotal * icmsPercent;
    final totalPis = subtotal * pisPercent;
    final totalCofins = subtotal * cofinsPercent;
    final total = subtotal + totalIcms + totalPis + totalCofins - desconto;

    return ValoresNfeModel(
      subtotal: subtotal,
      totalIcms: totalIcms,
      totalPis: totalPis,
      totalCofins: totalCofins,
      desconto: desconto,
      total: total,
    );
  }

  // ============================================================================
  // NFE STATE FACTORY
  // ============================================================================

  /// Cria NfeState vazio (padrão)
  static NfeState createEmptyState() => NfeState(
    nfes: [],
    selected: null,
    isLoading: false,
    errorMessage: null,
    currentPage: 1,
    pageSize: 10,
  );

  /// Cria NfeState em estado de loading
  static NfeState createLoadingState() => NfeState(
    nfes: [],
    selected: null,
    isLoading: true,
    errorMessage: null,
    currentPage: 1,
    pageSize: 10,
  );

  /// Cria NfeState com erro
  static NfeState createErrorState(String message) => NfeState(
    nfes: [],
    selected: null,
    isLoading: false,
    errorMessage: message,
    currentPage: 1,
    pageSize: 10,
  );

  /// Cria NfeState com sucesso (dados carregados)
  static NfeState createSuccessState(
    List<NfeModel> nfes, {
    int currentPage = 1,
    int pageSize = 10,
  }) =>
      NfeState(
        nfes: nfes,
        selected: null,
        isLoading: false,
        errorMessage: null,
        currentPage: currentPage,
        pageSize: pageSize,
      );

  /// Cria NfeState com uma NFe selecionada
  static NfeState createSelectedState(NfeModel nfe) => NfeState(
    nfes: [nfe],
    selected: nfe,
    isLoading: false,
    errorMessage: null,
    currentPage: 1,
    pageSize: 10,
  );

  // ============================================================================
  // HELPERS PARA DADOS ESPECÍFICOS
  // ============================================================================

  /// Cria NFe com status PENDENTE
  static NfeModel createPendingNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        status: NfeStatus.pendente,
      );

  /// Cria NFe com status AUTORIZADA
  static NfeModel createAuthorizedNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        status: NfeStatus.autorizada,
      );

  /// Cria NFe com status REJEITADA
  static NfeModel createRejectedNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        status: NfeStatus.rejeitada,
      );

  /// Cria NFe com status CANCELADA
  static NfeModel createCanceledNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        status: NfeStatus.cancelada,
      );

  /// Cria NFe com subtotal alto (para testes de formatação de valor)
  static NfeModel createHighValueNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        subtotal: 999999.99,
      );

  /// Cria NFe com subtotal baixo (para testes de arredondamento)
  static NfeModel createLowValueNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        subtotal: 0.99,
      );

  /// Cria NFe com razão social longa (testa truncamento de texto)
  static NfeModel createLongNameNfe({
    int id = 1,
    String numero = '000001',
  }) =>
      createNfe(
        id: id,
        numero: numero,
        razaoSocial:
            'Empresa Teste Muito Longa LTDA Especializada em Negócios Estranhos',
      );

  // ============================================================================
  // HELPERS PARA ESTRUTURAS COMPLEXAS
  // ============================================================================

  /// Cria lista representando resultado de paginação (primeira página)
  static List<NfeModel> createPaginatedNfeFirstPage({
    int pageSize = 10,
    int baseId = 1,
  }) =>
      createNfeList(pageSize);

  /// Cria lista representando resultado de paginação (página seguinte)
  static List<NfeModel> createPaginatedNfeNextPage({
    int pageSize = 10,
    int baseId = 11,
  }) =>
      List.generate(
        pageSize,
        (i) => createNfe(
          id: baseId + i,
          numero: '00000${baseId + i}'.padLeft(6, '0'),
        ),
      );

  /// Cria lista com mix de status (padrão para testes de filtro)
  static List<NfeModel> createMixedStatusList() => [
    createPendingNfe(id: 1, numero: '000001'),
    createAuthorizedNfe(id: 2, numero: '000002'),
    createRejectedNfe(id: 3, numero: '000003'),
    createCanceledNfe(id: 4, numero: '000004'),
    createPendingNfe(id: 5, numero: '000005'),
    createAuthorizedNfe(id: 6, numero: '000006'),
  ];

  // ============================================================================
  // HELPERS PARA DATES
  // ============================================================================

  /// Cria NFe com data específica (útil para testes de filtro por data)
  static NfeModel createNfeWithDate({
    int id = 1,
    String numero = '000001',
    required DateTime date,
  }) =>
      createNfe(
        id: id,
        numero: numero,
        dataHora: date,
      );

  /// Cria NFe de hoje
  static NfeModel createTodayNfe({int id = 1}) =>
      createNfeWithDate(
        id: id,
        date: DateTime.now(),
      );

  /// Cria NFe de ontem
  static NfeModel createYesterdayNfe({int id = 1}) =>
      createNfeWithDate(
        id: id,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

  /// Cria NFe de uma semana atrás
  static NfeModel createWeekAgoNfe({int id = 1}) =>
      createNfeWithDate(
        id: id,
        date: DateTime.now().subtract(const Duration(days: 7)),
      );

  /// Cria NFe de um mês atrás
  static NfeModel createMonthAgoNfe({int id = 1}) =>
      createNfeWithDate(
        id: id,
        date: DateTime.now().subtract(const Duration(days: 30)),
      );
}
