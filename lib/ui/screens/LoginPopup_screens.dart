import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/screens/ForgotPasswordScreen_screens.dart';
import 'package:task_manager_flutter/ui/screens/SignUpScreen_screens.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';

class LoginPopup extends StatefulWidget {
  @override
  _LoginPopupState createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginss(String username, String password) async {
    isLoading = true;

    Map<String, dynamic> requestBody = {
      "email": username,
      "password": password,
    };

    try {
      final NetworkResponse response =
          await NetworkCaller().postRequest(ApiLinks.login, requestBody);

      isLoading = false;

      if (response.isSuccess) {
        LoginModel model = LoginModel.fromJson(response.body!);
        await AuthUtility.setUserInfo(model);

        if (mounted) {
          // Fechar o popup após login bem-sucedido
          Navigator.of(context).pop();
        }
      } else if (response.statusCode == 400) {
        // Caso a resposta seja 400, exibir mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha ou usuário inválido')),
        );
      } else {
        // Tratar outros status de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${response.statusCode}')),
        );
      }
    } catch (e) {
      isLoading = false;
      if (mounted) {
        setState(() {});
      }

      // Exibir erro genérico para qualquer exceção
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _submitLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      String username = _usernameController.text;
      String password = _passwordController.text;

      if (username.isNotEmpty && password.isNotEmpty) {
        await loginss(username, password);
        Navigator.of(context).pop(); // Fecha o popup após o sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha os campos corretamente!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 231, 247, 233),
      title: const Text(
        'Login',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Usuário',
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 128, 202, 132),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 128, 202, 132),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _navigateToForgotPassword,
                child: const Text(
                  'Esqueci a senha',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _navigateToSignUp,
                child: const Text(
                  'Criar Novo Usuário',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 128, 202, 132),
            ),
            child: const Text(
              'Entrar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
