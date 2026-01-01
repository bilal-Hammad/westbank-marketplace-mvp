import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/menu_item_model.dart';
import '../../data/models/store_model.dart';
import '../../presentation/cart/cart_screen.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Store store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  StoreBranch? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.store.branches.isNotEmpty ? widget.store.branches.first : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenu(widget.store.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.shopping_cart_outlined),
                ),
                if (cart.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: menuProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : menuProvider.error != null
              ? Center(child: Text(menuProvider.error!))
              : menuProvider.menu == null
                  ? const Center(child: Text('No menu found'))
                  : Column(
                      children: [
                        if (widget.store.branches.length > 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<StoreBranch>(
                                    isExpanded: true,
                                    value: _selectedBranch,
                                    items: widget.store.branches
                                        .map(
                                          (b) => DropdownMenuItem(
                                            value: b,
                                            child: Text(b.compact()),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() => _selectedBranch = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: menuProvider.menu!.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final item = menuProvider.menu!.items[i];
                              return Card(
                                child: ListTile(
                                  onTap: () async {
                                    final branch = _selectedBranch ?? (widget.store.branches.isNotEmpty ? widget.store.branches.first : null);
                                    if (branch == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No open branch available')),
                                      );
                                      return;
                                    }

                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => _AddToCartSheet(
                                        store: widget.store,
                                        branch: branch,
                                        item: item,
                                      ),
                                    );
                                  },
                                  title: Text(item.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.description.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(item.description),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('Price: ${item.basePrice}'),
                                      ),
                                      if (item.optionGroups.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text('Options: ${item.optionGroups.length} group(s)'),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.add_circle_outline),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _AddToCartSheet extends StatefulWidget {
  final Store store;
  final StoreBranch branch;
  final MenuItem item;

  const _AddToCartSheet({
    required this.store,
    required this.branch,
    required this.item,
  });

  @override
  State<_AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<_AddToCartSheet> {
  int qty = 1;
  final notesC = TextEditingController();

  /// groupId -> selected optionIds
  final Map<String, Set<String>> selections = {};

  @override
  void initState() {
    super.initState();
    for (final g in widget.item.optionGroups) {
      selections[g.id] = <String>{};
    }
  }

  @override
  void dispose() {
    notesC.dispose();
    super.dispose();
  }

  bool get _valid {
    for (final g in widget.item.optionGroups) {
      final sel = selections[g.id] ?? <String>{};
      if (sel.length < g.minSelect) return false;
      if (sel.length > g.maxSelect) return false;
    }
    return true;
  }

  int _optionsTotal() {
    int sum = 0;
    for (final g in widget.item.optionGroups) {
      final sel = selections[g.id] ?? <String>{};
      for (final o in g.options) {
        if (sel.contains(o.id)) sum += o.priceAdd;
      }
    }
    return sum;
  }

  List<OptionItem> _selectedOptionObjects() {
    final out = <OptionItem>[];
    for (final g in widget.item.optionGroups) {
      final sel = selections[g.id] ?? <String>{};
      for (final o in g.options) {
        if (sel.contains(o.id)) out.add(o);
      }
    }
    return out;
  }

  void _toggleOption(OptionGroup group, OptionItem opt) {
    final sel = selections[group.id] ?? <String>{};

    // Radio-like behavior
    if (group.maxSelect == 1) {
      sel
        ..clear()
        ..add(opt.id);
      selections[group.id] = sel;
      setState(() {});
      return;
    }

    // Checkbox behavior
    if (sel.contains(opt.id)) {
      sel.remove(opt.id);
    } else {
      if (sel.length >= group.maxSelect) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max ${group.maxSelect} options for ${group.name}')),
        );
        return;
      }
      sel.add(opt.id);
    }

    selections[group.id] = sel;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final optionsTotal = _optionsTotal();
    final unit = widget.item.basePrice + optionsTotal;
    final total = unit * qty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (widget.item.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(widget.item.description),
              ),
            const SizedBox(height: 10),
            ...widget.item.optionGroups.map((g) {
              final sel = selections[g.id] ?? <String>{};
              final must = g.minSelect > 0;
              final header = '${g.name}${must ? ' (required)' : ''}  •  ${g.minSelect}-${g.maxSelect}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(header, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...g.options.map((o) {
                      final checked = sel.contains(o.id);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: groupLeading(g, checked),
                        title: Text(o.name),
                        subtitle: o.priceAdd != 0 ? Text('+${o.priceAdd}') : null,
                        onTap: () => _toggleOption(g, o),
                      );
                    }),
                  ],
                ),
              );
            }),
            TextField(
              controller: notesC,
              decoration: const InputDecoration(hintText: 'Item notes (optional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => qty = (qty - 1).clamp(1, 99)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => setState(() => qty = (qty + 1).clamp(1, 99)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text('Unit: $unit'),
                const SizedBox(width: 12),
                Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_valid
                    ? null
                    : () {
                        cart.addItem(
                          newStore: widget.store,
                          newBranch: widget.branch,
                          item: widget.item,
                          qty: qty,
                          selectedOptions: _selectedOptionObjects(),
                          notes: notesC.text.trim(),
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(_valid ? 'Add to cart' : 'Please select required options'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget groupLeading(OptionGroup g, bool checked) {
    if (g.maxSelect == 1) {
      return Icon(checked ? Icons.radio_button_checked : Icons.radio_button_off);
    }
    return Icon(checked ? Icons.check_box : Icons.check_box_outline_blank);
  }
}
