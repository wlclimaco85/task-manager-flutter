import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../mobile/screens/bottom_navbar_screen.dart';
import '../../windows/screens/bottom_navbar_screen.dart';
import '../../web/screens/bottom_navbar_screen.dart';
import '../../models/auth_utility.dart';
import '../../models/login_model.dart';
import '../../models/network_response.dart';
import '../../utils/api_links.dart';
import '../../utils/assets_utils.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/security_matrix.dart';
import '../services/network_caller.dart';
import '../services/push_notification_service.dart';
import '../services/alerta_polling_service.dart';
import '../services/login_empresa_acesso_service.dart';
import '../widgets/empresa_selecao_screen.dart';
import '../widgets/app_loading_overlay.dart';
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.washingtonclimaco.task_manager_flutter';

const List<_LoginModule> _includedModules = [
  _LoginModule(
    title: 'Chat com o escritorio',
    description: 'Conversas por setor com historico para cliente e equipe.',
    icon: Icons.chat_bubble_outline,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'Abertura de chamados',
    description: 'Solicitacoes do cliente por setor e acompanhamento interno.',
    icon: Icons.support_agent_outlined,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'Informativos',
    description: 'Avisos, cobrancas e comunicados enviados para clientes.',
    icon: Icons.campaign_outlined,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'Upload de extratos',
    description: 'Cliente envia extrato bancario direto pelo portal/app.',
    icon: Icons.upload_file_outlined,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'GED e documentos',
    description: 'Organizacao de arquivos, anexos e documentos do cliente.',
    icon: Icons.snippet_folder_outlined,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'Calendario financeiro',
    description: 'Agenda de vencimentos, guias, tarefas e compromissos.',
    icon: Icons.calendar_month_outlined,
    badge: 'Incluso',
  ),
  _LoginModule(
    title: 'Financeiro essencial',
    description:
        'Contas a pagar/receber, bancos, movimentacao e centro de custo.',
    icon: Icons.account_balance_wallet_outlined,
    badge: 'Incluso',
  ),
];

const List<_LoginModule> _optionalModules = [
  _LoginModule(
    title: 'Fiscal e NF-e',
    description: 'XML, SPED, SINTEGRA, entradas, saidas e tributacao.',
    icon: Icons.receipt_long_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'GME',
    description:
        'Gestor Micro Empreendedor para vendas, compras, producao e rotina operacional.',
    icon: Icons.storefront_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'NFS-e',
    description: 'Nota fiscal de servico, prefeitura, tomador e servicos.',
    icon: Icons.description_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'NFC-e',
    description: 'Cupons fiscais, PDV, pagamentos e emissao para varejo.',
    icon: Icons.point_of_sale_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Precificacao de contratos',
    description: 'Regras, reajustes e margens para contratos recorrentes.',
    icon: Icons.handshake_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Service Desk',
    description: 'SLA, filas, transferencia e operacao de suporte.',
    icon: Icons.headset_mic_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Projetos',
    description: 'Organizacao de entregas, etapas, responsaveis e status.',
    icon: Icons.account_tree_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Precificacao',
    description: 'Calculo comercial para servicos, pacotes e propostas.',
    icon: Icons.sell_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Financeiro avancado',
    description:
        'Regua de cobranca, kanban de pagamentos e conciliacao bancaria.',
    icon: Icons.insights_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'DRE gerencial',
    description: 'Indicadores de resultado, margem e analise de performance.',
    icon: Icons.stacked_line_chart_outlined,
    badge: 'Opcional',
  ),
  _LoginModule(
    title: 'Estoque e giro',
    description: 'Controle de estoque, giro de produto e alertas de reposicao.',
    icon: Icons.inventory_2_outlined,
    badge: 'Opcional',
  ),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loginInProgress = false;
  String _loginStepMessage = 'Autenticando credenciais...';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  void _goHome() {
    if (kIsWeb) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WebBottomNavBarScreen()),
          (_) => false);
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WindowsBottomNavBarScreen()),
          (_) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
          (_) => false);
    }
  }

  Future<void> _abrirSelecaoEmpresaOuHome() async {
    final acessos = await LoginEmpresaAcessoService().listarMeusAcessos();
    final aprovadas = acessos.where((a) => a.aprovado).toList();
    if (!mounted) return;
    if (aprovadas.length > 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmpresaSelecaoScreen(
            obrigatorio: true,
            loadAcessos: () async => acessos,
          ),
        ),
      );
      if (!mounted) return;
      _goHome();
      return;
    }
    _goHome();
  }

  Future<void> _login() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loginInProgress = true;
      _loginStepMessage = 'Autenticando credenciais...';
    });

    NetworkResponse resp;
    try {
      resp = await NetworkCaller().postRequest(ApiLinks.login, {
        'email': _emailController.text.trim(),
        'password': _passwordController.text
      });
    } catch (e) {
      setState(() => _loginInProgress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao conectar: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
        ));
      }
      return;
    }

    if (resp.isSuccess && resp.body != null) {
      final model = LoginModel.fromJson(resp.body!);
      if ((model.token ?? "").isEmpty) {
        setState(() => _loginInProgress = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(GridTexts.loginTokenMissing)));
        }
        return;
      }

      if (mounted) {
        setState(() => _loginStepMessage = 'Carregando módulos e permissões...');
      }
      await AuthUtility.setUserInfo(model);
      ModuloAccess.reset();
      await ModuloAccess.load();

      if (mounted) {
        setState(() => _loginStepMessage = 'Conectando serviços e notificações...');
      }

      unawaited(PushNotificationService.registrarDispositivoLogado().catchError((e) {
        debugPrint('[Push] Falha ao registrar dispositivo: $e');
      }));
      unawaited(AlertaPollingService.instance.iniciar().catchError((e) {
        debugPrint('[AlertaPolling] Falha ao iniciar: $e');
      }));

      if (!mounted) return;
      if (model.login?.trocarSenhaProximoLogin == true) {
        setState(() => _loginInProgress = false);
        final email = model.login?.email ?? '';
        if (email.isNotEmpty) {
          await _showTrocarSenhaDialog(email);
        }
        return;
      }

      if (mounted) {
        setState(() => _loginStepMessage = 'Abrindo Calendário Financeiro...');
      }
      await _abrirSelecaoEmpresaOuHome();
    } else {
      setState(() => _loginInProgress = false);
      if (mounted) {
        _passwordController.clear();
        final msg = resp.statusCode == 400 || resp.statusCode == 401
            ? GridTexts.loginInvalidCredentials
            : resp.statusCode == -1
                ? GridTexts.loginNoConnection
                : 'Erro ${resp.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  Future<void> _showTrocarSenhaDialog(String email) async {
    final atualCtrl = TextEditingController();
    final novaCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureAtual = true;
    bool obscureNova = true;
    bool obscureConfirm = true;
    bool loading = false;
    String? erro;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(Icons.lock_reset, color: GridColors.secondary, size: 24),
            const SizedBox(width: 8),
            const Text('Trocar senha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 320,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'É necessário definir uma nova senha antes de continuar.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              if (erro != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(erro!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12)),
                ),
              _SenhaField(
                label: 'Senha atual',
                ctrl: atualCtrl,
                obscure: obscureAtual,
                onToggle: () => setS(() => obscureAtual = !obscureAtual),
              ),
              const SizedBox(height: 10),
              _SenhaField(
                label: 'Nova senha',
                ctrl: novaCtrl,
                obscure: obscureNova,
                onToggle: () => setS(() => obscureNova = !obscureNova),
              ),
              const SizedBox(height: 10),
              _SenhaField(
                label: 'Confirmar nova senha',
                ctrl: confirmCtrl,
                obscure: obscureConfirm,
                onToggle: () => setS(() => obscureConfirm = !obscureConfirm),
              ),
            ]),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        final atual = atualCtrl.text.trim();
                        final nova = novaCtrl.text.trim();
                        final confirm = confirmCtrl.text.trim();
                        if (atual.isEmpty || nova.isEmpty || confirm.isEmpty) {
                          setS(() => erro = 'Preencha todos os campos.');
                          return;
                        }
                        if (nova.length < 6) {
                          setS(() => erro =
                              'A nova senha deve ter pelo menos 6 caracteres.');
                          return;
                        }
                        if (nova != confirm) {
                          setS(() =>
                              erro = 'Nova senha e confirmação não conferem.');
                          return;
                        }
                        setS(() {
                          loading = true;
                          erro = null;
                        });
                        final checkResp = await NetworkCaller().postRequest(
                          ApiLinks.login,
                          {'email': email, 'password': atual},
                        );
                        if (!checkResp.isSuccess) {
                          setS(() {
                            loading = false;
                            erro = 'Senha atual incorreta.';
                          });
                          return;
                        }
                        final alterResp = await NetworkCaller().postRequest(
                          '${ApiLinks.baseUrl}/api/login/alterar-senha',
                          {'email': email, 'novaSenha': nova},
                        );
                        setS(() => loading = false);
                        if (alterResp.isSuccess) {
                          Navigator.of(ctx).pop(true);
                        } else {
                          setS(() =>
                              erro = 'Erro ao alterar senha. Tente novamente.');
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    atualCtrl.dispose();
    novaCtrl.dispose();
    confirmCtrl.dispose();

    if (mounted) await _abrirSelecaoEmpresaOuHome();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF023819),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF004D20),
                  Color(0xFF013316),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Barra de Login Horizontal no Topo
                  _LoginHorizontalHeader(
                    emailCtrl: _emailController,
                    passCtrl: _passwordController,
                    formKey: _formKey,
                    obscure: _obscurePassword,
                    loading: _loginInProgress,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onLogin: _login,
                    onForgot: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmailVarificationScreeen()),
                    ),
                    onRequestAccess: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SolicitacaoAcessoScreen()),
                    ),
                  ),

                  // 2. Corpo Principal: Módulos (Esquerda) + Carrossel de Notícias (Direita)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 960;

                        if (isDesktop) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Lado Esquerdo: Módulos Inclusos e Opcionais (Sem Mockup)
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const _FuncionalidadesPortal(),
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Lado Direito: Carrossel com últimas notícias
                                SizedBox(
                                  width: 400,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const _NoticiasCarousel(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Layout Mobile / Telas Menores (Scroll Vertical)
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              _NoticiasCarousel(isMobile: true),
                              SizedBox(height: 20),
                              _FuncionalidadesPortal(isMobile: true),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loginInProgress)
            Positioned.fill(
              child: AppLoadingOverlay(
                title: 'Acessando o Sistema',
                message: _loginStepMessage,
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginModule {
  final String title;
  final String description;
  final IconData icon;
  final String badge;

  const _LoginModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
  });
}

// ============================================================================
// 1. Barra Superior de Login Horizontal
// ============================================================================
class _LoginHorizontalHeader extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onLogin, onForgot, onRequestAccess;

  const _LoginHorizontalHeader({
    required this.emailCtrl,
    required this.passCtrl,
    required this.formKey,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgot,
    required this.onRequestAccess,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 900;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF003D1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 10 : 8,
      ),
      child: isCompact ? _buildCompact(context) : _buildWide(context),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Marca e Título
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: const _SafeLogoWidget(size: 38),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              GridTexts.appTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Portal do escritório para clientes',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const Spacer(),

        // Formulário Horizontal Inline
        Form(
          key: formKey,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Campo Usuário
              SizedBox(
                width: 145,
                child: _headerField(
                  ctrl: emailCtrl,
                  hint: GridTexts.loginUserHint,
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? GridTexts.loginUserRequired : null,
                ),
              ),
              const SizedBox(width: 6),

              // Campo Senha
              SizedBox(
                width: 135,
                child: _headerField(
                  ctrl: passCtrl,
                  hint: GridTexts.loginPasswordHint,
                  icon: Icons.lock_outline,
                  obscure: obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!loading) onLogin();
                  },
                  suffix: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                      size: 15,
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? GridTexts.loginPasswordRequired
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Botão Acessar
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: loading ? null : onLogin,
                  child: loading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          GridTexts.loginAction,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Links de Acesso Rápido
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onForgot,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: const Text(
                        GridTexts.forgotPassword,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onRequestAccess,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: const Text(
                        GridTexts.requestAccess,
                        style: TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Botão Play Store
              const _PlayStoreHeaderButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(5),
                child: const _SafeLogoWidget(size: 34),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GridTexts.appTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Portal do escritório para clientes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const _PlayStoreHeaderButton(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          _headerField(
            ctrl: emailCtrl,
            hint: GridTexts.loginUserHint,
            icon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: (v) =>
                (v == null || v.isEmpty) ? GridTexts.loginUserRequired : null,
          ),
          const SizedBox(height: 8),
          _headerField(
            ctrl: passCtrl,
            hint: GridTexts.loginPasswordHint,
            icon: Icons.lock_outline,
            obscure: obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!loading) onLogin();
            },
            suffix: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: onToggleObscure,
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
                size: 15,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? GridTexts.loginPasswordRequired : null,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: loading ? null : onLogin,
              child: loading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      GridTexts.loginAction,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onForgot,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      GridTexts.forgotPassword,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onRequestAccess,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      GridTexts.requestAccess,
                      style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 11.5),
        prefixIcon: Icon(icon, color: Colors.white70, size: 15),
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFF86EFAC),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 9.5),
      ),
    );
  }
}

class _PlayStoreHeaderButton extends StatelessWidget {
  final bool compact;
  const _PlayStoreHeaderButton({this.compact = false});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_playStoreUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir a Play Store.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _open(context),
        tooltip: 'Baixar na Play Store',
        icon: const Icon(Icons.android_outlined, color: Color(0xFF86EFAC), size: 20),
      );
    }
    return Tooltip(
      message: 'Baixar aplicativo Android',
      child: OutlinedButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.android_outlined, size: 14),
        label: const Text('Play Store', style: TextStyle(fontSize: 10.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF86EFAC),
          side: const BorderSide(color: Color(0xFF86EFAC), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. Funcionalidades do Portal (Módulos Inclusos e Opcionais - Sem Mockup)
// ============================================================================
class _FuncionalidadesPortal extends StatelessWidget {
  final bool isMobile;
  const _FuncionalidadesPortal({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Seção
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF86EFAC).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF86EFAC),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Portal do Escritório para Clientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Módulos inclusos para gestão, comunicação e rotina financeira',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid de Módulos Inclusos (Compacta e Ajustada)
        Expanded(
          flex: isMobile ? 0 : 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              final childRatio = constraints.maxWidth > 600 ? 2.4 : 1.9;

              return GridView.builder(
                shrinkWrap: isMobile,
                physics: isMobile
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: childRatio,
                ),
                itemCount: _includedModules.length,
                itemBuilder: (context, index) {
                  return _ModuleCardCompact(module: _includedModules[index]);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Faixa de Planos e Módulos Opcionais
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFBBF24),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Módulos opcionais (Fiscal, NF-e, NFS-e, NFC-e, GME, Service Desk, DRE, Estoque) disponíveis a partir de R\$ 99,90/mês ou R\$ 199,90 pacote completo.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleCardCompact extends StatelessWidget {
  final _LoginModule module;
  const _ModuleCardCompact({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GridColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              module.icon,
              color: GridColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Incluso',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    module.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. Carrossel de Últimas Notícias do Sistema (Lateral)
// ============================================================================
class _NoticiasCarousel extends StatefulWidget {
  final bool isMobile;
  const _NoticiasCarousel({this.isMobile = false});

  @override
  State<_NoticiasCarousel> createState() => _NoticiasCarouselState();
}

class _NoticiasCarouselState extends State<_NoticiasCarousel> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _noticias = [];
  bool _loading = true;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarNoticias();
  }

  Future<void> _carregarNoticias() async {
    try {
      final resp = await http
          .get(Uri.parse('${ApiLinks.noticiasPublicas}?limite=15'))
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final list =
            (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
        list.sort((a, b) {
          final da =
              a['dtNoticia']?.toString() ?? a['dtImport']?.toString() ?? '';
          final db =
              b['dtNoticia']?.toString() ?? b['dtImport']?.toString() ?? '';
          return db.compareTo(da);
        });

        if (mounted) {
          setState(() {
            _noticias = list;
            _loading = false;
          });
          _iniciarAutoPlay();
        }
        return;
      }
    } catch (e) {
      debugPrint('[_NoticiasCarousel] Erro ao carregar noticias: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _iniciarAutoPlay() {
    _timer?.cancel();
    if (_noticias.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _noticias.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _anterior() {
    if (_noticias.isEmpty || !_pageController.hasClients) return;
    final prevPage = (_currentPage - 1 + _noticias.length) % _noticias.length;
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _proximo() {
    if (_noticias.isEmpty || !_pageController.hasClients) return;
    final nextPage = (_currentPage + 1) % _noticias.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _abrirDetalheNoticia(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => _NewsDetailDialog(noticia: item),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.isMobile ? 320.0 : null;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header do Carrossel com Navegação
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: Color(0xFFFBBF24),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Últimas Notícias & Comunicados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_noticias.isNotEmpty) ...[
                IconButton(
                  onPressed: _anterior,
                  tooltip: 'Notícia anterior',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white70, size: 20),
                ),
                IconButton(
                  onPressed: _proximo,
                  tooltip: 'Próxima notícia',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white70, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Conteúdo do Carrossel
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF86EFAC),
                      strokeWidth: 2,
                    ),
                  )
                : _noticias.isEmpty
                    ? _buildEmptyState()
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        itemCount: _noticias.length,
                        itemBuilder: (context, index) {
                          final item = _noticias[index];
                          return _NewsCard(
                            noticia: item,
                            onTap: () => _abrirDetalheNoticia(item),
                          );
                        },
                      ),
          ),

          // Indicador de Bolinhas (Dots)
          if (_noticias.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _noticias.length > 10 ? 10 : _noticias.length,
                (index) => Container(
                  width: _currentPage == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF86EFAC)
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.campaign_outlined, color: Colors.white60, size: 36),
            SizedBox(height: 8),
            Text(
              'Nenhum comunicado recente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Novas notícias e avisos fiscais do escritório serão exibidos aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> noticia;
  final VoidCallback onTap;

  const _NewsCard({required this.noticia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titulo = noticia['titulo']?.toString() ?? 'Sem título';
    final resumo = noticia['resumo']?.toString() ??
        noticia['noticia']?.toString() ??
        'Clique para ler mais detalhes sobre este informativo.';
    final fonte = noticia['fonte']?.toString() ?? 'Informativo';
    final foto = noticia['foto']?.toString();
    final dtStr =
        noticia['dtNoticia']?.toString() ?? noticia['dtImport']?.toString();
    String dataFmt = '';
    if (dtStr != null && dtStr.length >= 10) {
      final parts = dtStr.substring(0, 10).split('-');
      if (parts.length == 3) {
        dataFmt = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem ou Banner da Notícia
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (foto != null && foto.isNotEmpty && !foto.startsWith('data:'))
                    Image.network(
                      foto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackImage(),
                    )
                  else
                    _buildFallbackImage(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GridColors.secondary.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fonte,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (dataFmt.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dataFmt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Título e Resumo
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        resumo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Ler notícia completa',
                          style: TextStyle(
                            color: GridColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: GridColors.primary,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.article_outlined,
          color: Colors.white60,
          size: 40,
        ),
      ),
    );
  }
}

// Dialog com Detalhe Completo da Notícia
class _NewsDetailDialog extends StatelessWidget {
  final Map<String, dynamic> noticia;
  const _NewsDetailDialog({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final titulo = noticia['titulo']?.toString() ?? 'Sem título';
    final texto = noticia['noticia']?.toString() ??
        noticia['resumo']?.toString() ??
        'Sem conteúdo.';
    final fonte = noticia['fonte']?.toString() ?? 'Informativo';
    final autor = noticia['autor']?.toString();
    final link = noticia['link']?.toString();
    final foto = noticia['foto']?.toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header do Modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: GridColors.secondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fonte,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Conteúdo Rolável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (foto != null && foto.isNotEmpty && !foto.startsWith('data:'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            foto,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (autor != null && autor.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Por: $autor',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      texto,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Rodapé do Modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (link != null && link.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(link);
                        if (uri != null) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Ver fonte original'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Logo institucional
class _SafeLogoWidget extends StatelessWidget {
  final double size;
  const _SafeLogoWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetsUtils.logoJPG,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, error, __) {
        debugPrint('[_SafeLogoWidget] Falha ao carregar logo asset: $error');
        return SizedBox(
          height: size,
          width: size,
          child: const Center(
            child: Icon(Icons.business_center,
                color: GridColors.secondary, size: 24),
          ),
        );
      },
    );
  }
}

/// Campo de senha reutilizável dentro do dialog de troca de senha.
class _SenhaField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;

  const _SenhaField({
    required this.label,
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: IconButton(
          icon:
              Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
