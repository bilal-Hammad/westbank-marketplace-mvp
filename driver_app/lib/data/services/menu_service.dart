import 'package:dio/dio.dart';
import '../../core/constants/endpoints.dart';
import '../models/menu_model.dart';
import 'api_service.dart';

class MenuService {
  final Dio _dio = ApiService().dio;

  /// GET /menu/store/:storeId
  /// Backend response shape: { menu: { ... } }
  Future<Menu> getMenuByStore(String storeId) async {
    final path = Endpoints.menuByStore.replaceAll('{storeId}', storeId);
    final res = await _dio.get(path);

    final data = res.data;
    if (data is Map && data['menu'] is Map) {
      return Menu.fromJson((data['menu'] as Map).cast<String, dynamic>());
    }
    // Fallback if backend ever returns menu object directly
    if (data is Map) {
      return Menu.fromJson(data.cast<String, dynamic>());
    }
    throw Exception('Invalid menu response');
  }
}
