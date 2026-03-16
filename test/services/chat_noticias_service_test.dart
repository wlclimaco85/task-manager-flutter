// test/services/chat_noticias_service_test.dart
// Chat, Notícias, Cotações: apenas GET → devem retornar 200
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    token = await loginAndGetToken();
  });

  group('Chat API', () {
    test('Listar chats → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.fecthChats), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Chats');
    });
  });

  group('Notícias API', () {
    test('Listar notícias → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allNoticias), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Notícias');
    });
  });

  group('Cotações API', () {
    test('Listar cotações → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allCotacoes), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Cotações');
    });

    test('Listar cotações dólar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.fecthAllCotacaoDollar), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Cotações Dólar');
    });
  });
}
