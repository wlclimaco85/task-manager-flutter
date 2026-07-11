import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../mobile/screens/bottom_navbar_screen.dart';
import '../../windows/screens/bottom_navbar_screen.dart';
import '../../web/screens/bottom_navbar_screen.dart';
import '../../models/auth_utility.dart';
import '../../models/login_model.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/security_matrix.dart';
import '../services/network_caller.dart';

/// LoginScreen MINIMALISTA — apenas email + senha + botão login.
/// Sem animações, notícias, diálogos ou widgets complexos.
/// Objetivo: testar se o erro "Null check operator" vai embora.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'wlclimaco@gmail.com');
  final _passwordController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  bool _loginInProgress = false;
  bool _obscurePassword = true;

  void _goHome() {
    if (kIsWeb) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WebBottomNavBarScreen()),
        (_) => false,
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WindowsBottomNavBarScreen()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loginInProgress = true);

    try {
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
              const SnackBar(content: Text(GridTexts.loginTokenMissing)),
            );
          }
          return;
        }

        await AuthUtility.setUserInfo(model);
        await ModuloAccess.load();

        if (!mounted) return;
        _goHome();
      } else if (mounted) {
        _passwordController.clear();
        final msg = resp.statusCode == 400 || resp.statusCode == 401
            ? GridTexts.loginInvalidCredentials
            : resp.statusCode == -1
                ? GridTexts.loginNoConnection
                : 'Erro ${resp.statusCode}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() => _loginInProgress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
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
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: GridColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(
                Icons.lock_outline,
                size: 64,
                color: GridColors.primary,
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email obrigatório';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Senha obrigatória';
                  if (v.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão Login
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loginInProgress ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    disabledBackgroundColor: GridColors.primary.withAlpha(128),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loginInProgress
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
