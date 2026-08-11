import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';
import 'package:task_manager_flutter/repositories/nfe_draft_repository.dart';

/// Testes reais (não simulados) do repositório de rascunhos offline de NFe
/// (card W3R3). Usa Hive apontando para um diretório temporário — sem mocks
/// de armazenamento, o box é lido/escrito de verdade em disco.
void main() {
  late Directory tempDir;
  late NfeDraftRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nfe_draft_repo_test');
    Hive.init(tempDir.path);
    repository = NfeDraftRepository();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(NfeDraftRepository.boxName);
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('salvarRascunho + listarRascunhos', () {
    test('salva um rascunho offline e ele aparece na listagem', () async {
      final draft = await repository.salvarRascunho(
        nfeIdReferencia: '123',
        dadosFormulario: {'numero': '99', 'valor': 150.5},
        acao: 'emitir',
      );

      expect(draft.status, NfeDraftStatus.rascunho);

      final lista = await repository.listarRascunhos();
      expect(lista, hasLength(1));
      expect(lista.first.id, draft.id);
      expect(lista.first.nfeIdReferencia, '123');
      expect(lista.first.dadosFormulario['numero'], '99');
    });

    test('mais de um rascunho é listado do mais recente para o mais antigo',
        () async {
      final d1 = await repository.salvarRascunho(
          nfeIdReferencia: '1', dadosFormulario: {}, acao: 'emitir');
      await Future.delayed(const Duration(milliseconds: 5));
      final d2 = await repository.salvarRascunho(
          nfeIdReferencia: '2', dadosFormulario: {}, acao: 'emitir');

      final lista = await repository.listarRascunhos();
      expect(lista.map((d) => d.id).toList(), [d2.id, d1.id]);
    });
  });

  test('atualizarStatus persiste a mudança de estado', () async {
    final draft = await repository.salvarRascunho(
        nfeIdReferencia: '5', dadosFormulario: {}, acao: 'emitir');

    await repository.atualizarStatus(draft.id,
        status: NfeDraftStatus.erro, mensagemErro: 'falhou');

    final atualizado = await repository.obterRascunho(draft.id);
    expect(atualizado!.status, NfeDraftStatus.erro);
    expect(atualizado.mensagemErro, 'falhou');
  });

  test('excluirRascunho remove o rascunho da box', () async {
    final draft = await repository.salvarRascunho(
        nfeIdReferencia: '7', dadosFormulario: {}, acao: 'emitir');

    await repository.excluirRascunho(draft.id);

    final lista = await repository.listarRascunhos();
    expect(lista, isEmpty);
  });

  test('contarPendentes conta apenas rascunho/erro, não enviado/conflito',
      () async {
    final d1 = await repository.salvarRascunho(
        nfeIdReferencia: '1', dadosFormulario: {}, acao: 'emitir');
    final d2 = await repository.salvarRascunho(
        nfeIdReferencia: '2', dadosFormulario: {}, acao: 'emitir');
    final d3 = await repository.salvarRascunho(
        nfeIdReferencia: '3', dadosFormulario: {}, acao: 'emitir');

    await repository.atualizarStatus(d2.id, status: NfeDraftStatus.enviado);
    await repository.atualizarStatus(d3.id, status: NfeDraftStatus.conflito);

    final pendentes = await repository.contarPendentes();
    expect(pendentes, 1); // apenas d1 continua como 'rascunho'
  });
}
