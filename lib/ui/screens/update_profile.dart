import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/custom_text_form_field.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';

class UpdateProfileScreen extends StatelessWidget {
  UpdateProfileScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 50,
              ),
              const Text(
                "Update Profile",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                  hintText: "Email",
                  controller: _emailController,
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 8,
              ),
              CustomTextFormField(
                  hintText: "First Name",
                  controller: _firstNameController,
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 8,
              ),
              CustomTextFormField(
                  hintText: "Last Name",
                  controller: _lastNameController,
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 8,
              ),
              CustomTextFormField(
                  hintText: "Phone Number",
                  controller: _phoneNumberController,
                  textInputType: TextInputType.phone),
              const SizedBox(
                height: 8,
              ),
              CustomTextFormField(
                  hintText: "Password",
                  controller: _passwordController,
                  textInputType: TextInputType.text),
              const SizedBox(
                height: 8,
              ),
              CustomButton(
                onPresse: () {},
              ),
            ],
          ),
        ),
      )),
    );
  }
}
