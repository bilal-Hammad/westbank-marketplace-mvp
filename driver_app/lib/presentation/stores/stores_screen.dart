import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/store_provider.dart';
import 'store_details_screen.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.separated(
                  itemCount: provider.stores.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final store = provider.stores[i];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreDetailsScreen(store: store),
                          ),
                        );
                      },
                      title: Text(store.name),
                      subtitle: Text(
                        [store.type, store.fulfillmentType]
                            .where((e) => e.trim().isNotEmpty)
                            .join(' • '),
                      ),
                      trailing: Icon(
                        store.isOpen ? Icons.check_circle : Icons.cancel,
                        color: store.isOpen ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
    );
  }
}