import 'package:flutter/material.dart';
import '../../services/ponto_service.dart';
import '../../utils/grid_colors.dart';

class RelatorioPontoScreen extends StatefulWidget {
  const RelatorioPontoScreen({super.key});

  @override
  State<RelatorioPontoScreen> createState() => _RelatorioPontoScreenState();
}

class _RelatorioPontoScreenState extends State<RelatorioPontoScreen> {
  bool _loading = false;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: Ligar a api/folha_ponto/fechamento
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Relatório de Ponto e Absenteísmo'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Mês:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _mesSelecionado,
                        items: List.generate(12, (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        )),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _mesSelecionado = val);
                            _carregarDados();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text('Ano:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _anoSelecionado,
                        items: [2024, 2025, 2026].map((a) => DropdownMenuItem(
                          value: a,
                          child: Text('$a'),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _anoSelecionado = val);
                            _carregarDados();
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Gerar Espelho (PDF)'),
                        onPressed: () {
                          // TODO: Chamar PontoService.gerarRelatorioPdf
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: GridColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Expanded(
                    child: Center(
                      child: Text('Tabela de relatório de ponto, horas normais, extras e absenteísmo aparecerá aqui.'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
