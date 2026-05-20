import 'package:flutter/material.dart';
import '../../../models/role_model.dart';
import '../../services/role_caller.dart';

// Cores centralizadas para todo o componente
class GridColors {
  static const Color primary = Color(0xFF93070A);
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color primaryLight = Color(0xFFB84042);
  static const Color secondary = Color(0xFF005826);
  static const Color secondaryLight = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFF003D1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF000000);
  static const Color link = Color(0xFFFF0000);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF93070A);
  static const Color buttonBackground = Color(0xFF93070A);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF005826);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color filterBackground = Color(0xFFEFEFEF);
  static const Color hover = Color(0x1A000000);
  static const Color selectedRow = Color(0xFFE3F2FD);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x26000000);
}

class RoleDialog extends StatefulWidget {
  final int loginId;

  const RoleDialog({super.key, required this.loginId});

  @override
  _RoleDialogState createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  Role? _selectedRole;
  List<Role> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  _loadRoles() async {
    try {
      final roles = await RoleCaller().getRoles();
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  _associateRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma role'),
          backgroundColor: GridColors.error,
        ),
      );
      return;
    }

    try {
      await RoleCaller().associateRoleToLogin(
        widget.loginId,
        _selectedRole?.id ?? 0,
      );
      Navigator.of(context).pop(true); // Fecha o diálogo e indica sucesso
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao associar role: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Associar Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: GridColors.error))
            else
              DropdownButtonFormField<Role>(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: GridColors.inputBorder),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GridColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GridColors.primary),
                  ),
                ),
                initialValue: _selectedRole,
                items: _roles.map((Role role) {
                  return DropdownMenuItem<Role>(
                    value: role,
                    child: Text(role.description ?? ''),
                  );
                }).toList(),
                onChanged: (Role? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: GridColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _associateRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.buttonBackground,
                  ),
                  child: const Text(
                    'Associar',
                    style: TextStyle(color: GridColors.buttonText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
