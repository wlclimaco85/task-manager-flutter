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
import '../../utils/api_links.dart';
import '../../utils/assets_utils.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/security_matrix.dart';
import '../../widgets/home_screen.dart';
import '../../widgets/responsive_widget.dart';
import '../services/network_caller.dart';
import 'email_verification_screeen.dart';
import 'solicitacao_acesso_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loginInProgress = false;
  bool _obscurePassword = true;
  bool _loadingNoticias = true;
  List<Map<String, dynamic>> _noticias = [];

  bool get _showNoticias =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed && mounted) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
            }
          });
    _carregarNoticias();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.of(context).disableAnimations) {
        _animCtrl
          ..duration = Duration.zero
          ..forward();
      }
    });
  }

  Future<void> _carregarNoticias() async {
    if (!_showNoticias) {
      if (mounted) setState(() => _loadingNoticias = false);
      return;
    }
    try {
      final resp = await http
          .get(Uri.parse('${ApiLinks.noticiasPublicas}?limite=48'))
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
        if (mounted) setState(() => _noticias = list);
      }
    } catch (error) {
      debugPrint('[LoginScreen] Falha ao carregar noticias publicas: $error');
    }
    if (mounted) setState(() => _loadingNoticias = false);
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loginInProgress = true);
    final resp = await NetworkCaller().postRequest(ApiLinks.login, {
      'email': _emailController.text.trim(),
      'password': _passwordController.text
    });
    setState(() => _loginInProgress = false);
    if (resp.isSuccess && resp.body != null) {
      final model = LoginModel.fromJson(resp.body!);
      if (model.token == null || model.token!.isEmpty) {
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
        await _showTrocarSenhaDialog(model.login!.email ?? '');
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
    final atualCtrl  = TextEditingController();
    final novaCtrl   = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureAtual   = true;
    bool obscureNova    = true;
    bool obscureConfirm = true;
    bool loading = false;
    String? erro;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(Icons.lock_reset, color: GridColors.secondary, size: 24),
            const SizedBox(width: 8),
            const Text('Trocar senha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(erro!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        final atual   = atualCtrl.text.trim();
                        final nova    = novaCtrl.text.trim();
                        final confirm = confirmCtrl.text.trim();
                        if (atual.isEmpty || nova.isEmpty || confirm.isEmpty) {
                          setS(() => erro = 'Preencha todos os campos.');
                          return;
                        }
                        if (nova.length < 6) {
                          setS(() => erro = 'A nova senha deve ter pelo menos 6 caracteres.');
                          return;
                        }
                        if (nova != confirm) {
                          setS(() => erro = 'Nova senha e confirmação não conferem.');
                          return;
                        }
                        setS(() { loading = true; erro = null; });
                        // Valida senha atual tentando autenticar
                        final checkResp = await NetworkCaller().postRequest(
                          ApiLinks.login,
                          {'email': email, 'password': atual},
                        );
                        if (!checkResp.isSuccess) {
                          setS(() { loading = false; erro = 'Senha atual incorreta.'; });
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
                          setS(() => erro = 'Erro ao alterar senha. Tente novamente.');
                        }
                      },
                child: loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
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
  void dispose() {
    _animCtrl.dispose();
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
      fullHeightCompact: !_showNoticias,
    );

    return Scaffold(
      body: ResponsiveWidget(
        mobileBuilder: (context, width) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GridColors.secondary, GridColors.secondaryDark],
            ),
          ),
          child: SafeArea(child: loginBanner),
        ),
        tabletBuilder: (context, width) => _showNoticias
            ? Column(children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GridColors.secondary, GridColors.secondaryDark],
                      ),
                    ),
                    child: SafeArea(child: loginBanner),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(children: [
                    Expanded(
                        child: _NoticiasGrid(
                            noticias: _noticias, loading: _loadingNoticias)),
                    const _EmpresaFooter(),
                  ]),
                ),
              ])
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [GridColors.secondary, GridColors.secondaryDark],
                  ),
                ),
                child: SafeArea(child: loginBanner),
              ),
        desktopBuilder: (context, width) => _showNoticias
            ? Row(children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [GridColors.secondary, GridColors.secondaryDark],
                      ),
                    ),
                    child: SafeArea(child: loginBanner),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(children: [
                    Expanded(
                        child: _NoticiasGrid(
                            noticias: _noticias, loading: _loadingNoticias)),
                    const _EmpresaFooter(),
                  ]),
                ),
              ])
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [GridColors.secondary, GridColors.secondaryDark],
                  ),
                ),
                child: SafeArea(child: loginBanner),
              ),
      ),
    );
  }
}

// -- Login Banner --
class _LoginBanner extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure, loading;
  final bool fullHeightCompact;
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
      required this.onRequestAccess,
      this.fullHeightCompact = false});

  @override
  Widget build(BuildContext context) {
    // Mobile (Android/iOS) usa sempre o layout compacto centralizado,
    // independente da largura reportada pelo emulador.
    final bool isMobile =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;
    final bool isCompact =
        isMobile || MediaQuery.sizeOf(context).width < 720;
    if (isCompact) return _buildCompact(context);

    // Desktop/Web: layout vertical centralizado com logo grande em cima
    final minHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo grande com moldura branca e sombra
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _SafeLogoWidget(size: 120),
                      ),
                      const SizedBox(height: 24),

                      // Nome da empresa
                      const Text(
                        GridTexts.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tagline
                      Text(
                        GridTexts.companyTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Campos de login
                      _field(
                        ctrl: emailCtrl,
                        hint: GridTexts.loginUserHint,
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? GridTexts.loginUserRequired
                            : null,
                      ),
                      const SizedBox(height: 16),
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
                          onPressed: onToggleObscure,
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: GridColors.textMuted,
                            size: 20,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? GridTexts.loginPasswordRequired
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Botao Acessar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: GridColors.primary.withValues(alpha: 0.4),
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
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Links secundarios
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: onForgot,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              GridTexts.forgotPassword,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '|',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onRequestAccess,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              GridTexts.requestAccess,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final minHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: fullHeightCompact ? minHeight : 0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo centralizado grande
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _SafeLogoWidget(size: 100),
                      ),
                      const SizedBox(height: 20),

                      // Nome
                      const Text(
                        GridTexts.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tagline
                      Text(
                        GridTexts.companyTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Campo usuario
                      _field(
                        ctrl: emailCtrl,
                        hint: GridTexts.loginUserHint,
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? GridTexts.loginUserRequired
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Campo senha
                      _field(
                        ctrl: passCtrl,
                        hint: GridTexts.loginPasswordHint,
                        icon: Icons.lock_outline,
                        obscure: obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!loading) onLogin();
                        },
                        suffix: IconButton(
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

                      // Botao Acessar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: GridColors.primary.withValues(alpha: 0.4),
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
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Links
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 0,
                        children: [
                          TextButton(
                            onPressed: onForgot,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: Text(
                              GridTexts.forgotPassword,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onRequestAccess,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: Text(
                              GridTexts.requestAccess,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
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
          ),
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
            borderSide: BorderSide(
                color: GridColors.divider, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: GridColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(12)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.error, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.error, width: 2),
            borderRadius: BorderRadius.circular(12)),
        errorStyle: const TextStyle(color: Colors.orange, fontSize: 11),
      ),
    );
  }
}

/// Logo institucional com fallback gracioso para ícone
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

// -- Grid de noticias (fundo verde clarinho) --
class _NoticiasGrid extends StatelessWidget {
  final List<Map<String, dynamic>> noticias;
  final bool loading;
  const _NoticiasGrid({required this.noticias, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.background,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            color: GridColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: GridColors.accent, borderRadius: BorderRadius.circular(4)),
                  child: const Text(GridTexts.newsTitle,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1))),
              const SizedBox(width: 10),
              const Text(GridTexts.newsSource,
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ])),
        Container(height: 2, color: GridColors.accent),
        Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: GridColors.secondary))
                : noticias.isEmpty
                    ? const Center(
                        child: Text(GridTexts.noNewsAvailable,
                            style: TextStyle(color: Colors.grey)))
                    : _buildGrid(context)),
      ]),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1200
        ? 4
        : w > 800
            ? 3
            : w > 500
                ? 2
                : 1;
    final cardWidth = (w - 32 - (cols - 1) * 12) / cols;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: noticias
            .map((n) => SizedBox(
                  width: cardWidth,
                  child: _NoticiaCard(noticia: n),
                ))
            .toList(),
      ),
    );
  }
}

// -- Card de noticia (fundo branco, borda verde suave) --
class _NoticiaCard extends StatelessWidget {
  final Map<String, dynamic> noticia;
  const _NoticiaCard({required this.noticia});

  Future<void> _abrirLink() async {
    final link = noticia['link'] as String? ?? '';
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [GridColors.secondary, GridColors.success],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.newspaper, color: Colors.white38, size: 36),
        SizedBox(height: 4),
        Text('Contabeis',
            style: TextStyle(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = noticia['titulo'] ?? noticia['tituloResu'] ?? '';
    final resumo = noticia['resumo'] ?? '';
    final foto = noticia['foto'] as String? ?? '';
    final id = noticia['id'];
    final data = _formatDate(noticia['dtNoticia'] ?? noticia['dtImport']);

    // Monta lista de URLs para tentar em cascata
    final List<String> imageUrls = _buildImageUrls(foto, id);
    return InkWell(
      onTap: _abrirLink,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GridColors.secondary.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem com fallback automático entre URLs
              SizedBox(
                height: 150,
                width: double.infinity,
                child: imageUrls.isEmpty
                    ? _placeholder()
                    : _MultiUrlImage(urls: imageUrls, placeholder: _placeholder()),
              ),
              // Texto colado na imagem
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: GridColors.textSecondary,
                              height: 1.3)),
                      const SizedBox(height: 4),
                      Text(resumo.isNotEmpty ? resumo : titulo,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: GridColors.divider,
                              height: 1.35)),
                      const SizedBox(height: 6),
                      Row(children: [
                        if (data.isNotEmpty)
                          Text(data,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        const Spacer(),
                        const Icon(Icons.open_in_new, size: 11, color: GridColors.primary),
                        const SizedBox(width: 3),
                        const Text(GridTexts.readMore,
                            style: TextStyle(
                                fontSize: 10,
                                color: GridColors.primary,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ]),
              ),
            ]),
      ),
    );
  }

  /// Retorna lista de URLs para tentar em cascata.
  /// Ordem: proxy backend primeiro (CORS-free + cache em DB) → URL direta (fallback desktop).
  List<String> _buildImageUrls(String foto, dynamic id) {
    // Normaliza protocol-relative (//cdn.contabeis.com.br/... → https://cdn...)
    final urlFoto = foto.startsWith('//') ? 'https:$foto' : foto;

    final temFotoValida = urlFoto.isNotEmpty &&
        urlFoto.startsWith('http') &&
        !urlFoto.startsWith('data:image/gif');

    final urls = <String>[];

    // 1ª tentativa: proxy do backend por ID (CORS-free, cache em memoria+DB no backend)
    if (id != null) {
      urls.add('${ApiLinks.baseUrl}/api/public/noticias/foto/$id');
    }

    // 2ª tentativa: URL direta (funciona no desktop sem CORS; na web pode ser bloqueada)
    if (temFotoValida) {
      final direct = urlFoto;
      if (!urls.contains(direct)) urls.add(direct);
    }

    return urls;
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    final s = dt.toString();
    if (s.length >= 10) {
      final p = s.substring(0, 10).split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    }
    return '';
  }
}

// -- Widget que tenta carregar imagens de uma lista de URLs em cascata --
class _MultiUrlImage extends StatefulWidget {
  final List<String> urls;
  final Widget placeholder;
  const _MultiUrlImage({required this.urls, required this.placeholder});

  @override
  State<_MultiUrlImage> createState() => _MultiUrlImageState();
}

class _MultiUrlImageState extends State<_MultiUrlImage> {
  int _idx = 0;

  @override
  void didUpdateWidget(_MultiUrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reseta o índice quando a lista de URLs muda (novo card / rebuild)
    if (oldWidget.urls != widget.urls) {
      _idx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_idx >= widget.urls.length) return widget.placeholder;
    final url = widget.urls[_idx];

    // Fix (card #463): antes, no web, isso usava HtmlElementView (<div> com
    // background-image CSS) para contornar CORS. O proxy do backend
    // (NoticiasImagemController, primeira URL da cascata em
    // _buildImageUrls) ja responde com Access-Control-Allow-Origin: *,
    // entao o workaround de CORS nao e mais necessario. HtmlElementView e
    // um PlatformView (elemento DOM fora do canvas do Flutter) e essa tela
    // chega a ter ate 48 instancias simultaneas (uma por card de noticia)
    // -- roteamento de ponteiro entre o canvas do Flutter e elementos DOM
    // embutidos e uma causa bem documentada de crashes tipo "Null check
    // operator... gestures library... while handling a pointer data
    // packet" no Flutter Web, exatamente o erro reportado em producao.
    // Usar Image.network em todas as plataformas elimina os PlatformViews.
    return Image.network(
      url,
      key: ValueKey('${url}_$_idx'),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Stack(alignment: Alignment.center, children: [
          widget.placeholder,
          const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
        ]);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[_MultiUrlImage] Falha ao carregar $url: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _idx++);
        });
        return widget.placeholder;
      },
    );
  }
}

// -- Rodape empresa --
class _EmpresaFooter extends StatelessWidget {
  const _EmpresaFooter();

  Future<void> _abrirLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(GridTexts.downloadOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            child: Wrap(
                spacing: 24,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
              const Text(GridTexts.footerCompany,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
              _infoItem(Icons.location_on,
                  GridTexts.footerAddress),
              _infoItem(Icons.phone, GridTexts.footerPhone),
              _infoItem(Icons.access_time, GridTexts.footerHours),
            ])),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => _abrirLink(context, ApiLinks.windowsDownloadUrl),
          icon: const Icon(Icons.download, size: 16, color: Colors.white70),
          label: const Text(GridTexts.downloadWindows,
              style: TextStyle(fontSize: 11, color: Colors.white70)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero),
        ),
      ]),
    );
  }

  Widget _infoItem(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white60),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]);
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
