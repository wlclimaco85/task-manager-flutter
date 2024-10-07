import 'package:flutter/material.dart';

class CustomColors {
  final Color _activePrimaryButton = const Color.fromARGB(255, 0, 88, 38);
  final Color _activePrimaryButton2 = Color.fromARGB(255, 2, 121, 53);
  final Color _activeSecondaryButton = const Color.fromARGB(255, 230, 230, 255);
  final Color _gradientMainColor = const Color(0xff00ADFA);
  final Color _gradientSecColor = const Color(0xff00E6FD);
  final Color _appBarMainColor = const Color(0xff0A6D92);
  final Color _appFundoPage = const Color.fromARGB(255, 0, 88, 38);
  final Color _appFundoImput = const Color(0xFFffffff);
  final Color _appFundoClaro = const Color.fromARGB(255, 0, 88, 38);
  final Color _appBotton = const Color.fromARGB(255, 147, 7, 10);
  final Color _appLabelBotton = const Color(0xFFffffff);

  Color getActivePrimaryButtonColor() {
    return _activePrimaryButton;
  }

  Color getActivePrimaryButtonColor2() {
    return _activePrimaryButton2;
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
