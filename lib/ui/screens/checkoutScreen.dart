import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Para FilePickerResult
import 'dart:io'; // Para File
import 'package:dio/dio.dart'; // Para FormData e envio de arquivos

class CheckoutScreen extends StatefulWidget {
  final String productName;
  final double productValue;
  final int productQnt;

  const CheckoutScreen({
    Key? key,
    required this.productName,
    required this.productValue,
    required this.productQnt,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _termsAccepted = false;
  String _termsText = "Carregando termos...";

  @override
  void initState() {
    super.initState();
    _fetchTerms(); // Busca os termos ao iniciar a tela
  }

  void _downloadContract() async {
    final url = 'https://seuservidor.com/api/contract.pdf';
    final response = await Dio().download(url, 'contrato.pdf');
    print('Contrato baixado: ${response.data}');
  }

  void _uploadContract2() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await Dio()
          .post('https://seuservidor.com/api/upload', data: formData);
      print('Contrato enviado: ${response.data}');
    }
  }

  Future<void> _fetchTerms() async {
    final dio = Dio();
    final url =
        'https://seuservidor.com/api/terms'; // Substitua pelo seu endpoint

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _termsText = response.data[
              'terms']; // Supondo que o endpoint retorne um JSON com a chave "terms"
        });
      } else {
        setState(() {
          _termsText = "Erro ao carregar os termos.";
        });
      }
    } catch (e) {
      setState(() {
        _termsText = "Erro ao carregar os termos: $e";
      });
    }
  }

  void _showDownloadAndUploadButtons() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contrato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica para download do contrato
                  _downloadContract();
                },
                icon: const Icon(Icons.download),
                label: const Text('Baixar Contrato'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica para upload do contrato
                  _uploadContract();
                },
                icon: const Icon(Icons.upload),
                label: const Text('Enviar Contrato Assinado'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadContract() async {
    try {
      // Abre o seletor de arquivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Obtém o arquivo selecionado
        PlatformFile file = result.files.first;
        File uploadedFile = File(file.path!);

        // Exibe o nome do arquivo selecionado
        print('Arquivo selecionado: ${file.name}');

        // Envia o arquivo para o backend
        final dio = Dio();
        final url =
            'https://seuservidor.com/api/upload'; // Substitua pelo seu endpoint

        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(uploadedFile.path,
              filename: file.name),
        });

        final response = await dio.post(url, data: formData);

        if (response.statusCode == 200) {
          print('Contrato enviado com sucesso!');
        } else {
          print('Erro ao enviar o contrato: ${response.statusCode}');
        }
      } else {
        print('Nenhum arquivo selecionado.');
      }
    } catch (e) {
      print('Erro ao selecionar o arquivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produto: ${widget.productName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Valor: R\$ ${widget.productValue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Termos da Compra:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _termsText,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                ),
                const Text('Aceito os termos'),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _termsAccepted
                    ? () {
                        _showDownloadAndUploadButtons();
                      }
                    : null,
                child: const Text('Finalizar Compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: CheckoutScreen(
      productName: 'Produto Exemplo',
      productValue: 100.00,
      productQnt: 1,
    ),
  ));
}
