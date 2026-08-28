import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = null;
  });

  test('setUserInfo grava em SharedPreferences e popula userInfo', () async {
    final model = LoginModel(
      token: 'token-test',
      login: Login(id: 1, email: 'user@test.com', empresa: Empresa(id: 5)),
    );

    await AuthUtility.setUserInfo(model);
    expect(AuthUtility.userInfo, isNotNull);
    expect(AuthUtility.userInfo?.token, equals('token-test'));

    final restored = await AuthUtility.getUserInfo();
    expect(restored, isNotNull);
    expect(restored?.token, equals('token-test'));
    expect(restored?.login?.empresa?.id, equals(5));
  });

  test('setUserInfo persiste foto normal do login para restaurar avatar',
      () async {
    final model = LoginModel(
      token: 'token-test',
      login: Login(
        id: 1,
        email: 'user@test.com',
        foto: 'data:image/png;base64,AAAA',
      ),
    );

    await AuthUtility.setUserInfo(model);

    final restored = await AuthUtility.getUserInfo();

    expect(restored?.login?.foto, equals('data:image/png;base64,AAAA'));
  });

  test('setUserInfo nao duplica foto entre login e data no cache', () async {
    final foto = 'data:image/png;base64,AAAA';
    final model = LoginModel(
      token: 'token-test',
      data: Data(id: 1, email: 'user@test.com', photo: foto),
      login: Login(id: 1, email: 'user@test.com', foto: foto),
    );

    await AuthUtility.setUserInfo(model);

    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;

    expect(stored['login']['foto'], equals(foto));
    expect(stored['data'], isNot(contains('photo')));
  });

  test('setUserInfo nao persiste imagens base64 grandes', () async {
    final fotoGigante = 'data:image/png;base64,${'A' * (3 * 1024 * 1024 + 1)}';
    final model = LoginModel(
      token: 'token-test',
      login: Login(
        id: 1,
        email: 'user@test.com',
        foto: fotoGigante,
      ),
    );

    await AuthUtility.setUserInfo(model);

    expect(AuthUtility.userInfo?.login?.foto, equals(fotoGigante));

    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;
    expect(stored['login'], isNot(contains('foto')));
  });

  test('getUserInfo restaura sessao persistida com data e login top-level',
      () async {
    final model = LoginModel(
      status: 'success',
      token: 'token-test',
      data: Data(id: 99),
      login: Login(id: 1, email: 'user@test.com', empresa: Empresa(id: 5)),
    );

    await AuthUtility.setUserInfo(model);
    AuthUtility.userInfo = null;

    final restored = await AuthUtility.getUserInfo();

    expect(restored?.token, equals('token-test'));
    expect(restored?.login?.id, equals(1));
    expect(restored?.login?.empresa?.id, equals(5));
  });

  test('clearUserInfo remove SharedPreferences e limpa userInfo', () async {
    final model = LoginModel(token: 'token-test', login: Login(id: 1));
    await AuthUtility.setUserInfo(model);
    await AuthUtility.clearUserInfo();

    expect(AuthUtility.userInfo, isNull);
    final restored = await AuthUtility.getUserInfo();
    expect(restored, isNull);
    expect(await AuthUtility.isUserLoggedIn(), isFalse);
  });

  test('isUserLoggedIn retorna false quando não há dados', () async {
    expect(await AuthUtility.isUserLoggedIn(), isFalse);
  });
}
