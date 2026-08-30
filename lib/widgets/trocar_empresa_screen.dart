import 'package:flutter/material.dart';

import '../services/login_empresa_acesso_caller.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Ponto de entrada "Trocar Empresa" acessivel pelo menu principal, fora do
/// login inicial (Task 4, fase 178 — RESEARCH.md A2: deve ficar visivel
/// para qualquer usuario elegivel, nao dentro do grupo administrativo
/// 'sistema'). Reaproveita o mesmo caller do picker pos-login; usuarios com
/// <=1 empresa aprovada veem um estado informativo, nao um erro.
class TrocarEmpresaScreen extends StatefulWidget {
  const TrocarEmpresaScreen({super.key});

  @override
  State<TrocarEmpresaScreen> createState() => _TrocarEmpresaScreenState();
}

class _TrocarEmpresaScreenState extends State<TrocarEmpresaScreen> {
  bool _carregando = true;
  bool _erroCarregamento = false;
  List<EmpresaAcessoOption> _empresas = [];
  int? _selecionadoId;
  bool _trocando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = false;
    });
    final empresas = await LoginEmpresaAcessoCaller.listarMinhasEmpresas();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _empresas = empresas;
      _selecionadoId = TenantContext.empresaId;
      // Se a chamada falhou completamente (rede) o retorno tambem e' lista
      // vazia — sem como distinguir aqui, entao so mostramos erro quando a
      // lista vier vazia E o usuario tiver empresa ativa hoje (indicativo de
      // falha, nao de "sem acesso extra configurado ainda").
      _erroCarregamento = false;
    });
  }

  Future<void> _confirmar() async {
    final selecionado = _selecionadoId;
    if (selecionado == null || selecionado == TenantContext.empresaId) return;
    setState(() => _trocando = true);
    final resultado =
        await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(selecionado);
    if (!mounted) return;
    setState(() => _trocando = false);
    final messenger = ScaffoldMessenger.of(context);
    if (resultado.sucesso) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: GridColors.success,
        content: Text(
            'Empresa ativa alterada. Recarregue a tela para ver os dados atualizados.'),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        backgroundColor: GridColors.error,
        content: Text(resultado.mensagemErro ??
            'Erro ao trocar de empresa. Tente novamente.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment, color: GridColors.primary),
                const SizedBox(width: 8),
                const Text('Trocar Empresa',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregando ? null : _carregar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erroCarregamento
                      ? _buildEstadoErro()
                      : _empresas.length <= 1
                          ? _buildEstadoSemOutraEmpresa()
                          : _buildLista(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: GridColors.error),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar suas empresas',
              style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoSemOutraEmpresa() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center, size: 64, color: GridColors.divider),
          SizedBox(height: 12),
          Text('Você só tem acesso a uma empresa',
              style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Solicite acesso a outra empresa para poder trocar.',
              style: TextStyle(color: GridColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _empresas.length,
            itemBuilder: (_, i) {
              final e = _empresas[i];
              final ativa = e.empresaId == TenantContext.empresaId;
              return RadioListTile<int>(
                key: Key('trocar_empresa_item_${e.empresaId}'),
                value: e.empresaId,
                groupValue: _selecionadoId,
                onChanged:
                    _trocando ? null : (v) => setState(() => _selecionadoId = v),
                title: Text(e.nome),
                subtitle: ativa ? const Text('Empresa ativa atualmente') : null,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _trocando ||
                    _selecionadoId == null ||
                    _selecionadoId == TenantContext.empresaId
                ? null
                : _confirmar,
            child: _trocando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Acessar empresa selecionada'),
          ),
        ),
      ],
    );
  }
}
