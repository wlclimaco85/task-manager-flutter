// lib/dashboard/api_client.dart (atualizado)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/dashboard_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

class DashboardApiClient {
  DashboardApiClient();
  final token =
      AuthUtility.userInfo?.token; // Assuming userInfo.token is available

  final int empresaId =
      pegarEmpresaLogada(); // Exemplo fixo, ajustar conforme necessário
  final int? parceiroId =
      pegarEmpresaLogada(); // Exemplo fixo, ajustar conforme necessário
  Map<String, String> _qp([Map<String, String>? extra]) {
    final m = {
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
    };
    if (extra != null) m.addAll(extra);
    return m;
  }

  Future<List<FinancePoint>> fetchFinanceSeries({int months = 6}) async {
    final uri = Uri.parse(ApiLinks.getFinance)
        .replace(queryParameters: _qp({'months': months.toString()}));

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Important: Add Accept header
      },
    );
    if (res.statusCode != 200)
      throw Exception('Finance series error ${res.statusCode}');
    final data = jsonDecode(res.body) as List;
    return data.map((e) {
      final receivable = (e['receivable'] ?? 0) as num;
      final payable = (e['payable'] ?? 0) as num;

      return FinancePoint(
        e['month'] as String? ?? '',
        receivable.toDouble(),
        payable.toDouble(),
      );
    }).toList();
  }

  Future<TicketStatusCounts> fetchTicketStatusCounts() async {
    final uri =
        Uri.parse(ApiLinks.statusCounts).replace(queryParameters: _qp());
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Important: Add Accept header
      },
    );
    if (res.statusCode != 200)
      throw Exception('Tickets error ${res.statusCode}');
    final e = jsonDecode(res.body);
    return TicketStatusCounts(
        open: e['open'], inProgress: e['inProgress'], closed: e['closed']);
  }

  Future<List<ChatsDailyPoint>> fetchChatsDaily({int days = 7}) async {
    final uri = Uri.parse(ApiLinks.chatDaily)
        .replace(queryParameters: _qp({'days': days.toString()}));
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Important: Add Accept header
      },
    );
    if (res.statusCode != 200)
      throw Exception('Chats daily error ${res.statusCode}');
    final data = jsonDecode(res.body) as List;
    return data
        .map((e) =>
            ChatsDailyPoint(DateTime.parse(e['date']), e['openChats'] as int))
        .toList();
  }
}
