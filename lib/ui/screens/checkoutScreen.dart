import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

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
  final Color _fundoVerdeClaro = const Color.fromARGB(255, 240, 255, 241);
  final Color _bordaVerdeEscuro = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _carregarTermos();
  }

  Future<void> _carregarTermos() async {
    try {
      final response = await Dio().get('https://seuservidor.com/api/termos');
      if (response.statusCode == 200) {
        setState(() {
          _termsText = response.data['termos'] ?? "Termos não disponíveis";
        });
      }
    } catch (e) {
      setState(() {
        _termsText = "Erro ao carregar termos: $e";
      });
    }
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

  void _showTermsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _fundoVerdeClaro,
        title: const Text('Termos da Compra',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child:
              Text(_termsText, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _bordaVerdeEscuro, width: 2),
        ),
      ),
    );
  }

  void _exibirTermos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos da Compra',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(_termsText,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: _bordaVerdeEscuro, width: 2),
        ),
      ),
    );
  }

  Widget _buildCardInformacao(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordaVerdeEscuro.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(valor,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.green)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorTotal = widget.productQnt * widget.productValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalização da Compra',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        color: _fundoVerdeClaro,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Seção de Informações do Produto
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: _bordaVerdeEscuro, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _buildCardInformacao('Produto:', widget.productName),
                    _buildCardInformacao(
                        'Quantidade:', '${widget.productQnt} sacos'),
                    _buildCardInformacao('Valor Unitário:',
                        'R\$ ${widget.productValue.toStringAsFixed(2)}'),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _bordaVerdeEscuro),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VALOR TOTAL:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green)),
                          Text('R\$ ${valorTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Seção de Termos
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _bordaVerdeEscuro.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: _bordaVerdeEscuro,
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text('Li e aceito os ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: _exibirTermos,
                          child: const Text('termos de compra',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Botão Finalizar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout, size: 24),
                label: const Text('CONFIRMAR COMPRA',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bordaVerdeEscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _termsAccepted
                    ? () => _showDownloadAndUploadButtons()
                    : null,
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
