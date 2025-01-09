import 'package:flutter/material.dart';

class CustomColors {
  final Color _activePrimaryButton = const Color.fromARGB(255, 63, 81, 181);
  final Color _activeSecondaryButton = const Color.fromARGB(255, 230, 230, 255);
  final Color _gradientMainColor = const Color(0xff00ADFA);
  final Color _gradientSecColor = const Color(0xff00E6FD);
  final Color _appBarMainColor = const Color(0xff0A6D92);
  final Color _appFundoPage = const Color(0xFF5937B2);
  final Color _appFundoImput = const Color(0xFFffffff);
  final Color _appFundoClaro = const Color(0xFF7859C9);
  final Color _appBotton = const Color(0xFFFA903A);
  final Color _appLabelBotton = const Color(0xFFffffff);
  final Color _lightGreenBackground = const Color.fromARGB(255, 231, 247, 233);
  final Color _darkGreenBorder = const Color.fromARGB(255, 1, 247, 14);
  final Color _buttonBackground = const Color.fromARGB(255, 128, 202, 132);

  Color getButtonBackground() {
    return _buttonBackground;
  }

  Color getDarkGreenBorder() {
    return _darkGreenBorder;
  }

  Color getLightGreenBackground() {
    return _lightGreenBackground;
  }

  Color getActivePrimaryButtonColor() {
    return _activePrimaryButton;
  }

  Color getActiveSecondaryButton() {
    return _activeSecondaryButton;
  }

  Color getGradientMainColor() {
    return _gradientMainColor;
  }

  Color getGradientSecondaryColor() {
    return _gradientSecColor;
  }

  Color getAppBarMainColor() {
    return _appBarMainColor;
  }

  Color getAppFundoPage() {
    return _appFundoPage;
  }

  Color getAppFundoImput() {
    return _appFundoImput;
  }

  Color getAppFundoClaro() {
    return _appFundoClaro;
  }

  Color getAppBotton() {
    return _appBotton;
  }

  Color getAppLabelBotton() {
    return _appLabelBotton;
  }
}
