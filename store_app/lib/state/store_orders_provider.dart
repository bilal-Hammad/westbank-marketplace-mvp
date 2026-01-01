import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/order_model.dart';
import '../data/services/store_orders_service.dart';

class StoreOrdersProvider extends ChangeNotifier {
  final StoreOrdersService _service = StoreOrdersService();

  List<Order> orders = const [];
  bool loading = false;
  String? error;

  Timer? _timer;

  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Avoid spamming if screen isn't active; caller can stop it.
      fetchInbox(silent: true);
    });
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchInbox({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }

    try {
      final items = await _service.fetchInbox();
      orders = items;
      error = null;
    } catch (_) {
      error ??= 'فشل تحميل الطلبات';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder({required String orderId, required int prepMinutes}) async {
    try {
      await _service.acceptOrder(orderId: orderId, prepMinutes: prepMinutes);
      await fetchInbox(silent: true);
      return true;
    } catch (_) {
      error = 'فشل قبول الطلب';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrder({required String orderId}) async {
    try {
      await _service.rejectOrder(orderId: orderId);
      await fetchInbox(silent: true);
      return true;
    } catch (_) {
      error = 'فشل رفض الطلب';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markReady({required String orderId}) async {
    try {
      await _service.markReady(orderId: orderId);
      await fetchInbox(silent: true);
      return true;
    } catch (_) {
      error = 'فشل تحديث الحالة (جاهز)';
      notifyListeners();
      return false;
    }
  }

  Future<bool> simulateTaxiAcceptDefaultOffice() async {
    try {
      await _service.simulateTaxiReply(from: '970599111111', text: '1');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
