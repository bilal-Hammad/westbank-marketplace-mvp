import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/address_provider.dart';
import '../../state/order_provider.dart';
import '../auth/login_screen.dart';
import '../address/address_screen.dart';
import '../home/home_screen.dart';

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
    final address = context.read<AddressProvider>();
    final orders = context.read<OrderProvider>();

    await auth.loadSession();
    if (auth.isLoggedIn) {
      await address.loadAddresses();
      if (address.error == 'Unauthorized') {
        // Token is invalid, clear it
        await auth.logout();
      } else {
        await orders.loadLastOrderId();
      }
    }

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Widget next;

    if (!auth.isLoggedIn) {
      next = LoginScreen();
    } else if (!address.hasDefaultAddress) {
      next = AddressScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
