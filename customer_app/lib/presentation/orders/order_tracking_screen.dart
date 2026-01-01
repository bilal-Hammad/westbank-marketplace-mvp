import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrder(widget.orderId);
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        context.read<OrderProvider>().fetchOrder(widget.orderId);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING_STORE':
        return 'Waiting for store';
      case 'DELIVERY_CONFIRMING':
        return 'Confirming delivery';
      case 'PREPARING':
        return 'Preparing';
      case 'ON_THE_WAY':
        return 'On the way';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            onPressed: () => provider.fetchOrder(widget.orderId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: provider.loading && provider.activeOrder == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.activeOrder == null
              ? Center(child: Text(provider.error!))
              : _OrderView(orderId: widget.orderId),
    );
  }
}

class _OrderView extends StatelessWidget {
  final String orderId;

  const _OrderView({required this.orderId});

  String _money(int v) => v.toString();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.activeOrder;

    if (order == null) {
      return const Center(child: Text('No order'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchOrder(orderId),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${order.status}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(_statusHuman(order.status)),
                  const SizedBox(height: 8),
                  Text('Store: ${order.store.name}'),
                  Text('Branch: ${order.branch.compact()}'),
                  const SizedBox(height: 8),
                  Text('Order ID: ${order.id}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...order.items.map(
            (it) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(it.nameSnap, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('x${it.qty}'),
                      ],
                    ),
                    if (it.options.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Options: ${it.options.map((o) => o.nameSnap).join(', ')}',
                        ),
                      ),
                    if (it.notes.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Notes: ${it.notes}'),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Unit: ${_money(it.unitPrice)}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subtotal: ${_money(order.subtotal)}'),
                  Text('Delivery fee: ${_money(order.deliveryFee)}'),
                  const Divider(),
                  Text('Total: ${_money(order.total)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Auto refresh every 10 seconds',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _statusHuman(String status) {
    switch (status) {
      case 'PENDING_STORE':
        return 'We sent your order to the store. Waiting for acceptance.';
      case 'DELIVERY_CONFIRMING':
        return 'Store accepted. Looking for a driver/taxi office.';
      case 'PREPARING':
        return 'Delivery confirmed. Store started preparing your order.';
      case 'ON_THE_WAY':
        return 'Driver picked up your order and is heading to you.';
      case 'DELIVERED':
        return 'Delivered. Enjoy!';
      case 'CANCELLED':
        return 'Cancelled.';
      default:
        return status;
    }
  }
}
