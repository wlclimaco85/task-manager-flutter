import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FreteWidget extends StatefulWidget {
  final int vendaId;
  final int compradorId;
  final int peso;
  final String cidadeOrigem;
  final String cidadeDestino;
  final String bairroOrigem;
  final String bairroDestino;

  const FreteWidget({
    required this.vendaId,
    required this.compradorId,
    required this.peso,
    required this.cidadeOrigem,
    required this.cidadeDestino,
    required this.bairroOrigem,
    required this.bairroDestino,
    Key? key,
  }) : super(key: key);

  @override
  _FreteWidgetState createState() => _FreteWidgetState();
}

class _FreteWidgetState extends State<FreteWidget> {
  late Future<double> _freteFuture;
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  bool _popupAberto = false;

  @override
  void initState() {
    super.initState();
    _freteFuture = _calcularFrete();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirPopup());
  }

  Future<double> _calcularFrete() async {
    Map<String, dynamic> requestBody = {
      "vendaId": widget.vendaId,
      "compradorId": widget.compradorId,
      "peso": widget.peso,
      "isNegociacao": false,
    };

    // Simulação da chamada de API
    await Future.delayed(const Duration(seconds: 1));
    return 150.0; // Valor simulado
  }

  void _abrirPopup() {
    if (!_popupAberto) {
      _popupAberto = true;
      _showFretePopup();
    }
  }

  void _showFretePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Detalhes do Frete',
            style: TextStyle(color: Colors.black)),
        content: FutureBuilder<double>(
          future: _freteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculando frete...',
                      style: TextStyle(color: Colors.grey)),
                ],
              );
            }

            if (snapshot.hasError) {
              return const Text('Erro ao calcular frete',
                  style: TextStyle(color: Colors.red));
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Origem: ${widget.bairroDestino} - ${widget.cidadeOrigem}',
                    style: const TextStyle(color: Colors.red)),
                Text(
                    'Destino: ${widget.bairroOrigem} - ${widget.cidadeDestino}',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                Text('Valor Total: ${_formatter.format(snapshot.data!)}',
                    style: TextStyle(
                        color: Colors.green[800], fontWeight: FontWeight.bold)),
                Text('Peso: ${widget.peso} kg'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.green[800]!.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Frete: ${_formatter.format(snapshot.data!)}'),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Este é o valor estimado de frete. Será feita uma nova cotação junto aos motoristas parceiros para verificar se conseguiremos manter o preço.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget vazio
  }
}
