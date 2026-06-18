import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servico generico de exportacao de listas em PDF (GAP MFIT #156).
///
/// Gera relatorios tabulares (treino, avaliacao fisica, exames, dieta, etc.)
/// a partir de cabecalhos + linhas. A geracao dos bytes ([gerarTabela]) e
/// separada da acao de impressao ([exportar]) para permitir teste unitario
/// sem depender do plugin de impressao.
class PdfExportService {
  static const PdfColor _corMarca = PdfColor.fromInt(0xFF7E57C2); // roxo Fitness 360

  /// Monta um PDF tabular e retorna seus bytes. Funcao pura (sem I/O de plugin).
  static Future<Uint8List> gerarTabela({
    required String titulo,
    required List<String> cabecalhos,
    required List<List<String>> linhas,
    String? subtitulo,
  }) async {
    final documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              titulo,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (subtitulo != null && subtitulo.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                subtitulo,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ),
          pw.TableHelper.fromTextArray(
            headers: cabecalhos,
            data: linhas,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: _corMarca),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Gerado pelo App Academia',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );

    return documento.save();
  }

  /// Gera o PDF e abre o dialogo de impressao/compartilhamento do dispositivo.
  static Future<void> exportar({
    required String titulo,
    required List<String> cabecalhos,
    required List<List<String>> linhas,
    String? subtitulo,
    String? nomeArquivo,
  }) async {
    final bytes = await gerarTabela(
      titulo: titulo,
      cabecalhos: cabecalhos,
      linhas: linhas,
      subtitulo: subtitulo,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: nomeArquivo ?? '$titulo.pdf',
    );
  }
}
