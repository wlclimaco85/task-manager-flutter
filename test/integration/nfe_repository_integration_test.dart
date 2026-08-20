import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

@GenerateMocks([Dio])
void main() {
  group('NfeRepository Integration Tests', () {
    late MockDio mockDio;
    late NfeRepository repository;

    setUp(() {
      mockDio = MockDio();
      repository = NfeRepository(dio: mockDio);
    });

    group('listarNfe', () {
      test('listarNfe_parsea JSON response corretamente', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'content': [
              {
                'id': 1,
                'empresaId': 1,
                'numero': '000001',
                'serie': 1,
                'dataHora': '2026-08-04T10:30:00Z',
                'statusNfe': 'AUTORIZADA',
                'cnpjEmitente': '12345678901234',
                'uf': 'SP',
                'ambiente': 'HOMOLOGACAO',
                'tipoOperacao': 'SAIDA',
                'tomador': {
                  'cnpjCpf': '98765432109876',
                  'razaoSocial': 'Cliente LTDA',
                  'endereco': 'Rua Teste, 123',
                  'numero': '123',
                  'bairro': 'Centro',
                  'cep': '01234567',
                  'uf': 'SP',
                  'municipio': 'São Paulo',
                },
                'itens': [],
                'valores': {
                  'subtotal': 1000.00,
                  'totalIcms': 180.00,
                  'totalPis': 65.00,
                  'totalCofins': 76.50,
                  'desconto': 0,
                  'total': 1000.00,
                },
                'criadoEm': '2026-08-04T10:30:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(
          page: 1,
          pageSize: 10,
          status: 'AUTORIZADA',
        );

        // Assert
        expect(nfes, isNotEmpty);
        expect(nfes.length, 1);
        expect(nfes[0].id, 1);
        expect(nfes[0].numero, '000001');
        expect(nfes[0].statusNfe.toString(), contains('autorizada'));
        expect(nfes[0].tipoOperacao, 'SAIDA');
        expect(nfes[0].nfeTomador.razaoSocial, 'Cliente LTDA');
        expect(nfes[0].nfeTomador.cnpjCpf, '98765432109876');
      });

      test('listarNfe com parâmetros status e tipoOperacao', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'content': [
              {
                'id': 2,
                'empresaId': 1,
                'numero': '000002',
                'serie': 1,
                'dataHora': '2026-08-05T14:00:00Z',
                'statusNfe': 'AUTORIZADA',
                'cnpjEmitente': '12345678901234',
                'uf': 'SP',
                'ambiente': 'HOMOLOGACAO',
                'tipoOperacao': 'ENTRADA',
                'tomador': {
                  'cnpjCpf': '98765432109876',
                  'razaoSocial': 'Fornecedor Inc',
                  'endereco': 'Av. Paulista',
                  'numero': '1000',
                  'bairro': 'Bela Vista',
                  'cep': '01311100',
                  'uf': 'SP',
                  'municipio': 'São Paulo',
                },
                'itens': [],
                'valores': {
                  'subtotal': 5000.00,
                  'totalIcms': 900.00,
                  'totalPis': 325.00,
                  'totalCofins': 382.50,
                  'desconto': 0,
                  'total': 5000.00,
                },
                'criadoEm': '2026-08-05T14:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(
          any,
          queryParameters: argThat(isA<Map<String, dynamic>>()
              .having((m) => m['status'], 'status', 'AUTORIZADA')
              .having((m) => m['tipoOperacao'], 'tipoOperacao', 'ENTRADA')),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(
          page: 1,
          pageSize: 10,
          status: 'AUTORIZADA',
          tipoOperacao: 'ENTRADA',
        );

        // Assert
        expect(nfes.length, 1);
        expect(nfes[0].tipoOperacao, 'ENTRADA');
        verify(mockDio.get(
          any,
          queryParameters: argThat(isA<Map<String, dynamic>>()
              .having((m) => m['status'], 'status', 'AUTORIZADA')
              .having((m) => m['tipoOperacao'], 'tipoOperacao', 'ENTRADA')),
          options: anyNamed('options'),
        )).called(1);
      });

      test('listarNfe com date range parameters', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'content': [],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(
          any,
          queryParameters: argThat(isA<Map<String, dynamic>>()
              .having((m) => m['dataInicio'], 'dataInicio', '2026-08-01')
              .having((m) => m['dataFim'], 'dataFim', '2026-08-31')),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(
          page: 1,
          pageSize: 10,
          dataInicio: DateTime(2026, 8, 1),
          dataFim: DateTime(2026, 8, 31),
        );

        // Assert
        expect(nfes, isEmpty);
        verify(mockDio.get(
          any,
          queryParameters: argThat(isA<Map<String, dynamic>>()
              .having((m) => m['dataInicio'], 'dataInicio', '2026-08-01')
              .having((m) => m['dataFim'], 'dataFim', '2026-08-31')),
          options: anyNamed('options'),
        )).called(1);
      });

      test('listarNfe trata resposta sem content wrapper', () async {
        // Arrange - backend pode retornar array direto
        final mockResponse = Response(
          data: [
            {
              'id': 3,
              'empresaId': 1,
              'numero': '000003',
              'serie': 1,
              'dataHora': '2026-08-06T09:00:00Z',
              'statusNfe': 'RASCUNHO',
              'cnpjEmitente': '12345678901234',
              'uf': 'MG',
              'ambiente': 'HOMOLOGACAO',
              'tomador': {
                'cnpjCpf': '55555555555555',
                'razaoSocial': 'Empresa XYZ',
                'endereco': 'Rua ABC',
                'numero': '456',
                'bairro': 'Centro',
                'cep': '30000000',
                'uf': 'MG',
                'municipio': 'Belo Horizonte',
              },
              'itens': [],
              'valores': {
                'subtotal': 0,
                'totalIcms': 0,
                'totalPis': 0,
                'totalCofins': 0,
                'desconto': 0,
                'total': 0,
              },
              'criadoEm': '2026-08-06T09:00:00Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(nfes.length, 1);
        expect(nfes[0].numero, '000003');
      });
    });

    group('listarNfe error handling', () {
      test('listarNfe handles 401 Unauthorized', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/nfe/listar'),
            data: {'message': 'Unauthorized'},
          ),
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeApiException>()),
        );
      });

      test('listarNfe handles 403 Forbidden', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/api/nfe/listar'),
            data: {'message': 'Forbidden'},
          ),
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeApiException>()),
        );
      });

      test('listarNfe handles 404 Not Found', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/api/nfe/listar'),
            data: {'message': 'Not Found'},
          ),
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeRepositoryException>()),
        );
      });

      test('listarNfe handles 500 Server Error', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/nfe/listar'),
            data: {'message': 'Internal server error'},
          ),
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeRepositoryException>()),
        );
      });

      test('listarNfe handles connection timeout', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeRepositoryException>()),
        );
      });

      test('listarNfe handles network error', () async {
        // Arrange
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
          type: DioExceptionType.unknown,
          error: Exception('Network error'),
        ));

        // Act & Assert
        expect(
          () => repository.listarNfe(page: 1, pageSize: 10),
          throwsA(isA<NfeRepositoryException>()),
        );
      });
    });

    group('listarNfe parsing edge cases', () {
      test('listarNfe handles null fields gracefully', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'content': [
              {
                'id': 4,
                'empresaId': 1,
                'numero': '000004',
                'serie': 1,
                'dataHora': '2026-08-07T11:00:00Z',
                'statusNfe': 'AUTORIZADA',
                'cnpjEmitente': '12345678901234',
                'uf': 'RJ',
                'ambiente': 'PRODUCAO',
                // tipoOperacao é null
                'tipoOperacao': null,
                'tomador': {
                  'cnpjCpf': '77777777777777',
                  'razaoSocial': 'Empresa RJ',
                  'endereco': 'Rua Rio',
                  'numero': '789',
                  'bairro': 'Leblon',
                  'cep': '22440000',
                  'uf': 'RJ',
                  'municipio': 'Rio de Janeiro',
                },
                'itens': [],
                'valores': {
                  'subtotal': 2000.00,
                  'totalIcms': 360.00,
                  'totalPis': 130.00,
                  'totalCofins': 153.00,
                  'desconto': 0,
                  'total': 2000.00,
                },
                'criadoEm': '2026-08-07T11:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(nfes.length, 1);
        expect(nfes[0].tipoOperacao, isNull);
        expect(nfes[0].nfeTomador.razaoSocial, 'Empresa RJ');
      });

      test('listarNfe handles empty itens list', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'content': [
              {
                'id': 5,
                'empresaId': 1,
                'numero': '000005',
                'serie': 2,
                'dataHora': '2026-08-08T15:30:00Z',
                'statusNfe': 'RASCUNHO',
                'cnpjEmitente': '12345678901234',
                'uf': 'BA',
                'ambiente': 'HOMOLOGACAO',
                'tipoOperacao': 'DEVOLUCAO',
                'tomador': {
                  'cnpjCpf': '88888888888888',
                  'razaoSocial': 'Empresa BA',
                  'endereco': 'Rua Salvador',
                  'numero': '321',
                  'bairro': 'Barra',
                  'cep': '42850700',
                  'uf': 'BA',
                  'municipio': 'Salvador',
                },
                'itens': [],
                'valores': {
                  'subtotal': 0,
                  'totalIcms': 0,
                  'totalPis': 0,
                  'totalCofins': 0,
                  'desconto': 0,
                  'total': 0,
                },
                'criadoEm': '2026-08-08T15:30:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(nfes.length, 1);
        expect(nfes[0].itens, isEmpty);
        expect(nfes[0].tipoOperacao, 'DEVOLUCAO');
      });

      test('listarNfe handles empty content array', () async {
        // Arrange
        final mockResponse = Response(
          data: {'content': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/nfe/listar'),
        );

        when(mockDio.get(any, queryParameters: anyNamed('queryParameters'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final nfes = await repository.listarNfe(page: 1, pageSize: 10);

        // Assert
        expect(nfes, isEmpty);
      });
    });
  });
}
