import 'package:dio/dio.dart';
import '../../core/constants/endpoints.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;

  Future<void> requestOtp(String phone) async {
    await _dio.post(
      Endpoints.requestOtp,
      data: {'phone': phone},
    );
  }

  Future<String> verifyOtp(String phone, String otp, {String? name}) async {
    final data = {'phone': phone, 'code': otp};
    if (name != null && name.isNotEmpty) {
      data['name'] = name;
    }
    final res = await _dio.post(
      Endpoints.verifyOtp,
      data: data,
    );

    return res.data['token'];
  }
}
