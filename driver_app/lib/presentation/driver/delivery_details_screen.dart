import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/delivery_model.dart';
import '../../state/driver_provider.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final Delivery delivery;
  final bool isRequest;

  const DeliveryDetailsScreen({super.key, required this.delivery, this.isRequest = false});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverProvider>();
    final d = delivery;
    final o = d.order;

    final scheduled = d.scheduledMoveAt;
    final now = DateTime.now();
    final waitSeconds = scheduled == null ? 0 : scheduled.difference(now).inSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(o.store.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Pickup: ${o.branch.compact()}'),
          const SizedBox(height: 6),
          Text('Drop-off: ${o.address.compactLabel()}'),
          if (o.address.details.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Address details: ${o.address.details}'),
          ],
          const SizedBox(height: 12),
          _InfoRow('Order status', o.status),
          _InfoRow('Delivery status', d.status),
          if (scheduled != null) _InfoRow('Suggested move time', scheduled.toLocal().toString()),
          if (waitSeconds > 15) ...[
            const SizedBox(height: 6),
            Text(
              'Smart dispatch: please wait ~${(waitSeconds / 60).ceil()} min so you arrive near pickup time.',
              style: const TextStyle(color: Colors.black87),
            ),
          ],
          const SizedBox(height: 16),
          if ((o.notesToDriver).trim().isNotEmpty) ...[
            const Text('Notes to driver', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(o.notesToDriver),
            const SizedBox(height: 16),
          ],
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...o.items.map((it) => _ItemTile(it)),
          const SizedBox(height: 24),
          if (isRequest) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await p.reject(d.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: p.loading
                        ? null
                        : () async {
                            final accepted = await p.accept(d.id);
                            if (context.mounted && accepted != null) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: accepted)),
                              );
                            }
                          },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (o.status == 'READY')
              ElevatedButton(
                onPressed: p.loading ? null : () => p.markPickedUp(d.id),
                child: const Text('Picked up (start delivery)'),
              )
            else
              ElevatedButton(
                onPressed: null,
                child: const Text('Waiting for store to mark READY'),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (p.loading || d.status != 'ON_THE_WAY') ? null : () => p.markDelivered(d.id),
              child: const Text('Mark delivered'),
            ),
          ]
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OrderItem item;
  const _ItemTile(this.item);

  @override
  Widget build(BuildContext context) {
    final opts = item.options.map((o) => o.nameSnap).where((s) => s.trim().isNotEmpty).toList();
    final subtitle = [
      if (opts.isNotEmpty) opts.join(', '),
      if (item.notes.trim().isNotEmpty) 'Notes: ${item.notes}',
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text('${item.qty} × ${item.nameSnap}'),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
      ),
    );
  }
}
