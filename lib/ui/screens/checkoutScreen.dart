import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:task_manager_flutter/data/services/checkout_caller.dart';
import 'package:html_unescape/html_unescape.dart';
import 'dart:convert'; // Importe o pacote dart:convert

class CheckoutScreen extends StatefulWidget {
  final String productName;
  final double productValue;
  final int productQnt;
  final int idVenda;

  const CheckoutScreen({
    Key? key,
    required this.productName,
    required this.productValue,
    required this.productQnt,
    required this.idVenda,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _termsAccepted = false;
  String _termsText = "Carregando termos...";
  final Color _fundoVerdeClaro = const Color.fromARGB(255, 240, 255, 241);
  final Color _bordaVerdeEscuro = const Color(0xFF2E7D32);
  bool contratarFrete = false;
  double valorFrete = 50.0; // Valor estimado do frete

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

  Future<void> _downloadContract(int contratoId, BuildContext context) async {
    try {
      CheckoutCaller().downloadContrato(contratoId, context);

      if (mounted) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _uploadContract(int negociacaoID) async {
    try {
      CheckoutCaller.uploadContract(negociacaoID);

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
                  onPressed: () => _downloadContract(widget.idVenda, context),
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
                  onPressed: () => _uploadContract(widget.idVenda),
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
    return _exibirTermos();
  }

  void _exibirTermos() {
    print("Starting _exibirTermos");

    if (_termsText.isEmpty) {
      print("_termsText is empty. Not showing dialog.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termos não encontrados.')),
      );
      return;
    }

    final unescape = HtmlUnescape();
    String textoDecodificado =
        _termsText.contains('&') ? unescape.convert(_termsText) : _termsText;
    print("Decoded text: $textoDecodificado");

    print("About to show dialog");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _fundoVerdeClaro,
        title: Text(
          'Termos da Compra',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: _bordaVerdeEscuro),
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Html(
              data: textoDecodificado,
              style: {
                "p": Style(
                  fontSize: FontSize(16.0),
                  lineHeight: LineHeight(1.8),
                  margin: Margins.only(bottom: 10),
                ),
                "ul": Style(
                  margin: Margins.only(left: 20, top: 10, bottom: 10),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 8),
                  display: Display.listItem,
                ),
                "hr": Style(
                  height: Height(1),
                  color: Colors.grey[400],
                  margin: Margins.symmetric(vertical: 15),
                ),
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print("Closing dialog");
              Navigator.pop(context);
            },
            child: Text('Fechar', style: TextStyle(color: _bordaVerdeEscuro)),
          ),
        ],
      ),
    );
    print("showDialog finished");
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

  void _showFretePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Estimativa de Frete"),
          content: const Text(
              "Este é o valor estimado de frete. Será feita uma nova cotação junto aos motoristas parceiros para verificar se conseguiremos manter o preço."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
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
                    value: contratarFrete,
                    onChanged: (bool? value) {
                      setState(() {
                        contratarFrete = value ?? false;
                      });
                      if (contratarFrete) {
                        _showFretePopup();
                      }
                    },
                    activeColor: _bordaVerdeEscuro,
                  ),
                  const Expanded(
                    child: Wrap(
                      children: [
                        Expanded(
                          child: Wrap(
                            children: [
                              Text("Contratar Frete - R\$ 20.000,00",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
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
      idVenda: 1,
    ),
  ));
}
