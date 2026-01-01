import 'package:flutter/material.dart';

import '../data/models/menu_item_model.dart';
import '../data/models/store_model.dart';

class CartLine {
  final MenuItem item;
  int qty;
  final List<OptionItem> selectedOptions;
  String notes;

  CartLine({
    required this.item,
    required this.qty,
    required this.selectedOptions,
    required this.notes,
  });

  int get optionsTotal => selectedOptions.fold(0, (sum, o) => sum + o.priceAdd);
  int get unitTotal => item.basePrice + optionsTotal;
  int get lineTotal => unitTotal * qty;

  List<String> get optionIds => selectedOptions.map((e) => e.id).toList();
  String optionsSummary() {
    if (selectedOptions.isEmpty) return '';
    return selectedOptions.map((e) => e.name).join(', ');
  }
}

class CartProvider extends ChangeNotifier {
  Store? store;
  StoreBranch? branch;

  final List<CartLine> lines = [];

  String notesToStore = '';
  String notesToDriver = '';

  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);
  int get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);

  bool get isEmpty => lines.isEmpty;

  /// Adds an item to cart. Cart is single-store in MVP.
  /// If you add from another store, cart is cleared automatically.
  void addItem({
    required Store newStore,
    required StoreBranch newBranch,
    required MenuItem item,
    required int qty,
    required List<OptionItem> selectedOptions,
    String notes = '',
  }) {
    if (store != null && store!.id != newStore.id) {
      clear();
    }

    store = newStore;
    branch = newBranch;

    // Merge identical items with same options + notes
    final idx = lines.indexWhere((l) {
      final sameItem = l.item.id == item.id;
      final sameNotes = l.notes.trim() == notes.trim();
      final a = l.selectedOptions.map((e) => e.id).toList()..sort();
      final b = selectedOptions.map((e) => e.id).toList()..sort();
      final sameOpts = a.length == b.length && List.generate(a.length, (i) => a[i] == b[i]).every((x) => x);
      return sameItem && sameOpts && sameNotes;
    });

    if (idx >= 0) {
      lines[idx].qty += qty;
    } else {
      lines.add(
        CartLine(
          item: item,
          qty: qty,
          selectedOptions: selectedOptions,
          notes: notes,
        ),
      );
    }

    notifyListeners();
  }

  void updateQty(int index, int newQty) {
    if (index < 0 || index >= lines.length) return;
    lines[index].qty = newQty.clamp(1, 99);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= lines.length) return;
    lines.removeAt(index);
    if (lines.isEmpty) {
      store = null;
      branch = null;
      notesToStore = '';
      notesToDriver = '';
    }
    notifyListeners();
  }

  void setNotes({String? toStore, String? toDriver}) {
    if (toStore != null) notesToStore = toStore;
    if (toDriver != null) notesToDriver = toDriver;
    notifyListeners();
  }

  void clear() {
    store = null;
    branch = null;
    lines.clear();
    notesToStore = '';
    notesToDriver = '';
    notifyListeners();
  }

  List<Map<String, dynamic>> toCreateOrderItemsPayload() {
    return lines
        .map(
          (l) => {
            'itemId': l.item.id,
            'qty': l.qty,
            'optionIds': l.optionIds,
            if (l.notes.trim().isNotEmpty) 'notes': l.notes.trim(),
          },
        )
        .toList();
  }
}
