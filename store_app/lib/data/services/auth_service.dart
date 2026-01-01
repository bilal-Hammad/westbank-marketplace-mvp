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

  Future<String> verifyOtp(String phone, String otp) async {
    final res = await _dio.post(
      Endpoints.verifyOtp,
      data: {'phone': phone, 'code': otp},
    );

    return res.data['token'];
  }
}
