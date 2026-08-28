import '../models/auth_utility.dart';
import '../models/login_model.dart';

Map<String, dynamic> buildLoginAdditionalFormData({
  Login? sessionLogin,
  bool ativo = false,
}) {
  final login = sessionLogin ?? AuthUtility.userInfo?.login;
  final tipoLogin = login?.tipoLogin?.value;

  return {
    if (ativo) 'ativo': true,
    'trocarSenhaProximoLogin': true,
    'aplicativo': {'id': 1},
    if (tipoLogin != null) 'tipoLogin': tipoLogin,
  };
}
