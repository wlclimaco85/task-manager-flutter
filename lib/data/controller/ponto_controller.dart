import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ponto_model.dart';
import '../../data/services/ponto_service.dart';

class PontoState {
  final bool loading;
  final bool registering;
  final List<PontoModel> registros;
  final double? bancoHoras;
  final String? error;

  const PontoState({
    this.loading = false,
    this.registering = false,
    this.registros = const [],
    this.bancoHoras,
    this.error,
  });

  PontoState copyWith({
    bool? loading,
    bool? registering,
    List<PontoModel>? registros,
    double? bancoHoras,
    String? error,
  }) {
    return PontoState(
      loading: loading ?? this.loading,
      registering: registering ?? this.registering,
      registros: registros ?? this.registros,
      bancoHoras: bancoHoras ?? this.bancoHoras,
      error: error,
    );
  }
}

/// Provider do service
final pontoServiceProvider = Provider<PontoService>((ref) {
  return PontoService();
});

/// Controller por parceiroId (family)
final pontoControllerProvider =
    StateNotifierProvider.family<PontoController, PontoState, int>(
  (ref, parceiroId) {
    final service = ref.watch(pontoServiceProvider);
    return PontoController(
      service: service,
      parceiroId: parceiroId,
    )..carregarDiaAtual();
  },
);

class PontoController extends StateNotifier<PontoState> {
  final PontoService service;
  final int parceiroId;

  PontoController({
    required this.service,
    required this.parceiroId,
  }) : super(const PontoState());

  DateTime get _hoje => DateTime.now();

  /// Carrega as marcações do dia atual
  Future<void> carregarDiaAtual() async {
    try {
      state = state.copyWith(loading: true, error: null);

      final registros = await service.listarPorDia(
        parceiroId: parceiroId,
        data: _hoje,
      );

      registros.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      state = state.copyWith(
        loading: false,
        registros: registros,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Erro ao carregar marcações: $e',
      );
    }
  }

  /// Define automaticamente se é ENTRADA ou SAIDA
  TipoRegistro _proximoTipo() {
    if (state.registros.isEmpty) {
      return TipoRegistro.entrada;
    }

    final ultimo = state.registros.last;
    if (ultimo.tipo == TipoRegistro.entrada) {
      return TipoRegistro.saida;
    } else {
      return TipoRegistro.entrada;
    }
  }

  /// Registra ponto automático (ENTRADA/SAIDA)
  Future<bool> registrarPontoAutomatico({String? observacao}) async {
    try {
      state = state.copyWith(registering: true, error: null);

      final tipo = _proximoTipo();

      final novo = await service.registrarPonto(
        parceiroId: parceiroId,
        tipo: tipo,
        observacao: observacao,
      );

      if (novo != null) {
        final lista = [...state.registros, novo]
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

        state = state.copyWith(
          registering: false,
          registros: lista,
        );
        return true;
      } else {
        state = state.copyWith(
          registering: false,
          error: 'Não foi possível registrar o ponto.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        registering: false,
        error: 'Erro ao registrar ponto: $e',
      );
      return false;
    }
  }

  /// Carrega banco de horas para o mês atual
  Future<double?> carregarBancoHorasMesAtual() async {
    try {
      state = state.copyWith(loading: true, error: null);

      final agora = DateTime.now();

      final valor = await service.calcularBancoHoras(
        parceiroId: parceiroId,
        mesReferencia: agora,
      );

      state = state.copyWith(
        loading: false,
        bancoHoras: valor,
      );

      return valor;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Erro ao carregar banco de horas: $e',
      );
      return null;
    }
  }

  /// Gera PDF de batidas (últimos 30 dias, por exemplo)
  Future<Uint8List?> gerarRelatorioPdf() async {
    try {
      final fim = DateTime.now();
      final inicio = fim.subtract(const Duration(days: 30));

      return await service.gerarRelatorioPdf(
        parceiroId: parceiroId,
        inicio: inicio,
        fim: fim,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao gerar PDF: $e',
      );
      return null;
    }
  }

  // ====== CÁLCULOS DE HORAS ======

  Duration get horasTrabalhadas {
    final registros = [...state.registros]
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

    Duration total = Duration.zero;

    for (int i = 0; i < registros.length - 1; i++) {
      final atual = registros[i];
      final prox = registros[i + 1];

      if (atual.tipo == TipoRegistro.entrada &&
          prox.tipo == TipoRegistro.saida) {
        total += prox.dataHora.difference(atual.dataHora);
      }
    }

    return total;
  }

  Duration get intervaloTotal {
    final registros = [...state.registros]
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

    Duration total = Duration.zero;

    for (int i = 0; i < registros.length - 1; i++) {
      final atual = registros[i];
      final prox = registros[i + 1];

      if (atual.tipo == TipoRegistro.saida &&
          prox.tipo == TipoRegistro.entrada) {
        total += prox.dataHora.difference(atual.dataHora);
      }
    }

    return total;
  }

  String get horasTrabalhadasFormatada => _formatDuration(horasTrabalhadas);

  String get intervaloFormatado => _formatDuration(intervaloTotal);

  String _formatDuration(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    return '${horas}h ${minutos.toString().padLeft(2, '0')}min';
  }

  /// Lista de pares Entrada/Saída para exibir na tela
  List<Map<String, String>> get marcacoesAgrupadas {
    final registros = [...state.registros]
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

    final List<Map<String, String>> lista = [];

    for (int i = 0; i < registros.length; i++) {
      final r = registros[i];

      if (r.tipo == TipoRegistro.entrada) {
        String entrada = r.horaFormatada;
        String saida = '--:--';

        if (i + 1 < registros.length &&
            registros[i + 1].tipo == TipoRegistro.saida) {
          saida = registros[i + 1].horaFormatada;
        }

        lista.add({
          'entrada': entrada,
          'saida': saida,
        });
      }
    }

    return lista;
  }
}
