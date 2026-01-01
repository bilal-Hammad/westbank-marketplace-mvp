import 'package:dio/dio.dart';

import '../../core/constants/endpoints.dart';
import '../models/store_model.dart';
import 'api_service.dart';

class StoreService {
  final Dio _dio = ApiService().dio;

  /// GET /stores
  /// Backend response shape: { stores: [...] }
  Future<List<Store>> getStores() async {
    final res = await _dio.get(Endpoints.stores);

    final data = res.data;
    final List storesJson = (data is Map && data['stores'] is List)
        ? (data['stores'] as List)
        : (data as List);

    return storesJson.map((json) => Store.fromJson(json)).toList();
  }
}
