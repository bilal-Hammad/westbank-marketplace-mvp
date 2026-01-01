import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_model.dart';
import '../../state/store_orders_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  int prepMinutes = 30;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    prepMinutes = widget.order.prepMinutes ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StoreOrdersProvider>();
    final o = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Summary'),
          _kv('Store', o.store.name),
          _kv('Branch', o.branch.compact()),
          _kv('Status', o.status),
          if (o.createdAt != null) _kv('Created', o.createdAt!.toLocal().toString()),
          const SizedBox(height: 12),

          _sectionTitle('Notes'),
          _kv('To Store', o.notesToStore.isEmpty ? '-' : o.notesToStore),
          _kv('To Driver', o.notesToDriver.isEmpty ? '-' : o.notesToDriver),
          const SizedBox(height: 12),

          _sectionTitle('Items'),
          ...o.items.map(_itemTile),
          const SizedBox(height: 12),

          _sectionTitle('Totals'),
          _kv('Subtotal', _money(o.subtotal)),
          _kv('Delivery', _money(o.deliveryFee)),
          _kv('Total', _money(o.total)),
          const SizedBox(height: 20),

          _sectionTitle('Actions'),
          const SizedBox(height: 8),
          _prepPicker(),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : () => _accept(context, prov, o),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _reject(context, prov, o),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => _ready(context, prov, o),
              icon: const Icon(Icons.restaurant),
              label: const Text('Mark READY'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await prov.simulateTaxiAcceptDefaultOffice();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Sent taxi ACCEPT (mock)' : 'Failed to send taxi reply')),
                      );
                    },
              icon: const Icon(Icons.send),
              label: const Text('DEV: simulate taxi accept (office 970599111111)'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Important (MVP): When you accept, the backend waits for a taxi office reply (up to 60s each).\n'
            'Use the DEV button above or call POST /taxi/whatsapp-reply with {from:"970599111111", text:"1"} to unblock.',
            style: TextStyle(fontSize: 12),
          ),

          if (prov.error != null) ...[
            const SizedBox(height: 12),
            Text(prov.error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _itemTile(OrderItem it) {
    final opts = it.options.map((o) => '${o.nameSnap} (+${_money(o.priceAdd)})').toList();
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
                    '${it.qty}× ${it.nameSnap}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_money(it.lineTotal())),
              ],
            ),
            if (opts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Options: ${opts.join(', ')}', style: const TextStyle(fontSize: 12)),
            ],
            if (it.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${it.notes}', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _prepPicker() {
    final quick = [15, 20, 30, 45, 60];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prep time: $prepMinutes min', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: quick
              .map(
                (m) => ChoiceChip(
                  label: Text('$m'),
                  selected: prepMinutes == m,
                  onSelected: (_) => setState(() => prepMinutes = m),
                ),
              )
              .toList(),
        ),
        Slider(
          value: prepMinutes.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          label: '$prepMinutes',
          onChanged: (v) => setState(() => prepMinutes = v.round()),
        ),
      ],
    );
  }

  Future<void> _accept(BuildContext context, StoreOrdersProvider prov, Order o) async {
    setState(() => busy = true);
    final ok = await prov.acceptOrder(orderId: o.id, prepMinutes: prepMinutes);
    if (!context.mounted) return;
    setState(() => busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Accepted. Waiting for taxi confirmation…' : 'Accept failed')),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _reject(BuildContext context, StoreOrdersProvider prov, Order o) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject order?'),
        content: const Text('This will cancel the order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => busy = true);
    final ok = await prov.rejectOrder(orderId: o.id);
    if (!context.mounted) return;
    setState(() => busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Rejected' : 'Reject failed')),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _ready(BuildContext context, StoreOrdersProvider prov, Order o) async {
    setState(() => busy = true);
    final ok = await prov.markReady(orderId: o.id);
    if (!context.mounted) return;
    setState(() => busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Marked READY' : 'Update failed')),
    );
    if (ok) Navigator.pop(context);
  }

  String _money(int amount) {
    final nis = (amount / 100.0).toStringAsFixed(2);
    return '$nis ₪';
  }
}
