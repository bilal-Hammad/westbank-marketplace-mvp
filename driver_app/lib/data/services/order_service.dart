import 'package:dio/dio.dart';

import '../../core/constants/endpoints.dart';
import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  final Dio _dio = ApiService().dio;

  Future<Order> createOrder({
    required String storeId,
    required String branchId,
    required List<Map<String, dynamic>> items,
    String? notesToStore,
    String? notesToDriver,
  }) async {
    final res = await _dio.post(
      Endpoints.createOrder,
      data: {
        'storeId': storeId,
        'branchId': branchId,
        'notesToStore': notesToStore,
        'notesToDriver': notesToDriver,
        'items': items,
      },
    );

    return Order.fromJson((res.data['order'] as Map).cast<String, dynamic>());
  }

  Future<Order> getOrder(String orderId) async {
    final path = Endpoints.orderDetails.replaceAll('{orderId}', orderId);
    final res = await _dio.get(path);
    return Order.fromJson((res.data['order'] as Map).cast<String, dynamic>());
  }
}
