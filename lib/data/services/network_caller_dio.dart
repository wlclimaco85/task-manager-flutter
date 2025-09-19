// network_caller.dart
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/data/models/network_response_dio.dart';

class NetworkCaller {
  final Dio _dio = Dio();

  Future<NetworkResponseDio> multipartRequestWithDio(
    String url,
    String filePath, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        ...data ?? {},
      });

      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
      );

      return NetworkResponseDio(
        statusCode: response.statusCode,
        body: response.data,
      );
    } on DioException catch (e) {
      return NetworkResponseDio(
        statusCode: e.response?.statusCode,
        errorMessage: e.message,
      );
    }
  }
}
