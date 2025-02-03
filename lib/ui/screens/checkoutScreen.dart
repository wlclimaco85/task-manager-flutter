import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/data/services/checkout_caller.dart';

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
      final termos = await CheckoutCaller.carregarTermos();

      if (mounted) {
        setState(() {
          _termsText = termos;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _downloadContract() async {
    try {
      CheckoutCaller.downloadContract();

      if (mounted) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _uploadContract() async {
    try {
      CheckoutCaller.uploadContract();

      if (mounted) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
    }
  }

  void _showDownloadAndUploadButtons() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _fundoVerdeClaro,
          title: Text('Contrato',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _bordaVerdeEscuro)), // Cor verde principal
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão de Download
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 24),
                  label: const Text('Baixar Contrato Modelo',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bordaVerdeEscuro, // Verde principal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: _bordaVerdeEscuro), // Borda consistente
                    ),
                  ),
                  onPressed: _downloadContract,
                ),
              ),
              SizedBox(height: 15),
              // Botão de Upload
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload, size: 24),
                  label: const Text('Enviar Contrato Assinado',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bordaVerdeEscuro, // Mesma cor do tema
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: _bordaVerdeEscuro),
                    ),
                  ),
                  onPressed: _uploadContract,
                ),
              ),
            ],
          ),
          actions: [
            // Botão Fechar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _bordaVerdeEscuro)), // Cor verde principal
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: _bordaVerdeEscuro, width: 2), // Borda verde
          ),
        );
      },
    );
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
