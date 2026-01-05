import 'package:dio/dio.dart';
import '../../core/constants/endpoints.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;

  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post(
        Endpoints.requestOtp,
        data: {'phone': phone},
      );
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout. Please check your internet connection.');
        } else if (e.response?.statusCode == 400) {
          throw Exception('Invalid phone number format.');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
        throw Exception('Failed to send OTP: ${e.toString()}');
      }
    }
  }

  Future<String> verifyOtp(String phone, String otp, {String? name}) async {
    try {
      final data = {'phone': phone, 'code': otp};
      if (name != null && name.isNotEmpty) {
        data['name'] = name;
      }
      final res = await _dio.post(
        Endpoints.verifyOtp,
        data: data,
      );

      return res.data['token'];
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout. Please check your internet connection.');
        } else if (e.response?.statusCode == 400) {
          throw Exception('Invalid OTP or phone number.');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } else {
        throw Exception('Failed to verify OTP: ${e.toString()}');
      }
    }
  }
}
