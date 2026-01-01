import 'package:flutter/material.dart';
import '../data/models/store_model.dart';
import '../data/services/store_service.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _service = StoreService();

  List<Store> stores = [];
  bool loading = false;
  String? error;

  Future<void> loadStores() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      stores = await _service.getStores();
    } catch (e) {
      error = 'Failed to load stores';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
