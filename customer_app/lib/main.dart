import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/address_provider.dart';
import 'state/cart_provider.dart';
import 'state/order_provider.dart';
import 'state/store_provider.dart';
import 'state/menu_provider.dart';
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
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
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