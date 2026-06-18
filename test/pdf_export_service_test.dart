import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/pdf_export_service.dart';

void main() {
  group('PdfExportService.gerarTabela', () {
    test('gera bytes de um PDF valido com dados', () async {
      final bytes = await PdfExportService.gerarTabela(
        titulo: 'Treinos',
        cabecalhos: const ['Nome', 'Tipo', 'Duracao'],
        linhas: const [
          ['Treino A', 'Forca', '60 min'],
          ['Treino B', 'Cardio', '30 min'],
        ],
      );

      expect(bytes.lengthInBytes, greaterThan(0));
      // Todo PDF valido comeca com a assinatura "%PDF".
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('gera PDF mesmo sem linhas (apenas cabecalho)', () async {
      final bytes = await PdfExportService.gerarTabela(
        titulo: 'Exames',
        cabecalhos: const ['Nome', 'Laboratorio'],
        linhas: const [],
      );

      expect(bytes.lengthInBytes, greaterThan(0));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('aceita subtitulo opcional', () async {
      final bytes = await PdfExportService.gerarTabela(
        titulo: 'Avaliacao Fisica',
        subtitulo: 'Aluno: Joao Silva',
        cabecalhos: const ['Data', 'Peso', 'IMC'],
        linhas: const [
          ['01/06/2026', '80 kg', '24,5'],
        ],
      );

      expect(bytes.lengthInBytes, greaterThan(0));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
