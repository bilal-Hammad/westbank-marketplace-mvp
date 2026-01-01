import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';
import '../orders/order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _notesToStoreC = TextEditingController();
  final _notesToDriverC = TextEditingController();

  @override
  void dispose() {
    _notesToStoreC.dispose();
    _notesToDriverC.dispose();
    super.dispose();
  }

  String _money(int v) {
    // Backend uses *100 style (e.g., 800 = 8₪). You can format later.
    return v.toString();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();

    if (cart.store == null || cart.branch == null || cart.lines.isEmpty) return;

    cart.setNotes(
      toStore: _notesToStoreC.text,
      toDriver: _notesToDriverC.text,
    );

    final order = await orders.createOrder(
      storeId: cart.store!.id,
      branchId: cart.branch!.id,
      items: cart.toCreateOrderItemsPayload(),
      notesToStore: cart.notesToStore.trim().isEmpty ? null : cart.notesToStore.trim(),
      notesToDriver: cart.notesToDriver.trim().isEmpty ? null : cart.notesToDriver.trim(),
    );

    if (!mounted) return;

    if (order != null) {
      cart.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.id),
        ),
      );
    } else {
      final msg = orders.error ?? 'Failed to place order';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    _notesToStoreC.text = cart.notesToStore;
    _notesToDriverC.text = cart.notesToDriver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(
            onPressed: cart.clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear cart',
          ),
        ],
      ),
      body: Column(
        children: [
          if (cart.store != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.storefront),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cart.store!.name} • ${cart.branch?.compact() ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final line = cart.lines[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                line.item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              onPressed: () => cart.removeAt(i),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (line.optionsSummary().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Options: ${line.optionsSummary()}'),
                          ),
                        if (line.notes.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Notes: ${line.notes}'),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text('Unit: ${_money(line.unitTotal)}'),
                              const Spacer(),
                              IconButton(
                                onPressed: () => cart.updateQty(i, line.qty - 1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${line.qty}'),
                              IconButton(
                                onPressed: () => cart.updateQty(i, line.qty + 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const SizedBox(width: 8),
                              Text('Total: ${_money(line.lineTotal)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(controller: _notesToStoreC, hint: 'Notes to store (optional)'),
                const SizedBox(height: 8),
                AppTextField(controller: _notesToDriverC, hint: 'Notes to driver (optional)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Subtotal: ${_money(cart.subtotal)}')),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Delivery fee: 800')),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Estimated total: ${_money(cart.subtotal + 800)}')),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: orders.loading ? 'Placing Order...' : 'Place Order',
                  onPressed: orders.loading ? null : _placeOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
