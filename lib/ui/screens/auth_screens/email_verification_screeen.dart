import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/otp_varification.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';

class EmailVarificationScreeen extends StatefulWidget {
  const EmailVarificationScreeen({Key? key}) : super(key: key);

  @override
  State<EmailVarificationScreeen> createState() =>
      _EmailVarificationScreeenState();
}

class _EmailVarificationScreeenState extends State<EmailVarificationScreeen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 80,
                ),
                Text(
                  "Your Email Adderess",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "A 6 digit code has been sent to your email address. Please enter it below to continue.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(hintText: "Email"),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const OtpVarificationScreen()));
                    },
                    child: const Icon(
                      Icons.arrow_circle_right_outlined,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Have an Account?",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(letterSpacing: .7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
