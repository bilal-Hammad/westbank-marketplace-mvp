import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../data/models/address_model.dart';
import '../data/services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _service = AddressService();

  List<Address> addresses = [];
  bool loading = false;
  String? error;

  Address? get defaultAddress {
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return null;
  }

  bool get hasDefaultAddress => defaultAddress != null;

  Future<void> loadAddresses() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      addresses = await _service.getAddresses();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        error = 'Unauthorized';
      } else {
        error = 'Failed to load addresses';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createAddress({
    required double lat,
    required double lng,
    String? label,
    String? city,
    String? area,
    String? details,
    bool isDefault = true,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.createAddress(
        lat: lat,
        lng: lng,
        label: label,
        city: city,
        area: area,
        details: details,
        isDefault: isDefault,
      );
      addresses = await _service.getAddresses();
    } catch (_) {
      error = 'Failed to save address';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setDefault(String addressId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.setDefault(addressId);
      addresses = await _service.getAddresses();
    } catch (_) {
      error = 'Failed to set default address';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.deleteAddress(addressId);
      addresses = await _service.getAddresses();
    } catch (_) {
      error = 'Failed to delete address';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reset() {
    addresses = [];
    loading = false;
    error = null;
    notifyListeners();
  }
}
