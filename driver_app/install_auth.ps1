# ===============================
# Stage 1 - Auth Installer (OTP)
# ===============================

$base = "lib"

function WriteFile($path, $content) {
    $full = "$base/$path"
    Write-Host "Writing $full"
    $content | Out-File -Encoding UTF8 -Force $full
}

# -------------------------------
# Auth Service
# -------------------------------
WriteFile "data/services/auth_service.dart" @"
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
      data: {'phone': phone, 'otp': otp},
    );

    return res.data['token'];
  }
}
"@

# -------------------------------
# Auth Provider
# -------------------------------
WriteFile "state/auth_provider.dart" @"
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;
  bool isLoggedIn = false;
  String phone = '';

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.containsKey('token');
    notifyListeners();
  }

  Future<void> requestOtp(String phoneNumber) async {
    loading = true;
    notifyListeners();

    phone = phoneNumber;
    await _service.requestOtp(phoneNumber);

    loading = false;
    notifyListeners();
  }

  Future<void> verifyOtp(String otp) async {
    loading = true;
    notifyListeners();

    final token = await _service.verifyOtp(phone, otp);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    isLoggedIn = true;
    loading = false;
    notifyListeners();
  }
}
"@

# -------------------------------
# Login Screen
# -------------------------------
WriteFile "presentation/auth/login_screen.dart" @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              controller: controller,
              hint: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Send OTP',
              loading: auth.loading,
              onPressed: () async {
                await auth.requestOtp(controller.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OtpScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
"@

# -------------------------------
# OTP Screen
# -------------------------------
WriteFile "presentation/auth/otp_screen.dart" @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';

class OtpScreen extends StatelessWidget {
  OtpScreen({super.key});

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              controller: controller,
              hint: 'OTP Code',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Verify',
              loading: auth.loading,
              onPressed: () async {
                await auth.verifyOtp(controller.text);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
"@

Write-Host ""
Write-Host "✅ Auth (Login + OTP) installed successfully!"
