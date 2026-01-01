import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/address_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';
import '../../state/driver_provider.dart';
import '../../data/models/delivery_model.dart';
import '../auth/login_screen.dart';
import 'delivery_details_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverProvider>();

    if (p.bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!p.isDriver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This account is not a DRIVER.\n\nAsk admin to set your role to DRIVER, then login again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver'),
        actions: [
          IconButton(
            onPressed: p.loading ? null : () => p.refreshAll(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              context.read<AddressProvider>().reset();
              context.read<CartProvider>().clear();
              await context.read<OrderProvider>().clearLastOrder();
              context.read<DriverProvider>().reset();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OnlineCard(
              isOnline: p.isOnline,
              loading: p.loading,
              onChanged: (v) => p.setOnline(v),
            ),
            if (p.error != null) ...[
              const SizedBox(height: 12),
              Text(p.error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            _SectionTitle('Active delivery'),
            const SizedBox(height: 8),
            if (p.active.isEmpty)
              const Text('No active delivery right now.')
            else
              ...p.active.map((d) => _DeliveryTile(
                    delivery: d,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: d)),
                      );
                    },
                  )),
            const SizedBox(height: 20),
            _SectionTitle('New requests'),
            const SizedBox(height: 8),
            if (!p.isOnline)
              const Text('Go online to receive new requests.')
            else if (p.available.isEmpty)
              const Text('No requests yet. Keep the app open.')
            else
              ...p.available.map((d) => _RequestCard(
                    delivery: d,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: d, isRequest: true)),
                      );
                    },
                    onAccept: p.loading ? null : () async {
                      final accepted = await p.accept(d.id);
                      if (!mounted) return;
                      if (accepted != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: accepted)),
                        );
                      }
                    },
                    onReject: () => p.reject(d.id),
                  )),
          ],
        ),
      ),
    );
  }
}

class _OnlineCard extends StatelessWidget {
  final bool isOnline;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _OnlineCard({
    required this.isOnline,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOnline ? 'New delivery requests will appear here.' : 'Go online to start receiving requests.',
                  ),
                ],
              ),
            ),
            Switch(
              value: isOnline,
              onChanged: loading ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _DeliveryTile extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;
  const _DeliveryTile({required this.delivery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(delivery.order.store.name),
        subtitle: Text('${delivery.order.branch.compact()}\nStatus: ${delivery.order.status}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onView;
  final VoidCallback? onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.delivery,
    required this.onView,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delivery.order.store.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(delivery.order.branch.compact()),
            const SizedBox(height: 6),
            Text('Drop-off: ${delivery.order.address.compactLabel()}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    child: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
