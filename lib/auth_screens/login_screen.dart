import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/web_image_helper.dart';

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
import '../services/network_caller.dart';
import 'email_verification_screeen.dart';
import 'signup_form_screen.dart';

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
      if (mounted) _goHome();
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
      onRequestAccess: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SignUpFormScreen())),
      fullHeightCompact: !_showNoticias,
    );

    return Scaffold(
      backgroundColor: GridColors.secondary,
      body: _showNoticias
          ? Column(children: [
              loginBanner,
              Expanded(
                  child: _NoticiasGrid(
                      noticias: _noticias, loading: _loadingNoticias)),
              const _EmpresaFooter(),
            ])
          : SafeArea(child: loginBanner),
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
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    if (isCompact) return _buildCompact(context);

    return Container(
      color: GridColors.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]),
          padding: const EdgeInsets.all(8),
          child: _SafeLogoWidget(size: 80),
        ),
        const SizedBox(width: 16),
        const Text(GridTexts.appShortTitle,
            textAlign: TextAlign.left,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                height: 1.3)),
        const SizedBox(width: 32),
        Flexible(
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
                key: formKey,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
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
                                : null),
                        const SizedBox(height: 8),
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
                                    color: Colors.white60,
                                    size: 18)),
                            validator: (v) => (v == null || v.isEmpty)
                                ? GridTexts.loginPasswordRequired
                                : null),
                      ])),
                      const SizedBox(width: 16),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: GridColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: loading ? null : onLogin,
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text(GridTexts.loginAction,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                            )),
                        TextButton(
                            onPressed: onForgot,
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: Size.zero),
                            child: const Text(GridTexts.forgotPassword,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10))),
                        TextButton(
                            onPressed: onRequestAccess,
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: Size.zero),
                            child: const Text(GridTexts.requestAccess,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10))),
                      ]),
                    ])))),
      ]),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final minHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: fullHeightCompact ? minHeight : 0),
      color: GridColors.secondary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        padding: const EdgeInsets.all(8),
                        child: _SafeLogoWidget(size: 86),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Text(
                          GridTexts.appShortTitle,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              height: 1.25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _field(
                      ctrl: emailCtrl,
                      hint: GridTexts.loginUserHint,
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? GridTexts.loginUserRequired
                          : null),
                  const SizedBox(height: 14),
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
                              color: Colors.white60,
                              size: 20)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? GridTexts.loginPasswordRequired : null),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: loading ? null : onLogin,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text(GridTexts.loginAction,
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 0,
                    children: [
                      TextButton(
                        onPressed: onForgot,
                        child: const Text(GridTexts.forgotPassword,
                            style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: onRequestAccess,
                        child: const Text(GridTexts.requestAccess,
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
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
      style: const TextStyle(color: Colors.white, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: GridColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(8)),
        errorStyle: const TextStyle(color: Colors.orange, fontSize: 10),
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

    // No web, usa <div> com background-image CSS para evitar CORS
    if (kIsWeb) {
      return buildPlatformImage(
        url: url,
        placeholder: widget.placeholder,
        width: double.infinity,
        height: double.infinity,
      );
    }

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
