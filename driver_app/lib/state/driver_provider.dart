import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/delivery_model.dart';
import '../data/services/driver_service.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();

  bool bootstrapping = false;
  bool loading = false;
  bool isDriver = true;
  String? error;

  bool isOnline = false;
  List<Delivery> available = [];
  List<Delivery> active = [];

  Timer? _pollTimer;

  Future<void> bootstrap() async {
    bootstrapping = true;
    error = null;
    notifyListeners();

    try {
      final me = await _service.getMe();
      final role = (me['role'] ?? '').toString();
      isDriver = role == 'DRIVER';
      final st = await _service.getStatus();
      isOnline = st['isOnline'] == true;
      await refreshAll();
      if (isOnline) _startPolling();
    } catch (e) {
      error = 'Failed to load driver profile';
    } finally {
      bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> setOnline(bool value) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (value) {
        final st = await _service.goOnline();
        isOnline = st['isOnline'] == true;
        _startPolling();
      } else {
        final st = await _service.goOffline();
        isOnline = st['isOnline'] == true;
        _stopPolling();
      }
      await refreshAll();
    } catch (e) {
      error = 'Failed to update status';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshAvailable(),
      refreshActive(),
    ]);
  }

  Future<void> refreshAvailable() async {
    try {
      final list = await _service.fetchAvailableDeliveries();
      available = list.map(Delivery.fromJson).toList();
    } catch (_) {
      // keep old list
    }
    notifyListeners();
  }

  Future<void> refreshActive() async {
    try {
      final list = await _service.fetchActiveDeliveries();
      active = list.map(Delivery.fromJson).toList();
    } catch (_) {
      // keep old list
    }
    notifyListeners();
  }

  Future<Delivery?> accept(String deliveryId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final json = await _service.acceptDelivery(deliveryId);
      final d = Delivery.fromJson(json);
      await refreshAll();
      return d;
    } catch (e) {
      error = 'Could not accept delivery';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> reject(String deliveryId) async {
    try {
      await _service.rejectDelivery(deliveryId);
      // Remove locally (MVP)
      available = available.where((d) => d.id != deliveryId).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markPickedUp(String deliveryId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.markPickedUp(deliveryId);
      await refreshAll();
    } catch (e) {
      error = 'Pickup failed';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markDelivered(String deliveryId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.markDelivered(deliveryId);
      await refreshAll();
    } catch (e) {
      error = 'Delivering failed';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await refreshAll();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void reset() {
    bootstrapping = false;
    loading = false;
    isDriver = true;
    error = null;
    isOnline = false;
    available = [];
    active = [];
    _stopPolling();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
