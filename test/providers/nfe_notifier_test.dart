import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

import '../helpers/fake_nfe_repository.dart';
import '../helpers/nfe_fixtures.dart';

NfeModel _nfe(int id) => NfeModel.fromJson(nfeJson(id));

List<NfeModel> _nfes(int quantidade) => List.generate(quantidade, (i) => _nfe(i + 1));

NfeState _estado({
  List<NfeModel> nfes = const [],
  int currentPage = 1,
  int pageSize = 10,
  String? errorMessage,
}) =>
    NfeState(
      nfes: nfes,
      isLoading: false,
      currentPage: currentPage,
      pageSize: pageSize,
      errorMessage: errorMessage,
    );

void main() {
  late FakeNfeRepository repository;
  late NfeNotifier notifier;

  setUp(() {
    repository = FakeNfeRepository();
    notifier = NfeNotifier(repository);
  });

  group('NfeNotifier.listarNfe', () {
    test('carrega as NFes, guarda pagina e tamanho e encerra o loading', () async {
      repository.nfesParaListar = [_nfe(1), _nfe(2)];

      await notifier.listarNfe(page: 2, pageSize: 5);

      expect(notifier.state.nfes.map((n) => n.id), [1, 2]);
      expect(notifier.state.currentPage, 2);
      expect(notifier.state.pageSize, 5);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasError, isFalse);
    });

    test('repassa status e CNPJ do cliente ao repositorio', () async {
      await notifier.listarNfe(status: 'AUTORIZADA', clienteCnpj: '12345678000199');

      expect(repository.ultimoStatus, 'AUTORIZADA');
      expect(repository.ultimoCnpj, '12345678000199');
    });

    test('erro do repositorio vira errorMessage e esvazia a lista', () async {
      repository.nfesParaListar = [_nfe(1)];
      await notifier.listarNfe();
      repository.erroAoListar = NfeRepositoryException('timeout');

      await notifier.listarNfe();

      expect(notifier.state.errorMessage, contains('timeout'));
      expect(notifier.state.nfes, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('erro inesperado vira mensagem generica', () async {
      repository.erroAoListar = StateError('boom');

      await notifier.listarNfe();

      expect(notifier.state.errorMessage, startsWith('Erro inesperado ao listar NFes'));
    });

    test('nova listagem bem-sucedida limpa o erro anterior', () async {
      repository.erroAoListar = NfeRepositoryException('falha');
      await notifier.listarNfe();
      expect(notifier.state.hasError, isTrue);

      repository.erroAoListar = null;
      repository.nfesParaListar = [_nfe(1)];
      await notifier.listarNfe();

      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.nfes, hasLength(1));
    });
  });

  group('NfeNotifier.obterNfe', () {
    test('preenche selected com a NFe encontrada', () async {
      repository.nfeParaObter = _nfe(7);

      await notifier.obterNfe(7);

      expect(notifier.state.selected?.id, 7);
      expect(notifier.state.errorMessage, isNull);
    });

    test('NFe inexistente limpa selected e informa o erro', () async {
      repository.nfeParaObter = _nfe(7);
      await notifier.obterNfe(7);
      repository.erroAoObter = NfeNotFoundException('NFe #7');

      await notifier.obterNfe(7);

      expect(notifier.state.selected, isNull);
      expect(notifier.state.errorMessage, contains('não encontrada'));
    });
  });

  group('NfeNotifier.criarNfe', () {
    test('devolve a NFe criada e a deixa selecionada', () async {
      repository.nfeParaCriar = _nfe(9);

      final criada = await notifier.criarNfe({'serie': 1});

      expect(criada.id, 9);
      expect(notifier.state.selected?.id, 9);
      expect(repository.ultimosDadosCriados, {'serie': 1});
    });

    test('erro do repositorio e relancado e vira errorMessage', () async {
      repository.erroAoCriar = NfeRepositoryException('CNPJ inválido');

      await expectLater(
        notifier.criarNfe({}),
        throwsA(isA<NfeRepositoryException>()),
      );
      expect(notifier.state.errorMessage, contains('CNPJ inválido'));
    });
  });

  group('estado local', () {
    test('removerNfeLocal tira a NFe da lista sem chamar o repositorio', () {
      notifier.setTestState(_estado(nfes: [_nfe(1), _nfe(2)]));

      notifier.removerNfeLocal(1);

      expect(notifier.state.nfes.map((n) => n.id), [2]);
      expect(repository.chamadasListar, 0);
    });

    test('limparErro zera a mensagem de erro', () {
      notifier.setTestState(_estado(errorMessage: 'falha'));

      notifier.limparErro();

      expect(notifier.state.errorMessage, isNull);
    });

    test('resetarEstado volta ao estado inicial', () {
      notifier.setTestState(_estado(nfes: _nfes(3), currentPage: 3, pageSize: 25));

      notifier.resetarEstado();

      expect(notifier.state.nfes, isEmpty);
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.pageSize, 10);
    });
  });

  group('paginacao', () {
    test('proximaPagina busca a pagina seguinte quando ela existe', () async {
      repository.nfesParaListar = _nfes(15);
      notifier.setTestState(_estado(nfes: _nfes(15), currentPage: 1));

      await notifier.proximaPagina();

      expect(repository.ultimaPaginaListada, 2);
    });

    test('proximaPagina nao faz nada na ultima pagina', () async {
      notifier.setTestState(_estado(nfes: _nfes(15), currentPage: 2));

      await notifier.proximaPagina();

      expect(repository.chamadasListar, 0);
    });

    test('paginaAnterior nao vai abaixo da pagina 1', () async {
      notifier.setTestState(_estado(nfes: _nfes(15), currentPage: 1));

      await notifier.paginaAnterior();

      expect(repository.chamadasListar, 0);
    });

    test('paginaAnterior busca a pagina anterior', () async {
      notifier.setTestState(_estado(nfes: _nfes(15), currentPage: 2));

      await notifier.paginaAnterior();

      expect(repository.ultimaPaginaListada, 1);
    });
  });
}
