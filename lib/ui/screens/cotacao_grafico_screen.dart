import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/data/models/dollar_model.dart';

// Definição de cores
class AppColors {
  static const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
  static const Color borderColor = Color.fromARGB(255, 1, 247, 14);
  static const Color tableBorderColor =
      Color.fromARGB(255, 1, 247, 14); // Verde escuro
  static const Color tableText = Colors.black;
  static const Color tableSubtitleText = Colors.grey;
}

class CotacaoScreen extends StatefulWidget {
  const CotacaoScreen({super.key});

  @override
  _CotacaoScreenState createState() => _CotacaoScreenState();
}

class _CotacaoScreenState extends State<CotacaoScreen> {
  List<Cotacao> cotacoes = [];
  List<Dollar> dollarCotacoes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCotacoes();
    _fetchCotacoesDollares();
  }

  void refresh() {
    _fetchCotacoes();
    _fetchCotacoesDollares();
  }

  void _fetchCotacoes() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoes().then((data) {
      setState(() {
        cotacoes = data;
        isLoading = false;
      });
    });
  }

  void _fetchCotacoesDollares() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoesDollar().then((data) {
      setState(() {
        dollarCotacoes = data;
        isLoading = false;
      });
    });
  }

  Widget _buildTable(String title, List<TableRow> rows,
      {String? footer, String? source}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBackground, // Fundo verde claro
        border: Border.all(color: AppColors.tableBorderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.tableText,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: AppColors.tableText),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: rows,
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.tableSubtitleText,
              ),
            ),
          ],
          if (source != null) ...[
            const SizedBox(height: 8),
            Text(
              "Fonte: $source",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.tableSubtitleText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<TableRow> _buildCotacoesRows(List<Cotacao> cotacoes) {
    return [
      const TableRow(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.tableText),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.tableText),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.dtCotacao?.day}/${cotacao.dtCotacao?.month}/${cotacao.dtCotacao?.year}',
                style: const TextStyle(color: AppColors.tableText),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.valor?.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.tableText),
              ),
            ),
          ],
        );
      }),
    ];
  }

  List<TableRow> _buildDollarRows(List<Dollar> cotacoes) {
    return [
      const TableRow(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.tableText),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.tableText),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.date?.day}/${cotacao.date?.month}/${cotacao.date?.year}',
                style: const TextStyle(color: AppColors.tableText),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.rate?.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.tableText),
              ),
            ),
          ],
        );
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground, // Fundo da tela
      appBar: UserBannerAppBar(
        screenTitle: "Cotações",
        isLoading: isLoading,
        onRefresh: refresh,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTable(
                  'INDICADOR DO ARROZ EM CASCA CEPEA/IRGA-RS',
                  _buildCotacoesRows(cotacoes.take(5).toList()),
                  footer:
                      '* Nota: Reais por saca de 50 kg, tipo 1, 58/10, posto indústria Rio Grande do Sul, à vista (Prazo de Pagamento descontado pela taxa CDI/CETIP).',
                  source: 'CEPEA',
                ),
                const SizedBox(height: 20),
                _buildTable(
                  'Últimas Cotações do Dólar',
                  _buildDollarRows(dollarCotacoes),
                  source: 'Yahoo Finance',
                ),
              ],
            ),
    );
  }
}
