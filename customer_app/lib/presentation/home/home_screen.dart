import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/auth_provider.dart';
import '../../state/address_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';
import '../auth/login_screen.dart';
import '../orders/order_tracking_screen.dart';
import '../stores/stores_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (orderProvider.activeOrderId != null)
            IconButton(
              tooltip: 'Track last order',
              icon: const Icon(Icons.receipt_long),
              onPressed: () {
                final id = orderProvider.activeOrderId;
                if (id == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: id)),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();

              final address = context.read<AddressProvider>();
              address.reset();
              context.read<CartProvider>().clear();
              await context.read<OrderProvider>().clearLastOrder();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: _HomeBody()),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('HOME', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoresScreen()),
                );
              },
              icon: const Icon(Icons.storefront),
              label: const Text('Browse Stores'),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<OrderProvider>(
            builder: (context, orders, _) {
              final id = orders.activeOrderId;
              if (id == null) return const SizedBox.shrink();
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: id)),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Track Last Order'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
