import 'package:flutter/material.dart';

/// Identidade visual Abraço Contabilidade.
///
/// Vermelho (#93070A) e verde (#005826) — cores da marca Abraço.
class GridColors {
  static const Color primary = Color(0xFF93070A); // vermelho Abraço
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color primaryLight = Color(0xFFB84042);
  static const Color primarySoft = Color(0xFFFCEDEE); // vermelho muito claro
  static const Color secondary = Color(0xFF005826); // verde Abraço
  static const Color secondaryLight = Color(0xFF2E7D32);
  static const Color secondarySoft = Color(0xFFEAF5EE); // verde muito claro
  static const Color secondaryDark = Color(0xFF003D1A);
  static const Color accent = Color(0xFF2E7D32); // verde
  static const Color accentDark = Color(0xFF1B5E20);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryMuted = Color(0xB3FFFFFF);
  static const Color textSecondary = Color(0xFF17211B);
  static const Color textMuted = Color(0xFF64756A);
  static const Color link = Color(0xFF93070A);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF93070A);
  static const Color buttonBackground = Color(0xFF93070A);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6FAF7);
  static const Color shellBackground = Color(0xFF6A0507);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1976D2);
  static const Color divider = Color(0xFFD8E0DA);
  static const Color filterBackground = Color(0xFFF3F7F4);
  static const Color gridHeader = Color(0xFFF3F7F4);
  static const Color rowEven = Color(0xFFFFFFFF);
  static const Color rowOdd = Color(0xFFF6FAF7);
  static const Color hover = Color(0x1A93070A);
  static const Color selectedRow = Color(0xFFEAF5EE);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color warningDark = Color(0xFFE65100);
  static const Color neutral = Color(0xFF757575);
  static const Color borderSubtle = Color(0xFFDDDDDD);
  static const Color statusHoliday = Color(0xFF1565C0);
  static const Color statusClosed = Color(0xFF6A1B9A);
  static const Color statusNew = Color(0xFFFF9800);
  static const Color statusUnknown = Color(0xFFFFA000);
  static const Color pageBackground = Color(0xFFF6FAF7);
  static const Color surfaceMuted = Color(0xFFF3F7F4);
  static const Color disabledBackground = Color(0xFFE0E0E0);
  static const Color suggestionHigh = Color(0xFFE8F5E9);
  static const Color suggestionMedium = Color(0xFFFFF8E1);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x2693070A);
}

class CustomColors {
  final Color _lightGreenBackground = GridColors.card;
  final Color _darkGreenBorder = GridColors.primary;
  final Color _buttonBackground = GridColors.buttonBackground;
  final Color _textColorDesc = GridColors.textMuted;
  final Color _borderInput = GridColors.inputBorder;
  final Color _textColor = GridColors.textSecondary;
  final Color _negotiationCardBackground = GridColors.card;
  final Color _confirmButtonColor = GridColors.success;
  final Color _cancelButtonColor = GridColors.error;
  final Color _buttonTextColor = GridColors.buttonText;
  final Color _darkBlue = GridColors.shellBackground;
  final Color _headerTable = GridColors.filterBackground;
  final Color _showSnackBarError = GridColors.error;
  final Color _showSnackBarSuccess = GridColors.success;
  final Color _showSnackBarWarning = GridColors.warning;
  final Color _showSnackBarInfo = GridColors.info;
  final Color _showSnackBarText = GridColors.textPrimary;

  Color getShowSnackBarText() {
    return _showSnackBarText;
  }

  Color getShowSnackBarInfo() {
    return _showSnackBarInfo;
  }

  Color getShowSnackBarWarning() {
    return _showSnackBarWarning;
  }

  Color getShowSnackBarSuccess() {
    return _showSnackBarSuccess;
  }

  Color getShowSnackBarError() {
    return _showSnackBarError;
  }

  getBorderInput() {
    return _borderInput;
  }

  getLightGreenBackground() {
    return _lightGreenBackground;
  }

  getDarkBlue() {
    return _darkBlue;
  }

  getDarkGreenBorder() {
    return _darkGreenBorder;
  }

  getButtonBackground() {
    return _buttonBackground;
  }

  getTextColorDesc() {
    return _textColorDesc;
  }

  getTextColor() {
    return _textColor;
  }

  getNegotiationCardBackground() {
    return _negotiationCardBackground;
  }

  getConfirmButtonColor() {
    return _confirmButtonColor;
  }

  getCancelButtonColor() {
    return _cancelButtonColor;
  }

  getButtonTextColor() {
    return _buttonTextColor;
  }

  getHeaderTable() {
    return _headerTable;
  }
}
