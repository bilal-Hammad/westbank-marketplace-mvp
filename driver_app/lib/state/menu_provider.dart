import 'package:flutter/material.dart';
import '../data/models/menu_model.dart';
import '../data/services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();

  Menu? menu;
  bool loading = false;
  String? error;

  Future<void> loadMenu(String storeId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      menu = await _service.getMenuByStore(storeId);
    } catch (_) {
      error = 'Failed to load menu';
      menu = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    menu = null;
    loading = false;
    error = null;
    notifyListeners();
  }
}
