import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;
  bool isLoggedIn = false;
  String phone = '';
  String? error;

  // Load session on app start
 Future<void> loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  isLoggedIn = prefs.containsKey('token');  
  notifyListeners();
}


  // Request OTP
  Future<void> requestOtp(String inputPhone) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      phone = inputPhone.trim(); // 🔒 تثبيت الرقم
      await _service.requestOtp(phone);
    } catch (e) {
      error = 'Failed to send OTP';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Verify OTP
Future<void> verifyOtp(String otp) async {
  loading = true;
  error = null;
  notifyListeners();

  try {
    final token = await _service.verifyOtp(phone, otp.trim());

    await _saveToken(token);

    isLoggedIn = true;           
    notifyListeners();         
  } catch (e) {
    error = 'OTP verification failed';
  } finally {
    loading = false;
    notifyListeners();
  }
}


  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
}
