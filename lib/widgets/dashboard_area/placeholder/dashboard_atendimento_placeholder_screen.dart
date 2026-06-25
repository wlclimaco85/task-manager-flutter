import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../services/dashboard_atendimento_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/utils.dart';
import '../../../mobile/screens/dashboard_tickets_trend_screen.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';
import '../kpi_card.dart';

class DashboardAtendimentoPlaceholderScreen extends StatefulWidget {
  const DashboardAtendimentoPlaceholderScreen({super.key});

  @override
  State<DashboardAtendimentoPlaceholderScreen> createState() =>
      _DashboardAtendimentoPlaceholderScreenState();
}

class _DashboardAtendimentoPlaceholderScreenState
    extends State<DashboardAtendimentoPlaceholderScreen> {
  DashboardAreaState<List<KpiDashboardModel>> _state =
      const DashboardAreaState.loading();
  DateTime? _periodoInicio;
  DateTime? _periodoFim;

  final int _empresaId = pegarEmpresaLogada() ?? 0;
  final int? _parceiroId = pegarParceiroLogada();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());
    final resposta = await DashboardAtendimentoCaller().fetchKpis(
      periodoInicio: _periodoInicio,
      periodoFim: _periodoFim,
    );
    if (!mounted) return;
    if (resposta == null) {
      setState(() => _state =
          const DashboardAreaState.erro('Nao foi possivel carregar os dados.'));
      return;
    }
    if (resposta.kpis.isEmpty) {
      setState(() => _state = const DashboardAreaState.vazio());
      return;
    }
    setState(() => _state = DashboardAreaState.sucesso(resposta.kpis));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 20),
            SizedBox(width: 8),
            Text(
              'Atendimento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPeriodoBar(),
              _buildKpis(),
              _buildAtalhosRapidos(),
              _buildTendenciaChamados(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodoBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: GridColors.secondary,
            side: const BorderSide(color: GridColors.secondary),
          ),
          onPressed: _selecionarPeriodo,
          icon: const Icon(Icons.date_range, size: 16),
          label: Text(_periodoLabel, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildKpis() {
    switch (_state.status) {
      case DashboardAreaStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      case DashboardAreaStatus.erro:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_state.mensagemErro ?? 'Erro ao carregar dados'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
            ],
          ),
        );
      case DashboardAreaStatus.vazio:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Nenhum dado encontrado')),
        );
      case DashboardAreaStatus.sucesso:
        final kpis = _state.dados ?? [];
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final colunas = constraints.maxWidth < 600 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: kpis.length,
              itemBuilder: (_, i) => KpiCard(
                kpi: kpis[i],
                periodoInicio: _periodoInicio,
                periodoFim: _periodoFim,
                onTap: (ini, fim, rota) =>
                    DrillDownRouter.navigate(context, rota, ini, fim),
              ),
            );
          },
        );
    }
  }

  Widget _buildAtalhosRapidos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: GridColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acesso Rápido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: GridColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAtalhoBtn(
                      icon: Icons.assignment_outlined,
                      label: 'Chamados',
                      cor: GridColors.primary,
                      onTap: () => DrillDownRouter.navigate(
                          context, 'chamadoGrid', null, null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAtalhoBtn(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      cor: GridColors.secondary,
                      onTap: () => DrillDownRouter.navigate(
                          context, 'chatList', null, null),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtalhoBtn({
    required IconData icon,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cor.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendenciaChamados() {
    if (_empresaId == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: GridColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tendência de Chamados (6 meses)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: GridColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: TicketsTrendChart(
                  empresaId: _empresaId,
                  parceiroId: _parceiroId is int ? _parceiroId : null,
                  months: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _periodoLabel {
    if (_periodoInicio == null || _periodoFim == null) {
      return 'Mes atual';
    }
    String fmt(DateTime data) =>
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    return '${fmt(_periodoInicio!)} - ${fmt(_periodoFim!)}';
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final inicial = DateTimeRange(
      start: _periodoInicio ?? DateTime(agora.year, agora.month, 1),
      end: _periodoFim ?? DateTime(agora.year, agora.month + 1, 0),
    );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year + 2),
      initialDateRange: inicial,
    );
    if (range == null || !mounted) return;
    setState(() {
      _periodoInicio = range.start;
      _periodoFim = range.end;
    });
    await _carregar();
  }
}
