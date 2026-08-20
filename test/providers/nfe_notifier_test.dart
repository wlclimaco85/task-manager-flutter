import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

@GenerateMocks([NfeRepository])
void main() {
  group('NfeNotifier', () {
    late MockNfeRepository mockRepository;
    late NfeNotifier notifier;

    // Helper para criar NfeModel de teste
    NfeModel createTestNfe({
      required int id,
      required String numero,
      required int serie,
      required String cnpj,
      required NfeStatus status,
      required DateTime dataHora,
      String? tipoOperacao,
    }) {
      return NfeModel(
        id: id,
        empresaId: 1,
        numero: numero,
        serie: serie,
        dataHora: dataHora,
        statusNfe: status,
        cnpjEmitente: '12345678901234',
        uf: 'SP',
        ambiente: 'HOMOLOGACAO',
        tomador: NfeTomadorModel(
          cnpjCpf: cnpj,
          razaoSocial: 'Cliente $id',
          endereco: 'Rua Teste',
          numero: '123',
          bairro: 'Centro',
          cep: '01234567',
          uf: 'SP',
          municipio: 'São Paulo',
        ),
        itens: [],
        valores: ValoresNfeModel(
          subtotal: 1000.0,
          totalIcms: 180.0,
          totalPis: 65.0,
          totalCofins: 76.5,
          desconto: 0,
          total: 1000.0,
        ),
        criadoEm: DateTime.now(),
        tipoOperacao: tipoOperacao,
      );
    }

    setUp(() {
      mockRepository = MockNfeRepository();
      notifier = NfeNotifier(mockRepository);
    });

    tearDown(() {
      notifier.dispose();
    });

    group('sortNfes', () {
      test('sortNfes_cnpj_ascending ordena por CNPJ A→Z', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '99999999999999',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('cnpj', ascending: true);

        // Assert
        expect(notifier.state.nfes.length, 2);
        expect(notifier.state.nfes[0].nfeTomador?.cnpjCpf, '11111111111111');
        expect(notifier.state.nfes[1].nfeTomador?.cnpjCpf, '99999999999999');
      });

      test('sortNfes_cnpj_descending ordena por CNPJ Z→A', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '99999999999999',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('cnpj', ascending: false);

        // Assert
        expect(notifier.state.nfes[0].nfeTomador?.cnpjCpf, '99999999999999');
        expect(notifier.state.nfes[1].nfeTomador?.cnpjCpf, '11111111111111');
      });

      test('sortNfes_data_ascending ordena por data antiga→nova', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 10),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('data', ascending: true);

        // Assert
        expect(notifier.state.nfes[0].numero, '002');
        expect(notifier.state.nfes[1].numero, '001');
      });

      test('sortNfes_numero_ascending ordena por número', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '100',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '005',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('numero', ascending: true);

        // Assert
        expect(notifier.state.nfes[0].numero, '005');
        expect(notifier.state.nfes[1].numero, '100');
      });

      test('sortNfes_serie_ascending ordena por série', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 5,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 2,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('serie', ascending: true);

        // Assert
        expect(notifier.state.nfes[0].serie, 2);
        expect(notifier.state.nfes[1].serie, 5);
      });

      test('sortNfes_status_ascending ordena por status A→Z', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.rascunho,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.sortNfes('status', ascending: true);

        // Assert
        expect(notifier.state.nfes[0].statusNfe, NfeStatus.autorizada);
        expect(notifier.state.nfes[1].statusNfe, NfeStatus.rascunho);
      });

      test('sortNfes_invalid_field logs warning and returns', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));
        final originalList = notifier.state.nfes;

        // Act
        await notifier.sortNfes('campo_invalido', ascending: true);

        // Assert - lista deve permanecer igual
        expect(notifier.state.nfes, originalList);
      });
    });

    group('filterByStatus', () {
      test('filterByStatus_autorizada retorna só autorizadas', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.cancelada,
          dataHora: DateTime(2026, 8, 2),
        );
        final nfe3 = createTestNfe(
          id: 3,
          numero: '003',
          serie: 1,
          cnpj: '33333333333333',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 3),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2, nfe3]));

        // Act
        await notifier.filterByStatus('AUTORIZADA');

        // Assert
        expect(notifier.state.nfes.length, 2);
        expect(notifier.state.nfes.every((nfe) => nfe.statusNfe == NfeStatus.autorizada), true);
      });

      test('filterByStatus_cancelada retorna só canceladas', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.cancelada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.filterByStatus('CANCELADA');

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].statusNfe, NfeStatus.cancelada);
      });

      test('filterByStatus_nenhuma_correspondencia retorna vazio', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));

        // Act
        await notifier.filterByStatus('REJEITADA');

        // Assert
        expect(notifier.state.nfes.isEmpty, true);
      });
    });

    group('filterByTipoOperacao', () {
      test('filterByTipoOperacao_saida retorna só saidas', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
          tipoOperacao: 'SAIDA',
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
          tipoOperacao: 'ENTRADA',
        );
        final nfe3 = createTestNfe(
          id: 3,
          numero: '003',
          serie: 1,
          cnpj: '33333333333333',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 3),
          tipoOperacao: 'SAIDA',
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2, nfe3]));

        // Act
        await notifier.filterByTipoOperacao('SAIDA');

        // Assert
        expect(notifier.state.nfes.length, 2);
        expect(notifier.state.nfes.every((nfe) => nfe.tipoOperacao == 'SAIDA'), true);
      });

      test('filterByTipoOperacao_entrada retorna só entradas', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
          tipoOperacao: 'SAIDA',
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
          tipoOperacao: 'ENTRADA',
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.filterByTipoOperacao('ENTRADA');

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].tipoOperacao, 'ENTRADA');
      });

      test('filterByTipoOperacao_case_insensitive', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
          tipoOperacao: 'SAIDA',
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));

        // Act
        await notifier.filterByTipoOperacao('saida');

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].tipoOperacao, 'SAIDA');
      });
    });

    group('filterByDateRange', () {
      test('filterByDateRange_valido filtra corretamente', () async {
        // Arrange
        final inicio = DateTime(2026, 8, 5);
        final fim = DateTime(2026, 8, 15);

        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 10),
        );
        final nfe3 = createTestNfe(
          id: 3,
          numero: '003',
          serie: 1,
          cnpj: '33333333333333',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 20),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2, nfe3]));

        // Act
        await notifier.filterByDateRange(inicio, fim);

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].numero, '002');
      });

      test('filterByDateRange_vazio sem correspondencias', () async {
        // Arrange
        final inicio = DateTime(2026, 9, 1);
        final fim = DateTime(2026, 9, 30);

        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));

        // Act
        await notifier.filterByDateRange(inicio, fim);

        // Assert
        expect(notifier.state.nfes.isEmpty, true);
      });

      test('filterByDateRange_apenas_inicio', () async {
        // Arrange
        final inicio = DateTime(2026, 8, 5);

        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 10),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.filterByDateRange(inicio, null);

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].numero, '002');
      });
    });

    group('applyFiltersAndSort', () {
      test('applyFiltersAndSort_combined filtro + ordenação', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '100',
          serie: 1,
          cnpj: '99999999999999',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
          tipoOperacao: 'SAIDA',
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '005',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
          tipoOperacao: 'SAIDA',
        );
        final nfe3 = createTestNfe(
          id: 3,
          numero: '003',
          serie: 1,
          cnpj: '55555555555555',
          status: NfeStatus.cancelada,
          dataHora: DateTime(2026, 8, 3),
          tipoOperacao: 'ENTRADA',
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2, nfe3]));

        // Act
        await notifier.applyFiltersAndSort(
          statusFilter: 'AUTORIZADA',
          tipoOperacaoFilter: 'SAIDA',
          sortBy: 'numero',
          sortAscending: true,
        );

        // Assert
        expect(notifier.state.nfes.length, 2);
        expect(notifier.state.nfes[0].numero, '005');
        expect(notifier.state.nfes[1].numero, '100');
      });

      test('applyFiltersAndSort_apenas filtro', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.cancelada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.applyFiltersAndSort(statusFilter: 'AUTORIZADA');

        // Assert
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.nfes[0].statusNfe, NfeStatus.autorizada);
      });

      test('applyFiltersAndSort_apenas sort', () async {
        // Arrange
        final nfe1 = createTestNfe(
          id: 1,
          numero: '100',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfe2 = createTestNfe(
          id: 2,
          numero: '005',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 2),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1, nfe2]));

        // Act
        await notifier.applyFiltersAndSort(sortBy: 'numero', sortAscending: true);

        // Assert
        expect(notifier.state.nfes.length, 2);
        expect(notifier.state.nfes[0].numero, '005');
        expect(notifier.state.nfes[1].numero, '100');
      });
    });

    group('clearFilters', () {
      test('clearFilters_chama listarNfe e restaura estado', () async {
        // Arrange
        final nfesOriginais = [
          createTestNfe(
            id: 1,
            numero: '001',
            serie: 1,
            cnpj: '11111111111111',
            status: NfeStatus.autorizada,
            dataHora: DateTime(2026, 8, 1),
          ),
          createTestNfe(
            id: 2,
            numero: '002',
            serie: 1,
            cnpj: '22222222222222',
            status: NfeStatus.autorizada,
            dataHora: DateTime(2026, 8, 2),
          ),
        ];

        when(mockRepository.listarNfe(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          status: anyNamed('status'),
          tipoOperacao: anyNamed('tipoOperacao'),
          dataInicio: anyNamed('dataInicio'),
          dataFim: anyNamed('dataFim'),
          clienteCnpj: anyNamed('clienteCnpj'),
        )).thenAnswer((_) async => {'items': nfesOriginais, 'totalRecords': nfesOriginais.length});

        // Act
        await notifier.clearFilters();

        // Assert
        verify(mockRepository.listarNfe(
          page: 1,
          pageSize: 10,
          status: null,
          tipoOperacao: null,
          dataInicio: null,
          dataFim: null,
          clienteCnpj: null,
        )).called(1);
        expect(notifier.state.nfes.length, 2);
      });
    });

    group('listarNfe error handling', () {
      test('listarNfe_handles_401_error', () async {
        // Arrange
        when(mockRepository.listarNfe(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          status: anyNamed('status'),
          tipoOperacao: anyNamed('tipoOperacao'),
          dataInicio: anyNamed('dataInicio'),
          dataFim: anyNamed('dataFim'),
          clienteCnpj: anyNamed('clienteCnpj'),
        )).thenThrow(NfeApiException('Não autorizado (401)', statusCode: 401));

        // Act
        await notifier.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(notifier.state.hasError, true);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.nfes.isEmpty, true);
      });

      test('listarNfe_handles_500_error', () async {
        // Arrange
        when(mockRepository.listarNfe(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          status: anyNamed('status'),
          tipoOperacao: anyNamed('tipoOperacao'),
          dataInicio: anyNamed('dataInicio'),
          dataFim: anyNamed('dataFim'),
          clienteCnpj: anyNamed('clienteCnpj'),
        )).thenThrow(NfeRepositoryException('Server error'));

        // Act
        await notifier.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(notifier.state.hasError, true);
        expect(notifier.state.errorMessage, contains('Server error'));
        expect(notifier.state.isLoading, false);
      });

      test('listarNfe_handles_generic_error', () async {
        // Arrange
        when(mockRepository.listarNfe(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          status: anyNamed('status'),
          tipoOperacao: anyNamed('tipoOperacao'),
          dataInicio: anyNamed('dataInicio'),
          dataFim: anyNamed('dataFim'),
          clienteCnpj: anyNamed('clienteCnpj'),
        )).thenThrow(Exception('Unexpected error'));

        // Act
        await notifier.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(notifier.state.hasError, true);
        expect(notifier.state.isLoading, false);
      });
    });

    group('filterBy refetch', () {
      test('filterBy_refetch_com_status muda página para 1 e refetch', () async {
        // Arrange
        final nfeAutorizada = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );
        final nfeRascunho = createTestNfe(
          id: 2,
          numero: '002',
          serie: 1,
          cnpj: '22222222222222',
          status: NfeStatus.rascunho,
          dataHora: DateTime(2026, 8, 2),
        );

        when(mockRepository.listarNfe(
          page: 1,
          pageSize: 10,
          status: 'AUTORIZADA',
          tipoOperacao: null,
          dataInicio: null,
          dataFim: null,
          clienteCnpj: null,
        )).thenAnswer((_) async => {
          'items': [nfeAutorizada],
          'totalRecords': 1,
        });

        // Act
        await notifier.filterBy(status: 'AUTORIZADA');

        // Assert
        verify(mockRepository.listarNfe(
          page: 1,
          pageSize: 10,
          status: 'AUTORIZADA',
          tipoOperacao: null,
          dataInicio: null,
          dataFim: null,
          clienteCnpj: null,
        )).called(1);
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.nfes.length, 1);
        expect(notifier.state.totalRecords, 1);
      });

      test('filterBy_refetch_com_data_range', () async {
        // Arrange
        final nfe = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 15),
        );
        final inicio = DateTime(2026, 8, 1);
        final fim = DateTime(2026, 8, 31);

        when(mockRepository.listarNfe(
          page: 1,
          pageSize: 10,
          status: null,
          tipoOperacao: null,
          dataInicio: inicio,
          dataFim: fim,
          clienteCnpj: null,
        )).thenAnswer((_) async => {
          'items': [nfe],
          'totalRecords': 1,
        });

        // Act
        await notifier.filterBy(dataInicio: inicio, dataFim: fim);

        // Assert
        verify(mockRepository.listarNfe(
          page: 1,
          pageSize: 10,
          status: null,
          tipoOperacao: null,
          dataInicio: inicio,
          dataFim: fim,
          clienteCnpj: null,
        )).called(1);
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.nfes.length, 1);
      });
    });

    group('notifyListeners', () {
      test('sortNfes notifica listeners', () async {
        // Arrange
        var notified = false;
        notifier.addListener(() {
          notified = true;
        });

        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));
        notified = false;

        // Act
        await notifier.sortNfes('numero');

        // Assert
        expect(notified, true);
      });

      test('filterByStatus notifica listeners', () async {
        // Arrange
        var notified = false;
        notifier.addListener(() {
          notified = true;
        });

        final nfe1 = createTestNfe(
          id: 1,
          numero: '001',
          serie: 1,
          cnpj: '11111111111111',
          status: NfeStatus.autorizada,
          dataHora: DateTime(2026, 8, 1),
        );

        notifier.setTestState(notifier.state.copyWith(nfes: [nfe1]));
        notified = false;

        // Act
        await notifier.filterByStatus('AUTORIZADA');

        // Assert
        expect(notified, true);
      });
    });
  });
}
