# ===============================
# Stage 1 - Customer App Installer
# ===============================

$base = "lib"

$folders = @(
    "core/constants",
    "core/theme",
    "core/utils",
    "core/widgets",
    "data/models",
    "data/services",
    "data/repositories",
    "presentation/auth",
    "presentation/address",
    "presentation/home",
    "presentation/store",
    "presentation/product",
    "presentation/cart",
    "presentation/order",
    "presentation/splash",
    "state"
)

Write-Host "Creating folders..."
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path "$base/$folder" | Out-Null
}

function WriteFile($path, $content) {
    $full = "$base/$path"
    Write-Host "Writing $full"
    $content | Out-File -Encoding UTF8 -Force $full
}

# -------------------------------
# main.dart
# -------------------------------
WriteFile "main.dart" @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/address_provider.dart';
import 'state/cart_provider.dart';
import 'state/order_provider.dart';
import 'presentation/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const CustomerApp(),
    ),
  );
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Customer App',
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
"@

# -------------------------------
# Colors
# -------------------------------
WriteFile "core/constants/colors.dart" @"
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF7A00);
  static const green = Color(0xFF1BAA5C);
  static const background = Color(0xFFF7F7F7);
  static const text = Color(0xFF111111);
  static const mutedText = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const white = Colors.white;
}
"@

# -------------------------------
# Strings
# -------------------------------
WriteFile "core/constants/strings.dart" @"
class AppStrings {
  static const appName = 'Marketplace & Delivery';
}
"@

# -------------------------------
# Endpoints
# -------------------------------
WriteFile "core/constants/endpoints.dart" @"
class Endpoints {
  static const baseUrl = 'http://10.0.2.2:3000';

  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';

  static const addresses = '/customer/addresses';
  static const stores = '/stores';
  static const products = '/stores/{storeId}/products';

  static const createOrder = '/orders';
  static const orderDetails = '/orders/{orderId}';
}
"@

# -------------------------------
# Theme
# -------------------------------
WriteFile "core/theme/app_theme.dart" @"
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
"@

# -------------------------------
# Splash Screen
# -------------------------------
WriteFile "presentation/splash/splash_screen.dart" @"
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.shopping_bag, size: 48, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Stage 1 – Customer App',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
"@

# -------------------------------
# Providers
# -------------------------------
WriteFile "state/auth_provider.dart" @"
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
}
"@

WriteFile "state/address_provider.dart" @"
import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  String? addressId;
}
"@

WriteFile "state/cart_provider.dart" @"
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  int items = 0;
}
"@

WriteFile "state/order_provider.dart" @"
import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  String? activeOrderId;
}
"@

Write-Host ""
Write-Host "✅ lib folder created successfully!"
Write-Host "👉 Now run: flutter pub get && flutter run"
