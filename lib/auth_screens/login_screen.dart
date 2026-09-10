import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../mobile/screens/bottom_navbar_screen.dart';
import '../../windows/screens/bottom_navbar_screen.dart';
import '../../web/screens/bottom_navbar_screen.dart';
import '../../models/auth_utility.dart';
import '../../models/login_model.dart';
import '../../utils/api_links.dart';
import '../../utils/assets_utils.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/security_matrix.dart';
import '../services/network_caller.dart';
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

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
      'categoria': 'Comunicado',
      'dtNoticia': '2026-09-10T10:00:00',
    },
    {
      'id': 2,
      'titulo': 'Calendário Fiscal e Vencimento de Obrigações',
      'resumo':
          'Fique atento aos prazos de fechamento contábil e emissão de guias do mês. Acesse a aba Calendário para detalhes.',
      'categoria': 'Fiscal',
      'dtNoticia': '2026-09-08T09:00:00',
    },
    {
      'id': 3,
      'titulo': 'Armazenamento em Nuvem e GED Inteligente com Busca por IA',
      'resumo':
          'Agora seus boletos, alvarás e contratos ficam armazenados com tempo de retenção customizado e localização instantânea no Chat.',
      'categoria': 'Tecnologia',
      'dtNoticia': '2026-09-05T14:30:00',
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
    setState(() => _loginInProgress = true);
    final resp = await NetworkCaller().postRequest(ApiLinks.login, {
      'email': _emailController.text.trim(),
      'password': _passwordController.text
    });
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
      await AuthUtility.setUserInfo(model);
      await ModuloAccess.load();
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
                          setS(() => erro =
                              'Nova senha e confirmação não conferem.');
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
                          setS(() => erro =
                              'Erro ao alterar senha. Tente novamente.');
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

  @override
  Widget build(BuildContext context) {
    final bool isNarrow = MediaQuery.sizeOf(context).width < 880;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: isNarrow
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Layout Desktop: Login no Topo Horizontal + Boxes no Topo + Carrossel Lateral
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // 1. Top Bar Horizontal de Login
        _TopHorizontalLoginBar(
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
                  builder: (_) => const EmailVarificationScreeen())),
          onRequestAccess: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SolicitacaoAcessoScreen())),
        ),

        // 2. Área Principal (Fit to Screen sem scroll no desktop):
        // Coluna Esquerda: Boxes das Funcionalidades
        // Coluna Direita (onde antes ficava o login): Carrossel de Notícias
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Boxes das Funcionalidades
                const Expanded(
                  flex: 6,
                  child: _FuncionalidadesBoxes(),
                ),
                const SizedBox(width: 16),
                // Carrossel com as últimas notícias
                Expanded(
                  flex: 4,
                  child: _NoticiasCarousel(
                    noticias: _noticias,
                    loading: _loadingNoticias,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Rodapé sutil
        const _CompactFooter(),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Layout Mobile / Compacto
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com Logo
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: _SafeLogoWidget(size: 70),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              GridTexts.appTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.secondary,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de Login
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Usuário ou E-mail',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? GridTexts.loginUserRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? GridTexts.loginPasswordRequired
                          : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _loginInProgress ? null : _login,
                      child: _loginInProgress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text(GridTexts.loginAction,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const EmailVarificationScreeen())),
                          child: const Text('Esqueceu a senha?',
                              style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SolicitacaoAcessoScreen())),
                          child: const Text('Solicitar acesso',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Carrossel de Notícias
          SizedBox(
            height: 280,
            child: _NoticiasCarousel(
              noticias: _noticias,
              loading: _loadingNoticias,
            ),
          ),
          const SizedBox(height: 16),

          // Boxes de Funcionalidades
          const _FuncionalidadesBoxes(),
          const SizedBox(height: 16),
          const _CompactFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Top Bar Horizontal de Login (Header Superior Compacto)
// ─────────────────────────────────────────────────────────────────────────────
class _TopHorizontalLoginBar extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onLogin, onForgot, onRequestAccess;

  const _TopHorizontalLoginBar({
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
    return Container(
      decoration: const BoxDecoration(
        color: GridColors.secondary,
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Logo e Título à Esquerda
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _SafeLogoWidget(size: 38),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ABRAÇO CONTABILIDADE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Portal do Cliente & Gestão',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Formulário Horizontal Flexível
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo Usuário
                    SizedBox(
                      width: 160,
                      height: 36,
                      child: TextFormField(
                        controller: emailCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Usuário / E-mail',
                          hintStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Colors.white70, size: 16),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? '' : null,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Campo Senha
                    SizedBox(
                      width: 150,
                      height: 36,
                      child: TextFormField(
                        controller: passCtrl,
                        obscureText: obscure,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Senha',
                          hintStyle: const TextStyle(color: Colors.white60, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.white70, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                              size: 15,
                            ),
                            onPressed: onToggleObscure,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? '' : null,
                        onFieldSubmitted: (_) {
                          if (!loading) onLogin();
                        },
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: loading ? null : onLogin,
                        child: loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Acessar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Links de Apoio
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onForgot,
                          child: const Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: onRequestAccess,
                          child: const Text(
                            'Solicitar acesso',
                            style: TextStyle(
                              color: Color(0xFFFBD38D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Boxes das Funcionalidades no Topo (Cards Compactos Fit-to-Screen)
// ─────────────────────────────────────────────────────────────────────────────
class _FuncionalidadesBoxes extends StatelessWidget {
  const _FuncionalidadesBoxes();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Seção de Funcionalidades
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: GridColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: GridColors.secondary, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Módulos & Recursos Integrados',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    Text(
                      'Ambiente unificado para clientes, contadores e parceiros',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: GridColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '100% Online',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: GridColors.successDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Grid dos 6 Módulos Principais
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth < 450 ? 2 : 3;
                return GridView.count(
                  crossAxisCount: cols,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.55,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _ModuloCard(
                      icon: Icons.forum_rounded,
                      cor: GridColors.info,
                      titulo: 'Chat & Atendimento',
                      descricao:
                          'Conversas setorizadas, protocolos e envio de anexos em tempo real.',
                    ),
                    _ModuloCard(
                      icon: Icons.support_agent_rounded,
                      cor: GridColors.primary,
                      titulo: 'Chamados & Tickets',
                      descricao:
                          'Abertura de solicitações com controle de SLA e kanban visual.',
                    ),
                    _ModuloCard(
                      icon: Icons.folder_shared_rounded,
                      cor: GridColors.secondary,
                      titulo: 'GED & Documentos',
                      descricao:
                          'Armazenamento em nuvem com retenção e busca inteligente por IA.',
                    ),
                    _ModuloCard(
                      icon: Icons.event_available_rounded,
                      cor: GridColors.warning,
                      titulo: 'Calendário Fiscal',
                      descricao:
                          'Vencimento de tributos, guias DAS/FGTS e alertas automáticos.',
                    ),
                    _ModuloCard(
                      icon: Icons.query_stats_rounded,
                      cor: GridColors.successDark,
                      titulo: 'Gestão Financeira',
                      descricao:
                          'Contas a pagar/receber, DRE, fluxo de caixa e evolução.',
                    ),
                    _ModuloCard(
                      icon: Icons.account_balance_rounded,
                      cor: GridColors.accent,
                      titulo: 'Conciliação Bancária',
                      descricao:
                          'Importação de extratos OFX, ajuste de saldo e baixa automática.',
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Faixa de Módulos Opcionais / Ecossistema
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.extension_rounded,
                        color: GridColors.secondary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Extensões:',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748)),
                    ),
                  ],
                ),
                _badgeModulo('NF-e Entrada / XML'),
                _badgeModulo('NFS-e Nacional'),
                _badgeModulo('NFC-e / PDV'),
                _badgeModulo('SPED & Fiscal'),
                _badgeModulo('Ponto Eletrônico'),
                _badgeModulo('Trading & Sinais'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _badgeModulo(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568)),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String titulo;
  final String descricao;

  const _ModuloCard({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: cor, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF718096),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Carrossel de Últimas Notícias (Coluna Lateral onde ficava o login)
// ─────────────────────────────────────────────────────────────────────────────
class _NoticiasCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> noticias;
  final bool loading;

  const _NoticiasCarousel({
    required this.noticias,
    required this.loading,
  });

  @override
  State<_NoticiasCarousel> createState() => _NoticiasCarouselState();
}

class _NoticiasCarouselState extends State<_NoticiasCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _NoticiasCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noticias.length != oldWidget.noticias.length) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.noticias.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.noticias.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _abrirDetalhes(Map<String, dynamic> noticia) {
    showDialog(
      context: context,
      builder: (_) => _NewsDetailModal(noticia: noticia),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final itens = widget.noticias;
    if (itens.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('Nenhuma notícia cadastrada no momento.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Carrossel
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GridColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: GridColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Últimas Notícias & Avisos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              // Controles de Navegação Manual
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < itens.length - 1
                    ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Slide do Carrossel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: itens.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final noticia = itens[index];
                final titulo =
                    noticia['titulo']?.toString() ?? 'Informativo';
                final resumo = noticia['resumo']?.toString() ??
                    noticia['conteudo']?.toString() ??
                    '';
                final categoria =
                    noticia['categoria']?.toString() ?? 'Geral';
                final dataRaw = noticia['dtNoticia']?.toString() ??
                    noticia['dtImport']?.toString();

                String dataStr = '';
                if (dataRaw != null) {
                  try {
                    dataStr = DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(dataRaw));
                  } catch (_) {}
                }

                return InkWell(
                  onTap: () => _abrirDetalhes(noticia),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag de Categoria + Data
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    GridColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                categoria.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: GridColors.secondary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (dataStr.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 11, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    dataStr,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Título
                        Text(
                          titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Resumo
                        Expanded(
                          child: Text(
                            resumo,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF718096),
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Botão Ler Mais
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Ler notícia completa',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: GridColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: GridColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Dots de Paginação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              itens.length,
              (idx) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == idx ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == idx
                      ? GridColors.secondary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal de Detalhes da Notícia
// ─────────────────────────────────────────────────────────────────────────────
class _NewsDetailModal extends StatelessWidget {
  final Map<String, dynamic> noticia;
  const _NewsDetailModal({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final titulo = noticia['titulo']?.toString() ?? 'Informativo';
    final conteudo = noticia['conteudo']?.toString() ??
        noticia['resumo']?.toString() ??
        '';
    final categoria = noticia['categoria']?.toString() ?? 'Comunicado';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GridColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              categoria.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GridColors.secondary),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              Text(
                conteudo,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.secondary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilitários de Logo e Footer
// ─────────────────────────────────────────────────────────────────────────────
class _SafeLogoWidget extends StatelessWidget {
  final double size;
  const _SafeLogoWidget({this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetsUtils.logoJPG,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.business_rounded,
        size: size * 0.7,
        color: GridColors.secondary,
      ),
    );
  }
}

class _CompactFooter extends StatelessWidget {
  const _CompactFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© 2026 Abraço Contabilidade. Todos os direitos reservados.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          Text(
            'Versão 2.4.0 (Build 2026.09)',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
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
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
