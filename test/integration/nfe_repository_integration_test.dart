import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

import '../helpers/nfe_fixtures.dart';

/// Dio sem rede: a requisicao e interceptada e recebe a resposta preparada pelo
/// teste. Assim o [NfeRepository] roda o parsing e o tratamento de erro reais.
class _DioComResposta {
  final List<RequestOptions> requisicoes = [];
  int status = 200;
  Object? corpo;

  late final Dio dio = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: _interceptar));

  void _interceptar(RequestOptions options, RequestInterceptorHandler handler) {
    requisicoes.add(options);
    if (status >= 400) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: corpo,
          statusMessage: 'erro',
        ),
      ));
      return;
    }
    handler.resolve(Response(requestOptions: options, statusCode: status, data: corpo));
  }
}

void main() {
  late _DioComResposta transporte;
  late NfeRepository repository;

  setUp(() {
    transporte = _DioComResposta();
    repository = NfeRepository(dio: transporte.dio);
  });

  group('NfeRepository.listarNfe', () {
    test('le a lista paginada (content) e converte cada NFe', () async {
      transporte.corpo = {
        'content': [nfeJson(1), nfeJson(2)],
      };

      final nfes = await repository.listarNfe(page: 1, pageSize: 10);

      expect(nfes.map((n) => n.id), [1, 2]);
      expect(nfes.first, isA<NfeModel>());
    });

    test('aceita a lista direta sem o wrapper content', () async {
      transporte.corpo = [nfeJson(3)];

      final nfes = await repository.listarNfe(page: 1, pageSize: 10);

      expect(nfes.single.id, 3);
    });

    test('envia status em maiusculo e data sem a hora', () async {
      transporte.corpo = {'content': <Map<String, dynamic>>[]};

      await repository.listarNfe(
        page: 2,
        pageSize: 5,
        status: 'autorizada',
        dataInicio: DateTime(2026, 8, 1),
      );

      final query = transporte.requisicoes.single.queryParameters;
      expect(query['page'], 2);
      expect(query['size'], 5);
      expect(query['status'], 'AUTORIZADA');
      expect(query['dataInicio'], '2026-08-01');
      expect(query.containsKey('dataFim'), isFalse);
    });

    test('erro HTTP vira NfeRepositoryException com a mensagem do servidor', () async {
      transporte.status = 500;
      transporte.corpo = {'message': 'Falhou no servidor'};

      await expectLater(
        repository.listarNfe(page: 1, pageSize: 10),
        throwsA(isA<NfeRepositoryException>()
            .having((e) => e.message, 'message', contains('Falhou no servidor'))),
      );
    });
  });

  group('NfeRepository.obterNfe', () {
    test('retorna a NFe pelo id na rota /api/nfe/{id}', () async {
      transporte.corpo = nfeJson(7);

      final nfe = await repository.obterNfe(7);

      expect(nfe.id, 7);
      expect(nfe.numeroFormatado, '1-000001');
      expect(transporte.requisicoes.single.uri.path, endsWith('/api/nfe/7'));
    });

    test('404 vira NfeNotFoundException', () async {
      transporte.status = 404;

      await expectLater(repository.obterNfe(7), throwsA(isA<NfeNotFoundException>()));
    });

    test('outro erro HTTP vira NfeApiException com o status', () async {
      transporte.status = 500;
      transporte.corpo = {'message': 'Erro interno'};

      await expectLater(
        repository.obterNfe(7),
        throwsA(isA<NfeApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('NfeRepository.criarNfe', () {
    test('envia POST na raiz /api/nfe com os dados e devolve a NFe criada', () async {
      transporte.corpo = nfeJson(9);

      final nfe = await repository.criarNfe({'serie': 1});

      expect(nfe.id, 9);
      final requisicao = transporte.requisicoes.single;
      expect(requisicao.method, 'POST');
      expect(requisicao.uri.path, endsWith('/api/nfe'));
      expect(requisicao.data, {'serie': 1});
    });

    test('erro de validacao do servidor vira NfeRepositoryException', () async {
      transporte.status = 422;
      transporte.corpo = {'message': 'CNPJ invalido'};

      await expectLater(
        repository.criarNfe({}),
        throwsA(isA<NfeRepositoryException>()
            .having((e) => e.message, 'message', contains('CNPJ invalido'))),
      );
    });
  });
}
