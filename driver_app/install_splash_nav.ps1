# ===============================
# Stage 1 - Splash Navigation
# ===============================

$base = "lib"

function WriteFile($path, $content) {
    $full = "$base/$path"
    Write-Host "Writing $full"
    $content | Out-File -Encoding UTF8 -Force $full
}

# -------------------------------
# Update Splash Screen
# -------------------------------
WriteFile "presentation/splash/splash_screen.dart" @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.loadSession();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn
            ? const Scaffold(
                body: Center(child: Text('HOME (Stage 1)')),
              )
            : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
"@

Write-Host ""
Write-Host "✅ Splash navigation installed successfully!"
