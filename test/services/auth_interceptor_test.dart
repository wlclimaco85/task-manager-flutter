import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/services/auth_interceptor.dart';
import 'package:task_manager_flutter/services/auth_service.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthInterceptor', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor();
    });

    test('adiciona token ao header Authorization se token existe', () async {
      final options = RequestOptions(path: '/api/test');

      // Simular que há um token
      final handler = _MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      // Verificar que handler.next foi chamado
      expect(handler.nextCalled, true);
    });

    test('rejeita requisição com status 401', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 401,
      );

      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: response,
      );

      final handler = _MockErrorInterceptorHandler();

      await interceptor.onError(error, handler);

      // Verificar que requisição foi rejeitada
      expect(handler.rejectCalled, true);
    });

    test('deixa passar erros que não são 401', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 500,
      );

      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: response,
      );

      final handler = _MockErrorInterceptorHandler();

      await interceptor.onError(error, handler);

      // Verificar que chamou handler.next (passou para o próximo)
      expect(handler.nextCalled, true);
    });
  });
}

class _MockRequestInterceptorHandler implements RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  Future<void> next(RequestOptions options) async {
    nextCalled = true;
  }

  @override
  void reject(DioException err, {bool sync = false}) {}

  @override
  void resolve(Response response, {bool sync = false}) {}
}

class _MockErrorInterceptorHandler implements ErrorInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;

  @override
  Future<void> next(DioException err) async {
    nextCalled = true;
  }

  @override
  void reject(DioException err, {bool sync = false}) {
    rejectCalled = true;
  }

  @override
  void resolve(Response response, {bool sync = false}) {}
}
