import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/order_model.dart';
import '../data/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  String? activeOrderId;
  Order? activeOrder;

  bool loading = false;
  String? error;

  Future<void> loadLastOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    activeOrderId = prefs.getString('last_order_id');
    notifyListeners();
  }

  Future<Order?> createOrder({
    required String storeId,
    required String branchId,
    required List<Map<String, dynamic>> items,
    String? notesToStore,
    String? notesToDriver,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      activeOrder = await _service.createOrder(
        storeId: storeId,
        branchId: branchId,
        items: items,
        notesToStore: notesToStore,
        notesToDriver: notesToDriver,
      );
      activeOrderId = activeOrder!.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_order_id', activeOrderId!);

      return activeOrder;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('error')) {
          error = data['error'];
        } else {
          error = 'Server error: ${e.response!.statusCode}';
        }
      } else {
        error = 'Failed to place order: ${e.toString()}';
      }
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Order?> fetchOrder(String orderId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      activeOrder = await _service.getOrder(orderId);
      activeOrderId = activeOrder!.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_order_id', activeOrderId!);

      return activeOrder;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('error')) {
          error = data['error'];
        } else {
          error = 'Server error: ${e.response!.statusCode}';
        }
      } else {
        error = 'Failed to load order: ${e.toString()}';
      }
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> clearLastOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_order_id');
    activeOrderId = null;
    activeOrder = null;
    notifyListeners();
  }

  void reset() {
    activeOrderId = null;
    activeOrder = null;
    loading = false;
    error = null;
    notifyListeners();
  }
}
