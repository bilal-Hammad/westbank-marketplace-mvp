import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/endpoints.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;
  bool isLoggedIn = false;
  String phone = '';
  String? error;
  Map<String, dynamic>? me;

  /// Load session on app start and validate role.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      isLoggedIn = false;
      me = null;
      notifyListeners();
      return;
    }

    try {
      final data = await _fetchMe();
      me = data;
      final role = (data['role'] ?? '').toString();
      if (role != 'STORE_OWNER') {
        await logout(reason: 'هذا الحساب ليس حساب متجر (STORE_OWNER)');
        return;
      }
      isLoggedIn = true;
    } catch (_) {
      // Token invalid or server down.
      isLoggedIn = false;
      me = null;
    }

    notifyListeners();
  }

  /// Request OTP.
  Future<void> requestOtp(String inputPhone) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      phone = inputPhone.trim();
      await _service.requestOtp(phone);
    } catch (_) {
      error = 'فشل إرسال رمز التحقق';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Verify OTP, store JWT, then validate role = STORE_OWNER.
  Future<bool> verifyOtp(String otp) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _service.verifyOtp(phone, otp.trim());
      await _saveToken(token);

      final data = await _fetchMe();
      me = data;
      final role = (data['role'] ?? '').toString();
      if (role != 'STORE_OWNER') {
        await logout(reason: 'هذا الحساب ليس حساب متجر (STORE_OWNER)');
        error = 'الحساب غير مصرح لتطبيق المتجر';
        return false;
      }

      isLoggedIn = true;
      return true;
    } catch (_) {
      error = 'رمز OTP غير صحيح أو منتهي';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    final dio = ApiService().dio;
    final res = await dio.get(Endpoints.me);
    final out = (res.data['me'] as Map).cast<String, dynamic>();
    return out;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> logout({String? reason}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    isLoggedIn = false;
    me = null;
    if (reason != null && reason.isNotEmpty) {
      error = reason;
    }
    notifyListeners();
  }
}
