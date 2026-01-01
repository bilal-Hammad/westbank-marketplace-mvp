import 'package:dio/dio.dart';

import '../../core/constants/endpoints.dart';
import '../models/address_model.dart';
import 'api_service.dart';

class AddressService {
  final Dio _dio = ApiService().dio;

  Future<List<Address>> getAddresses() async {
    final res = await _dio.get(Endpoints.addresses);
    final data = res.data;
    final List itemsJson = (data is Map && data['items'] is List)
        ? (data['items'] as List)
        : const [];
    return itemsJson
        .map((e) => Address.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Address> createAddress({
    required double lat,
    required double lng,
    String? label,
    String? city,
    String? area,
    String? details,
    bool isDefault = true,
  }) async {
    final res = await _dio.post(
      Endpoints.addresses,
      data: {
        'label': label,
        'city': city,
        'area': area,
        'details': details,
        'lat': lat,
        'lng': lng,
        'isDefault': isDefault,
      },
    );

    return Address.fromJson((res.data['address'] as Map).cast<String, dynamic>());
  }

  Future<Address> setDefault(String addressId) async {
    final res = await _dio.patch('${Endpoints.addresses}/$addressId/default');
    return Address.fromJson((res.data['address'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteAddress(String addressId) async {
    await _dio.delete('${Endpoints.addresses}/$addressId');
  }
}
