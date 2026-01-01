import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/store_orders_provider.dart';
import 'order_details_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<StoreOrdersProvider>();
      prov.fetchInbox();
      prov.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<StoreOrdersProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<StoreOrdersProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders Inbox (${orders.orders.length})'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: orders.loading ? null : () => orders.fetchInbox(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
              // Splash will route again.
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => orders.fetchInbox(),
        child: orders.loading && orders.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No pending orders (PENDING_STORE).')),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Tip: Create an order from the customer app, then come back here and pull to refresh.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: orders.orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final o = orders.orders[i];
                      final when = o.createdAt;
                      final ts = when == null
                          ? ''
                          : '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} '
                            '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(o.store.name),
                        subtitle: Text('${o.branch.compact()}\nStatus: ${o.status}${ts.isEmpty ? '' : ' • $ts'}'),
                        isThreeLine: true,
                        trailing: Text(_formatMoney(o.total)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: o)),
                          );
                        },
                      );
                    },
                  ),
      ),
      bottomNavigationBar: orders.error == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  orders.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  String _formatMoney(int amount) {
    // Backend uses *100 for NIS (e.g., 800 = 8.00). We'll show as NIS.
    final nis = (amount / 100.0).toStringAsFixed(2);
    return '$nis ₪';
  }
}
