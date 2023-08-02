// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/reset_screen.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/signup_button.dart';

class OtpVarificationScreen extends StatefulWidget {
  const OtpVarificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);
  final String email;

  @override
  State<OtpVarificationScreen> createState() => _OtpVarificationScreenState();
}

class _OtpVarificationScreenState extends State<OtpVarificationScreen> {
  final TextEditingController _otpTEController = TextEditingController();
  bool _isLoading = false;
  GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  Future<void> otpVerify() async {}

  @override
  void dispose() {
    _otpTEController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  "PIN VARIFICATION",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "A 6 digit code has been sent to your email address. Please enter it below to continue.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _otpFormKey,
                  child: PinCodeTextField(
                    controller: _otpTEController,
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    cursorColor: Colors.green,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      borderWidth: 0.5,
                      fieldWidth: 50,
                      inactiveFillColor: Colors.white,
                      inactiveColor: Colors.white,
                      activeColor: Colors.white,
                      selectedColor: Colors.green,
                      selectedFillColor: Colors.white,
                      activeFillColor: Colors.white,
                    ),
                  ),
                ),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CustomButton(
                        onPresse: () async {
                          if (_otpFormKey.currentState!.validate()) {
                            _isLoading = true;
                            setState(
                                () {}); // No need to check mounted here since setState will handle it.

                            // Capture the context before entering the async function.

                            NetworkResponse response = await NetworkCaller()
                                .getRequest(ApiLinks.recoverVerifyOTP(
                                    widget.email,
                                    _otpTEController.text.trim()));

                            _isLoading = false;
                            setState(
                                () {}); // No need to check mounted here since setState will handle it.
                            final BuildContext context = this.context;
                            if (response.isSuccess) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResetPasswordScreen(
                                    email: widget.email,
                                    otp: _otpTEController.text.trim(),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter valid OTP"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                const SizedBox(
                  height: 16,
                ),
                SignUpButton(
                  text: "Have An Account?",
                  onPresse: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
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
