import 'package:flutter/material.dart';

class CustomColors {
  // 🔹 Fundo principal da tela
  final Color _lightGreenBackground = const Color.fromARGB(
    255,
    195,
    224,
    207,
  ); // fundo secundário
  final Color _darkGreenBorder = const Color(0xFF93070A); // bordas/ação
  final Color _buttonBackground = const Color(0xFF93070A); // botões
  final Color _buttonTextColor = const Color(0xFFFFFFFF); // texto do botão
  final Color _textColor = const Color(0xFFFFFFFF); // textos principais
  final Color _textColorDesc = const Color(0xFF000000); // textos secundários
  final Color _borderInput = const Color(0xFF93070A); // borda do input
  final Color _negotiationCardBackground = const Color(0xFFFFFFFF); // cards
  final Color _confirmButtonColor = const Color(0xFF93070A);
  final Color _cancelButtonColor = Colors.red;
  final Color _darkBlue = const Color(0xFF93070A); // header tabela
  final Color _headerTable = const Color(0xFF93070A);
  final Color _showSnackBarError = const Color(0xFFD32F2F);
  final Color _showSnackBarSuccess = const Color(0xFF2E7D32);
  final Color _showSnackBarWarning = const Color(0xFFFFA000);
  final Color _showSnackBarInfo = const Color(0xFF1976D2);
  final Color _showSnackBarText = const Color(0xFFFFFFFF);

  Color getShowSnackBarText() => _showSnackBarText;
  Color getShowSnackBarInfo() => _showSnackBarInfo;
  Color getShowSnackBarWarning() => _showSnackBarWarning;
  Color getShowSnackBarSuccess() => _showSnackBarSuccess;
  Color getShowSnackBarError() => _showSnackBarError;

  Color getBorderInput() => _borderInput;
  Color getLightGreenBackground() => _lightGreenBackground;
  Color getDarkBlue() => _darkBlue;
  Color getDarkGreenBorder() => _darkGreenBorder;
  Color getButtonBackground() => _buttonBackground;
  Color getTextColorDesc() => _textColorDesc;
  Color getTextColor() => _textColor;
  Color getNegotiationCardBackground() => _negotiationCardBackground;
  Color getConfirmButtonColor() => _confirmButtonColor;
  Color getCancelButtonColor() => _cancelButtonColor;
  Color getButtonTextColor() => _buttonTextColor;
  Color getHeaderTable() => _headerTable;
}
