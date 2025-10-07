// services/auth_service.dart
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool hasPermission(String permission) {
    // Implemente sua lógica de permissões aqui
    // Por enquanto, retorna true para testes
    return true;
  }

  // Método para obter o ID do usuário atual
  int getCurrentUserId() {
    // Retorna um ID fixo para testes - substitua pela sua lógica
    return 1;
  }
}
