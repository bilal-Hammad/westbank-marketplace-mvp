import 'package:dio/dio.dart';

import '../../core/constants/endpoints.dart';
import '../models/order_model.dart';
import 'api_service.dart';

class StoreOrdersService {
  final Dio _dio = ApiService().dio;

  Future<List<Order>> fetchInbox() async {
    final res = await _dio.get(Endpoints.storeOrdersInbox);
    final list = (res.data['orders'] as List?) ?? const [];
    return list.map((e) => Order.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> acceptOrder({required String orderId, required int prepMinutes}) async {
    await _dio.post(
      Endpoints.storeOrderAccept,
      data: {'orderId': orderId, 'prepMinutes': prepMinutes},
    );
  }

  Future<void> rejectOrder({required String orderId}) async {
    await _dio.post(
      Endpoints.storeOrderReject,
      data: {'orderId': orderId},
    );
  }

  Future<void> markReady({required String orderId}) async {
    await _dio.post(
      Endpoints.storeOrderReady,
      data: {'orderId': orderId},
    );
  }

  /// Dev helper to simulate a taxi office reply to unblock acceptance.
  /// Body example: {"from":"970599111111","text":"1"}
  Future<void> simulateTaxiReply({required String from, required String text}) async {
    await _dio.post(
      Endpoints.taxiWhatsappReply,
      data: {'from': from, 'text': text},
    );
  }
}
