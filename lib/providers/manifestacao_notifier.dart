import 'package:flutter/foundation.dart';
import '../models/manifestacao/manifestacao_model.dart';
import '../models/manifestacao/manifestacao_request.dart';
import '../models/manifestacao/manifestacao_status.dart';

/// Notifier para gerenciar estado de manifestação
class ManifestacaoNotifier extends ChangeNotifier {
  ManifestacaoModel? _manifestacao;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  ManifestacaoModel? get manifestacao => _manifestacao;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  bool get isFormValid => _manifestacao?.isValid ?? false;

  /// Carrega dados da manifestação (simulado)
  Future<void> loadManifestacao(String nfeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulação de carregamento
      await Future.delayed(Duration(milliseconds: 500));

      _manifestacao = ManifestacaoModel(
        nfeId: nfeId,
        numero: 'NFe 123456789',
        fornecedor: 'Fornecedor Exemplo Ltda',
        valor: 'R\$ 1.000,00',
        dataEmissao: DateTime.now(),
      );
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Erro ao carregar manifestação: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Atualiza o status da manifestação
  void setStatus(ManifestacaoStatus? status) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(status: status);
    notifyListeners();
  }

  /// Atualiza a observação
  void setObservacao(String obs) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(observacao: obs);
    notifyListeners();
  }

  /// Atualiza a quantidade recebida (para parcial)
  void setQuantidadeRecebida(int? qtd) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(quantidadeRecebida: qtd);
    notifyListeners();
  }

  /// Atualiza motivo da recusa
  void setMotivoRecusa(String? motivo) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(motivoRecusa: motivo);
    notifyListeners();
  }

  /// Submete a manifestação (simulado)
  Future<bool> submitManifestacao() async {
    if (!isFormValid || _manifestacao == null) {
      _errorMessage = 'Formulário inválido';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulação de envio à API
      await Future.delayed(Duration(seconds: 2));

      final request = ManifestacaoRequest(
        nfeId: _manifestacao!.nfeId,
        statusCodigo: _manifestacao!.status!.codigo,
        observacao: _manifestacao!.observacao,
        quantidadeRecebida: _manifestacao!.quantidadeRecebida,
        motivoRecusa: _manifestacao!.motivoRecusa,
      );

      // Log do envio (usar logger do projeto em produção)
      // print('Enviando manifestação: ${request.toJson()}');

      _isSubmitting = false;
      _manifestacao = null; // Limpa após sucesso
    } catch (e) {
      _errorMessage = 'Erro ao enviar manifestação: $e';
      _isSubmitting = false;
    }
    notifyListeners();
    return _errorMessage == null;
  }

  /// Limpa o erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reseta o formulário
  void reset() {
    _manifestacao = null;
    _errorMessage = null;
    _isLoading = false;
    _isSubmitting = false;
    notifyListeners();
  }
}
