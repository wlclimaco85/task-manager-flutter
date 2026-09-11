import '../../widgets/app_loading_overlay.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.appacademia.taskmanager';

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
  String _loginStepMessage = 'Autenticando credenciais...';
  bool _loadingNoticias = true;
  List<Map<String, dynamic>> _noticias = [];

  @override
  void initState() {
    super.initState();
    _carregarNoticias();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _carregarNoticias() async {
    try {
      final resp = await http
          .get(Uri.parse('${ApiLinks.noticiasPublicas}?limite=12'))
          .timeout(const Duration(seconds: 6));
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
            _loadingNoticias = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[LoginScreen] Falha ao carregar noticias publicas: $e');
    }

    if (mounted) {
      setState(() {
        if (_noticias.isEmpty) {
          _noticias = _noticiasFallback;
        }
        _loadingNoticias = false;
      });
    }
  }

  static const List<Map<String, dynamic>> _noticiasFallback = [
    {
      'id': 1,
      'titulo': 'Novidades no Portal do Cliente e Atendimento Integrado',
      'resumo':
          'Acompanhe seus documentos, guias de impostos, conciliações e converse com nossos atendentes diretamente pelo Chat em tempo real.',
      'categoria': 'COMUNICADO',
      'dtNoticia': '2026-09-10T10:00:00',
      'imagem':
          'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=200&auto=format&fit=crop&q=60',
    },
    {
      'id': 2,
      'titulo': 'Calendário Fiscal e Vencimento de Obrigações do Mês',
      'resumo':
          'Fique atento aos prazos de fechamento contábil e emissão de guias do mês. Acesse a aba Calendário para detalhes.',
      'categoria': 'FISCAL',
      'dtNoticia': '2026-09-08T09:00:00',
      'imagem':
          'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=200&auto=format&fit=crop&q=60',
    },
    {
      'id': 3,
      'titulo': 'Armazenamento em Nuvem e GED Inteligente com Busca por IA',
      'resumo':
          'Agora seus boletos, alvarás e contratos ficam armazenados com tempo de retenção customizado e localização instantânea no Chat.',
      'categoria': 'TECNOLOGIA',
      'dtNoticia': '2026-09-05T14:30:00',
      'imagem':
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=200&auto=format&fit=crop&q=60',
    },
    {
      'id': 4,
      'titulo': 'Conciliação Bancária Automática via Extrato OFX',
      'resumo':
          'Importe extratos OFX para conciliar recebimentos e despesas com agilidade e precisão contábil.',
      'categoria': 'FINANCEIRO',
      'dtNoticia': '2026-09-01T08:15:00',
      'imagem':
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=200&auto=format&fit=crop&q=60',
    },
    {
      'id': 5,
      'titulo': 'Emissão de NF-e, NFS-e e NFC-e Integrada ao Sistema',
      'resumo':
          'Emita suas notas fiscais de produto, serviço e cupons fiscais com regras tributárias pré-configuradas.',
      'categoria': 'EMISSÃO FISCAL',
      'dtNoticia': '2026-08-28T16:00:00',
      'imagem':
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=200&auto=format&fit=crop&q=60',
    },
  ];

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

    setState(() => _loginInProgress = false);
    if (resp.isSuccess && resp.body != null) {
      final model = LoginModel.fromJson(resp.body!);
      if ((model.token ?? '').isEmpty) {
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

      if (!mounted) return;
      if (model.login?.trocarSenhaProximoLogin == true) {
        final email = model.login?.email ?? '';
        if (email.isNotEmpty) {
          await _showTrocarSenhaDialog(email);
        }
        return;
      }
      _goHome();
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
          title: const Row(children: [
            Icon(Icons.lock_reset, color: GridColors.secondary, size: 24),
            SizedBox(width: 8),
            Text('Trocar senha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'É necessário definir uma nova senha antes de continuar.',
                    style: TextStyle(
                        fontSize: 13, color: GridColors.textSecondary),
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
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12)),
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
                    onToggle: () =>
                        setS(() => obscureConfirm = !obscureConfirm),
                  ),
                ],
              ),
            ),
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

    if (mounted) _goHome();
  }

  void _openNewsDetail(Map<String, dynamic> news) {
    showDialog(
      context: context,
      builder: (ctx) => _NewsDetailModal(news: news),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkGreenBg = Color(0xFF074828);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: darkGreenBg,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Top Horizontal Login Bar
            _TopHorizontalLoginBar(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              loginInProgress: _loginInProgress,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onLogin: _login,
            ),

            // Main Content Area with Green Background
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left/Center: System Modules (Included, Pricing, Optional)
                              Expanded(
                                flex: 7,
                                child: _SystemModulesShowcase(),
                              ),
                              const SizedBox(width: 16),
                              // Right Side: Flash News List (Image 3 style)
                              SizedBox(
                                width: 360,
                                child: _FlashNewsSidebar(
                                  loading: _loadingNoticias,
                                  noticias: _noticias,
                                  onSelectNews: _openNewsDetail,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FlashNewsSidebar(
                                loading: _loadingNoticias,
                                noticias: _noticias,
                                onSelectNews: _openNewsDetail,
                              ),
                              const SizedBox(height: 24),
                              _SystemModulesShowcase(),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // Footer info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: const Color(0xFF04341D),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '© ${DateTime.now().year} Abraço Contabilidade. Todos os direitos reservados.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Versão 2.4.0 (Build 2026.09)',
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
      ),
          if (_loginInProgress)
            Positioned.fill(
              child: AppLoadingOverlay(
                title: 'Iniciando Sessão',
                message: _loginStepMessage,
                isFullScreen: false,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Horizontal Login Bar (Header Branco, Bordas Verdes, Email e Senha Maiores)
// ---------------------------------------------------------------------------
class _TopHorizontalLoginBar extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loginInProgress;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _TopHorizontalLoginBar({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loginInProgress,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 980;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandHeader(),
                const SizedBox(height: 8),
                _buildLoginForm(context, isCompact: true),
              ],
            )
          : Row(
              children: [
                _buildBrandHeader(),
                const Spacer(),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: _buildLoginForm(context, isCompact: false),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            AssetsUtils.logoJPG,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.business,
              color: Color(0xFF074828),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ABRAÇO CONTABILIDADE',
              style: TextStyle(
                color: Color(0xFF074828),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Portal do Cliente & Gestão',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isCompact}) {
    const greenBorder = Color(0xFF074828);

    return Form(
      key: formKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Usuario / Email Field com Borda Verde e Largura Bem Maior
          SizedBox(
            width: isCompact ? 180 : 310,
            height: 36,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Usuário / E-mail',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.person_outline,
                    color: greenBorder, size: 17),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: greenBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: greenBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF15803D), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Senha Field com Borda Verde e Largura Bem Maior
          SizedBox(
            width: isCompact ? 160 : 240,
            height: 36,
            child: TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
              onFieldSubmitted: (_) => onLogin(),
              decoration: InputDecoration(
                hintText: 'Senha',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.lock_outline,
                    color: greenBorder, size: 17),
                suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 17,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: onTogglePassword,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: greenBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: greenBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF15803D), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botao Acessar (Vermelho em Destaque)
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: loginInProgress ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 2,
              ),
              child: loginInProgress
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Acessar',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Links Auxiliares
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmailVarificationScreeen()),
                ),
                child: const Text(
                  'Esqueceu a senha?',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SolicitacaoAcessoScreen()),
                ),
                child: const Text(
                  'Solicitar acesso',
                  style: TextStyle(
                    color: Color(0xFF074828),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF074828),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// System Modules Showcase (Banner de Preço em 1º com Borda Destacada, Cards 4 Colunas Fit)
// ---------------------------------------------------------------------------
class _SystemModulesShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Box de Módulos Contratados e Pacote Completo no Topo com Borda de Destaque
        _PricingBanner(),

        const SizedBox(height: 6),

        // 2. Seção: Já vem no sistema
        const Text(
          'Já vem no sistema',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        _buildModuleGrid(_includedModules, isIncluded: true),

        const SizedBox(height: 6),

        // 3. Seção: Módulos que podem ser contratados
        const Text(
          'Módulos que podem ser contratados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        _buildModuleGrid(_optionalModules, isIncluded: false),
      ],
    );
  }

  Widget _buildModuleGrid(List<_LoginModule> list, {required bool isIncluded}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 950 ? 4 : (constraints.maxWidth >= 650 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 5,
            childAspectRatio: crossAxisCount == 4 ? 3.0 : (crossAxisCount == 3 ? 3.4 : 2.8),
          ),
          itemBuilder: (context, i) {
            return _ModuleCard(module: list[i], isIncluded: isIncluded);
          },
        );
      },
    );
  }

  static const List<_LoginModule> _includedModules = [
    _LoginModule(
      title: 'Chat com o escritório',
      description: 'Conversas por setor com histórico para cliente e equipe.',
      icon: Icons.chat_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'Abertura de chamados',
      description:
          'Solicitações do cliente por setor e acompanhamento interno.',
      icon: Icons.support_agent_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'Informativos',
      description: 'Avisos, cobranças e comunicados enviados para clientes.',
      icon: Icons.campaign_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'Upload de extratos',
      description: 'Cliente envia extrato bancário direto pelo portal/app.',
      icon: Icons.file_upload_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'GED e documentos',
      description:
          'Organização de arquivos, anexos e documentos do cliente.',
      icon: Icons.folder_open_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'Calendário financeiro',
      description:
          'Agenda de vencimentos, guias, tarefas e compromissos.',
      icon: Icons.calendar_month_outlined,
      badge: 'Incluso',
    ),
    _LoginModule(
      title: 'Financeiro essencial',
      description:
          'Contas a pagar/receber, bancos, movimentação e centro de custo.',
      icon: Icons.account_balance_wallet_outlined,
      badge: 'Incluso',
    ),
  ];

  static const List<_LoginModule> _optionalModules = [
    _LoginModule(
      title: 'Fiscal e NF-e',
      description: 'XML, SPED, SINTEGRA, entradas, saídas e tributação.',
      icon: Icons.receipt_long_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'GME',
      description:
          'Gestor Micro Empreendedor para vendas, compras, produção e rotina operacional.',
      icon: Icons.storefront_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'NFS-e',
      description: 'Nota fiscal de serviço, prefeitura, tomador e serviços.',
      icon: Icons.description_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'NFC-e',
      description: 'Cupons fiscais, PDV, pagamentos e emissão para varejo.',
      icon: Icons.point_of_sale_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Precificação de contratos',
      description: 'Regras, reajustes e margens para contratos recorrentes.',
      icon: Icons.handshake_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Service Desk',
      description: 'SLA, filas, transferência e operação de suporte.',
      icon: Icons.headset_mic_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Projetos',
      description: 'Organização de entregas, etapas, responsáveis e status.',
      icon: Icons.account_tree_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Precificação',
      description: 'Cálculo comercial para serviços, pacotes e propostas.',
      icon: Icons.sell_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Financeiro avançado',
      description:
          'Régua de cobrança, kanban de pagamentos e conciliação bancária.',
      icon: Icons.insights_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'DRE gerencial',
      description: 'Indicadores de resultado, margem e análise de performance.',
      icon: Icons.stacked_line_chart_outlined,
      badge: 'Opcional',
    ),
    _LoginModule(
      title: 'Estoque e giro',
      description: 'Controle de estoque, giro de produto e alertas de reposição.',
      icon: Icons.inventory_2_outlined,
      badge: 'Opcional',
    ),
  ];
}

class _ModuleCard extends StatelessWidget {
  final _LoginModule module;
  final bool isIncluded;

  const _ModuleCard({
    required this.module,
    required this.isIncluded,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isIncluded ? const Color(0xFF2E7D32) : GridColors.primary;
    final iconBgColor =
        isIncluded ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isIncluded
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFFFCDD2),
          width: isIncluded ? 1 : 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(module.icon, color: badgeColor, size: 13),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      module.badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            module.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFD97706),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPriceBox(
                  icon: Icons.storefront_outlined,
                  iconColor: GridColors.primary,
                  title: 'Módulo contratado',
                  value: 'R\$ 99,90',
                  detail: 'por módulo',
                ),
              ),
              Container(
                width: 1,
                height: 26,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildPriceBox(
                  icon: Icons.all_inclusive_outlined,
                  iconColor: GridColors.primary,
                  title: 'Pacote completo',
                  value: 'R\$ 199,90',
                  detail: 'quantos módulos quiser usar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Se nenhuma opção atender sua demanda, fazemos um orçamento para criar a solução aqui mesmo dentro do nosso ambiente.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String detail,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: GridColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
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

// ---------------------------------------------------------------------------
// Flash News Lateral (Estilo Editorial com Suporte a Imagens do Banco de Dados)
// ---------------------------------------------------------------------------
class _FlashNewsSidebar extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> noticias;
  final Function(Map<String, dynamic>) onSelectNews;

  const _FlashNewsSidebar({
    required this.loading,
    required this.noticias,
    required this.onSelectNews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header FLASH NEWS
          Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFFD97706), size: 17),
              const SizedBox(width: 4),
              const Text(
                'FLASH NEWS',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'NOTÍCIAS',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 4),

          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GridColors.secondary,
                ),
              ),
            )
          else if (noticias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhuma notícia no momento.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: noticias.length > 5 ? 5 : noticias.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 8, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) {
                final n = noticias[i];
                return _FlashNewsItem(
                  news: n,
                  index: i,
                  onTap: () => onSelectNews(n),
                );
              },
            ),

          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 6),

          // Botao PlayStore no rodape da lateral
          const _PlayStoreButton(),
        ],
      ),
    );
  }
}

class _FlashNewsItem extends StatelessWidget {
  final Map<String, dynamic> news;
  final int index;
  final VoidCallback onTap;

  const _FlashNewsItem({
    required this.news,
    required this.index,
    required this.onTap,
  });

  String _formatDate(dynamic dt) {
    if (dt == null) return 'Hoje';
    try {
      final parsed = DateTime.parse(dt.toString());
      return DateFormat('• dd MMM, yyyy', 'pt_BR').format(parsed);
    } catch (_) {
      return '• Recente';
    }
  }

  static const List<String> _editorialThumbs = [
    'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=150&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=150&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=150&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=150&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=150&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=150&auto=format&fit=crop&q=60',
  ];

  @override
  Widget build(BuildContext context) {
    final title = news['titulo']?.toString() ?? news['tituloResu']?.toString() ?? 'Comunicado importante';
    final dateStr = _formatDate(news['dtNoticia'] ?? news['dtImport']);
    final rawFoto = news['foto'] ?? news['imagem'] ?? news['urlImagem'] ?? news['fotoUrl'];
    final id = news['id'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Col (Title + Date)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Thumbnail Image on Right
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFE2E8F0),
                child: _buildNewsThumbnail(rawFoto, id, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsThumbnail(dynamic rawFoto, dynamic id, int idx) {
    if (rawFoto != null) {
      final str = rawFoto.toString().trim();
      if (str.isNotEmpty && str != 'null') {
        if (str.startsWith('http://') || str.startsWith('https://')) {
          return Image.network(
            str,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackThumbnail(idx),
          );
        }
        if (str.startsWith('data:image')) {
          try {
            final commaIdx = str.indexOf(',');
            final base64Str = commaIdx != -1 ? str.substring(commaIdx + 1) : str;
            return Image.memory(
              base64Decode(base64Str),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackThumbnail(idx),
            );
          } catch (_) {
            return _buildFallbackThumbnail(idx);
          }
        }
      }
    }

    if (id != null && id.toString().isNotEmpty && id.toString() != '0') {
      return Image.network(
        '${ApiLinks.baseProdUrl}/api/public/noticias/foto/$id',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackThumbnail(idx),
      );
    }

    return _buildFallbackThumbnail(idx);
  }

  Widget _buildFallbackThumbnail(int idx) {
    final fallbackUrl = _editorialThumbs[idx % _editorialThumbs.length];
    return Image.network(
      fallbackUrl,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF074828).withValues(alpha: 0.15),
        child: const Center(
          child: Icon(
            Icons.article_outlined,
            color: Color(0xFF074828),
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// News Detail Modal
// ---------------------------------------------------------------------------
class _NewsDetailModal extends StatelessWidget {
  final Map<String, dynamic> news;

  const _NewsDetailModal({required this.news});

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    try {
      final parsed = DateTime.parse(dt.toString());
      return DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(parsed);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = news['titulo']?.toString() ?? '';
    final category = news['categoria']?.toString() ?? 'NOTÍCIA';
    final content = news['conteudo']?.toString() ??
        news['resumo']?.toString() ??
        'Conteúdo não disponível.';
    final date = _formatDate(news['dtNoticia'] ?? news['dtImport']);
    final imageUrl = news['imagem']?.toString() ?? news['urlImagem']?.toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF03331C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: GridColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Publicado em $date',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      content,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers & Components
// ---------------------------------------------------------------------------
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

class _PlayStoreButton extends StatelessWidget {
  const _PlayStoreButton();

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_playStoreUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a Play Store.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.android_outlined, size: 18),
      label: const Text('Baixar App na Play Store'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF044828),
        side: const BorderSide(color: Color(0xFF044828)),
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

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
