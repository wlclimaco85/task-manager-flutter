import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

/// Stub simples de repositório para testes
class StubNfeRepository implements NfeRepository {
  List<NfeModel> _mockNfes = [];
  bool _shouldFail = false;
  String _errorMessage = '';

  void setMockData(List<NfeModel> nfes) => _mockNfes = nfes;
  void setFail(String message) {
    _shouldFail = true;
    _errorMessage = message;
  }

  void reset() {
    _mockNfes = [];
    _shouldFail = false;
    _errorMessage = '';
  }

  @override
  Future<List<NfeModel>> listarNfe({
    required int page,
    required int pageSize,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    if (_shouldFail) throw Exception(_errorMessage);
    return _mockNfes;
  }

  @override
  Future<NfeModel> obterNfe(int id) async {
    if (_shouldFail) throw Exception(_errorMessage);
    return _mockNfes.firstWhere((nfe) => nfe.id == id);
  }

  @override
  Future<String> downloadXml(int id) async => '<xml></xml>';

  @override
  Future<List<int>> downloadPdf(int id) async => [];
}

void main() {
  late StubNfeRepository stubRepository;
  late NfeNotifier notifier;

  final testNfe = NfeModel(
    id: 1,
    empresaId: 200001,
    numero: '000001',
    serie: 1,
    dataHora: DateTime.now(),
    statusNfe: NfeStatus.pendente,
    cnpjEmitente: '12345678901234',
    uf: 'SP',
    ambiente: 'HOMOLOGACAO',
    tomador: const NfeTomadorModel(
      cnpjCpf: '98765432109876',
      razaoSocial: 'Cliente XYZ Ltda',
      endereco: 'Rua Teste, 123',
      numero: '123',
      bairro: 'Centro',
      cep: '01234567',
      uf: 'SP',
      municipio: 'São Paulo',
    ),
    itens: [],
    valores: ValoresNfeModel(
      subtotal: 1000,
      totalIcms: 180,
      totalPis: 65,
      totalCofins: 300,
      desconto: 0,
      total: 1545,
    ),
    criadoEm: DateTime.now(),
  );

  setUp(() {
    stubRepository = StubNfeRepository();
    notifier = NfeNotifier(stubRepository);
  });

  group('NfeNotifier - Testes de Estado', () {
    test('Estado inicial deve estar vazio', () {
      expect(notifier.state.nfes, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('Getters de estado funcionam corretamente', () {
      expect(notifier.state.hasError, false);
      expect(notifier.state.isEmpty, true);
      expect(notifier.state.totalPages, greaterThanOrEqualTo(1));
      expect(notifier.state.canNextPage, false);
      expect(notifier.state.canPreviousPage, false);
    });

    test('copyWith cria nova instância', () {
      final newState = notifier.state.copyWith(
        nfes: [testNfe],
        isLoading: true,
      );
      expect(newState.nfes.length, 1);
      expect(newState.isLoading, true);
      expect(notifier.state.nfes, isEmpty);
    });

    test('limparErro remove mensagem de erro', () {
      final stateWithError = notifier.state.copyWith(
        errorMessage: 'Erro teste',
      );
      expect(stateWithError.hasError, true);

      // Simula carregamento com erro
      notifier.limparErro();
      expect(notifier.state.errorMessage, isNull);
    });

    test('resetarEstado limpa tudo', () {
      // Cria estado com dados
      final stateWithData = notifier.state.copyWith(
        nfes: [testNfe],
        selected: testNfe,
        errorMessage: 'Erro',
        currentPage: 2,
      );

      expect(stateWithData.nfes.length, 1);
      expect(stateWithData.selected, isNotNull);

      // Reset
      notifier.resetarEstado();
      expect(notifier.state.nfes, isEmpty);
      expect(notifier.state.selected, isNull);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.currentPage, 1);
    });
  });

  group('NfeNotifier - Listagem', () {
    test('listarNfe carrega NFes com sucesso', () async {
      stubRepository.setMockData([testNfe]);

      await notifier.listarNfe();

      expect(notifier.state.nfes.length, 1);
      expect(notifier.state.nfes[0].id, testNfe.id);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('listarNfe atualiza página', () async {
      stubRepository.setMockData([testNfe]);

      await notifier.listarNfe(page: 2, pageSize: 20);

      expect(notifier.state.currentPage, 2);
      expect(notifier.state.pageSize, 20);
    });

    test('listarNfe com erro preenchenerrorMessage', () async {
      stubRepository.setFail('Erro conexão');

      await notifier.listarNfe();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.nfes, isEmpty);
    });
  });

  group('NfeNotifier - Manipulação Local', () {
    test('removerNfeLocal remove NFe da lista', () async {
      stubRepository.setMockData([testNfe]);
      await notifier.listarNfe();
      expect(notifier.state.nfes.length, 1);

      notifier.removerNfeLocal(1);

      expect(notifier.state.nfes, isEmpty);
    });

    test('Descrição de estado para debugging', () {
      final desc1 = notifier.state.stateDescription;
      expect(desc1, contains('EMPTY'));

      final stateLoading = notifier.state.copyWith(isLoading: true);
      expect(stateLoading.stateDescription, contains('LOADING'));

      final stateError = notifier.state.copyWith(errorMessage: 'Erro');
      expect(stateError.stateDescription, contains('ERROR'));
    });
  });

  group('NfeNotifier - Paginação', () {
    test('totalPages calcula corretamente', () {
      final state1 = NfeState(
        nfes: List.generate(25, (i) => testNfe),
        isLoading: false,
        pageSize: 10,
      );
      expect(state1.totalPages, 3);

      final state2 = NfeState(
        nfes: List.generate(30, (i) => testNfe),
        isLoading: false,
        pageSize: 10,
      );
      expect(state2.totalPages, 3);
    });

    test('canNextPage verifica limite corretamente', () {
      final state = NfeState(
        nfes: List.generate(25, (i) => testNfe),
        isLoading: false,
        currentPage: 1,
        pageSize: 10,
      );
      expect(state.canNextPage, true); // página 1 de 3

      final state2 = state.copyWith(currentPage: 3);
      expect(state2.canNextPage, false); // última página
    });

    test('canPreviousPage verifica corretamente', () {
      final state = NfeState(
        nfes: [testNfe],
        isLoading: false,
        currentPage: 1,
      );
      expect(state.canPreviousPage, false); // primeira página

      final state2 = state.copyWith(currentPage: 2);
      expect(state2.canPreviousPage, true);
    });
  });
}
