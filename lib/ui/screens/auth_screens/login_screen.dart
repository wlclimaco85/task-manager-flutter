import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/email_verification_screeen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/reset_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/signup_form_screen.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/signup_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  "Getting Start With",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(hintText: "Email"),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(hintText: "Password"),
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomButton(
                  onPresse: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen()),
                        (route) => false);
                  },
                ),
                const SizedBox(
                  height: 40,
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const EmailVarificationScreeen()));
                    },
                    child: const Text(
                      "Forgate Password?",
                      style: TextStyle(color: Colors.grey, letterSpacing: .7),
                    ),
                  ),
                ),
                SignUpButton(
                  text: "Have An Account?",
                  onPresse: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpFormScreen()),
                    );
                  },
                  buttonText: 'Sign In',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
