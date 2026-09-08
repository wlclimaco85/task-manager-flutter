import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.washingtonclimaco.task_manager_flutter';

const List<_LoginModule> _includedModules = [
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
    description: 'Gestao avancada de documentos e entregas fiscais.',
    icon: Icons.folder_copy_outlined,
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
    if (_formKey.currentState == null || !_formKey.currentState!.validate())
      return;
    setState(() => _loginInProgress = true);
    // Bug de producao: uma excecao nao tratada aqui (ex.: erro de
    // configuracao em ApiLinks.login) travava o botao com o spinner ativo
    // pra sempre, sem chamar o backend e sem nenhum erro visivel — o
    // catch garante que _loginInProgress sempre volta a false.
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
    setState(() => _loginInProgress = false);
    if (resp.isSuccess && resp.body != null) {
      final model = LoginModel.fromJson(resp.body!);
      if ((model.token ?? "").isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(GridTexts.loginTokenMissing)));
        }
        return;
      }
      await AuthUtility.setUserInfo(model);
      // reset() força releitura de empresa-modulo/parceiro-modulo para o
      // usuário recém-logado — load() agora tem cache de sessão (guarda
      // _loaded) para evitar chamadas de rede redundantes, então sem o
      // reset aqui um segundo login (outro usuário/empresa) na mesma
      // sessão web reaproveitaria indevidamente os módulos do login
      // anterior.
      ModuloAccess.reset();
      await ModuloAccess.load();
      await PushNotificationService.registrarDispositivoLogado();
      await AlertaPollingService.instance.iniciar();
      if (!mounted) return;
      if (model.login?.trocarSenhaProximoLogin == true) {
        final email = model.login?.email ?? '';
        if (email.isNotEmpty) {
          await _showTrocarSenhaDialog(email);
        }
        return;
      }
      await _abrirSelecaoEmpresaOuHome();
    } else if (mounted) {
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
                        // Valida senha atual tentando autenticar
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
                        // Altera senha
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
    final loginBanner = _LoginBanner(
      emailCtrl: _emailController,
      passCtrl: _passwordController,
      formKey: _formKey,
      obscure: _obscurePassword,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      loading: _loginInProgress,
      onLogin: _login,
      onForgot: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EmailVarificationScreeen())),
      onRequestAccess: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SolicitacaoAcessoScreen())),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GridColors.secondary, GridColors.secondaryDark],
          ),
        ),
        child: SafeArea(child: loginBanner),
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

// -- Login Banner --
class _LoginBanner extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onLogin, onForgot, onRequestAccess;
  const _LoginBanner(
      {required this.emailCtrl,
      required this.passCtrl,
      required this.formKey,
      required this.obscure,
      required this.loading,
      required this.onToggleObscure,
      required this.onLogin,
      required this.onForgot,
      required this.onRequestAccess});

  @override
  Widget build(BuildContext context) {
    final minHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1060;
    final isMobile = width < 720;

    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 36,
                vertical: isMobile ? 24 : 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: _ProductShowcase()),
                          const SizedBox(width: 34),
                          SizedBox(width: 410, child: _buildLoginCard(context)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _CompactProductHeader(),
                          const SizedBox(height: 22),
                          _buildLoginCard(context),
                          const SizedBox(height: 22),
                          const _ProductShowcase(compact: true),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GridColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: GridColors.secondary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: _SafeLogoWidget(size: 82),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              GridTexts.appTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GridColors.secondaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              GridTexts.companyTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GridColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _field(
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
            const SizedBox(height: 14),
            _field(
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
                tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: GridColors.textMuted,
                  size: 20,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? GridTexts.loginPasswordRequired
                  : null,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading ? null : onLogin,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        GridTexts.loginAction,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 0,
              children: [
                TextButton(
                  onPressed: onForgot,
                  style: TextButton.styleFrom(
                    foregroundColor: GridColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text(
                    GridTexts.forgotPassword,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: onRequestAccess,
                  style: TextButton.styleFrom(
                    foregroundColor: GridColors.secondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text(
                    GridTexts.requestAccess,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _PlayStoreButton(),
          ],
        ),
      ),
    );
  }

  Widget _field(
      {required TextEditingController ctrl,
      required String hint,
      required IconData icon,
      bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType,
      Iterable<String>? autofillHints,
      TextInputAction? textInputAction,
      ValueChanged<String>? onFieldSubmitted,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: GridColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: GridColors.secondary, size: 22),
        suffixIcon: suffix,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: GridColors.divider, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(12)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.error, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.error, width: 2),
            borderRadius: BorderRadius.circular(12)),
        errorStyle: const TextStyle(color: GridColors.error, fontSize: 11),
      ),
    );
  }
}

/// Logo institucional com fallback gracioso para ícone
class _CompactProductHeader extends StatelessWidget {
  const _CompactProductHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Portal do escritorio para clientes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Chamados, comunicados, extratos e financeiro em um lugar so.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
        ),
      ],
    );
  }
}

class _ProductShowcase extends StatelessWidget {
  final bool compact;

  const _ProductShowcase({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          const Text(
            'Portal do escritorio para clientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Entrada do cliente com chamados, informativos, extratos, calendario e financeiro. Os modulos avancados entram por contratacao.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 17,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 24),
        ],
        const _ProductPreview(),
        const SizedBox(height: 22),
        _ModuleSection(
          title: 'Ja vem no sistema',
          modules: _includedModules,
          compact: compact,
        ),
        const SizedBox(height: 14),
        _ModuleSection(
          title: 'Modulos que podem ser contratados',
          modules: _optionalModules,
          compact: compact,
        ),
      ],
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: GridColors.primary,
            child: const Row(
              children: [
                Icon(Icons.dashboard_customize_outlined,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Painel operacional Abraco',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.verified_outlined, color: Colors.white, size: 18),
              ],
            ),
          ),
          const AspectRatio(
            aspectRatio: 16 / 7,
            child: _ErpPreviewCanvas(),
          ),
        ],
      ),
    );
  }
}

class _ErpPreviewCanvas extends StatelessWidget {
  const _ErpPreviewCanvas();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 560 || constraints.maxHeight < 155;
        if (compact) return const _CompactErpPreviewCanvas();

        return Container(
          color: const Color(0xFFF2F7F3),
          padding: EdgeInsets.all(compact ? 10 : 16),
          child: Row(
            children: [
              if (!compact) ...[
                const _PreviewSidebar(),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PreviewPill(
                          icon: Icons.chat_bubble_outline,
                          label: '3 chamados',
                          color: GridColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _PreviewPill(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'R\$ 24,8 mil',
                          color: GridColors.secondary,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _PreviewPanel(
                              title: 'Operacao do cliente',
                              children: [
                                _PreviewMetric(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Chamados abertos',
                                  value: 'Fiscal, DP e financeiro',
                                  color: GridColors.primary,
                                ),
                                _PreviewMetric(
                                  icon: Icons.upload_file_outlined,
                                  title: 'Extratos enviados',
                                  value: 'Banco, caixa e conciliacao',
                                  color: GridColors.secondary,
                                ),
                                if (!compact)
                                  _PreviewMetric(
                                    icon: Icons.calendar_month_outlined,
                                    title: 'Calendario financeiro',
                                    value: 'Guias e vencimentos',
                                    color: GridColors.secondaryDark,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: compact ? 4 : 5,
                            child: _PreviewPanel(
                              title: 'Financeiro',
                              children: [
                                _PreviewAmountLine(
                                  label: 'A pagar',
                                  value: '12',
                                  color: GridColors.primary,
                                ),
                                _PreviewAmountLine(
                                  label: 'A receber',
                                  value: '18',
                                  color: GridColors.secondary,
                                ),
                                _PreviewAmountLine(
                                  label: 'Bancos',
                                  value: '4',
                                  color: GridColors.secondaryDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactErpPreviewCanvas extends StatelessWidget {
  const _CompactErpPreviewCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F7F3),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Central do cliente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GridColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: const [
                _CompactPreviewTile(
                  icon: Icons.support_agent_outlined,
                  label: 'Chamados',
                  color: GridColors.primary,
                ),
                _CompactPreviewTile(
                  icon: Icons.upload_file_outlined,
                  label: 'Extratos',
                  color: GridColors.secondary,
                ),
                _CompactPreviewTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendario',
                  color: GridColors.secondaryDark,
                ),
                _CompactPreviewTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Financeiro',
                  color: GridColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPreviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactPreviewTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSidebar extends StatelessWidget {
  const _PreviewSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      decoration: BoxDecoration(
        color: GridColors.secondaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: const Column(
        children: [
          _PreviewSidebarDot(icon: Icons.home_outlined, selected: true),
          SizedBox(height: 10),
          _PreviewSidebarDot(icon: Icons.support_agent_outlined),
          SizedBox(height: 10),
          _PreviewSidebarDot(icon: Icons.campaign_outlined),
          SizedBox(height: 10),
          _PreviewSidebarDot(icon: Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }
}

class _PreviewSidebarDot extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _PreviewSidebarDot({required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected
            ? GridColors.primary
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PreviewPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreviewPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GridColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _PreviewMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewAmountLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewAmountLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GridColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleSection extends StatelessWidget {
  final String title;
  final List<_LoginModule> modules;
  final bool compact;

  const _ModuleSection({
    required this.title,
    required this.modules,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = compact ? 268.0 : 230.0;
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 10,
          runSpacing: 10,
          children: modules
              .map<Widget>((module) => SizedBox(
                    width: cardWidth,
                    child: _ModuleCard(module: module),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _LoginModule module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final isIncluded = module.badge == 'Incluso';
    final badgeColor = isIncluded ? GridColors.secondary : GridColors.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncluded
              ? GridColors.secondaryLight.withValues(alpha: 0.35)
              : GridColors.primaryLight.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(module.icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      module.badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            module.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GridColors.textMuted,
              fontSize: 12,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayStoreButton extends StatelessWidget {
  const _PlayStoreButton();

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
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.android_outlined, size: 18),
      label: const Text('Baixar na Play Store'),
      style: OutlinedButton.styleFrom(
        foregroundColor: GridColors.secondary,
        side: const BorderSide(color: GridColors.secondary),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

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
                color: GridColors.secondary, size: 40),
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
