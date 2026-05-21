import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../../utils/app_logger.dart';

class FornecedorService {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allFornecedores,
      );
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      L.e('FornecedorService.fetchAll: $e');
    }
    return [];
  }

  static Future<bool> create(Map<String, dynamic> data) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.createFornecedor,
        data,
      );
      return response.isSuccess;
    } catch (e) {
      L.e('FornecedorService.create: $e');
      return false;
    }
  }

  static Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final NetworkResponse response = await NetworkCaller().putRequest(
        ApiLinks.updateFornecedor(id.toString()),
        data,
      );
      return response.isSuccess;
    } catch (e) {
      L.e('FornecedorService.update: $e');
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    try {
      final NetworkResponse response = await NetworkCaller().deleteRequest(
        ApiLinks.deleteFornecedor(id.toString()),
      );
      return response.isSuccess;
    } catch (e) {
      L.e('FornecedorService.delete: $e');
      return false;
    }
  }
}
