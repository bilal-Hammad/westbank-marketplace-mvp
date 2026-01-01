import 'package:dio/dio.dart';

import '../../core/constants/endpoints.dart';
import 'api_service.dart';

class DriverService {
  final Dio _dio = ApiService().dio;

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get(Endpoints.me);
    return (res.data['me'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _dio.get(Endpoints.driverStatus);
    return (res.data['status'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> goOnline({double? lat, double? lng}) async {
    final res = await _dio.post(Endpoints.driverOnline, data: {'lat': lat, 'lng': lng});
    return (res.data['status'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> goOffline() async {
    final res = await _dio.post(Endpoints.driverOffline);
    return (res.data['status'] as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableDeliveries() async {
    final res = await _dio.get(Endpoints.availableDeliveries);
    final list = (res.data['items'] as List?) ?? const [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveDeliveries() async {
    final res = await _dio.get(Endpoints.activeDeliveries);
    final list = (res.data['items'] as List?) ?? const [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> acceptDelivery(String deliveryId) async {
    final path = Endpoints.acceptDelivery.replaceFirst('{deliveryId}', deliveryId);
    final res = await _dio.post(path);
    return (res.data['delivery'] as Map).cast<String, dynamic>();
  }

  Future<void> rejectDelivery(String deliveryId) async {
    final path = Endpoints.rejectDelivery.replaceFirst('{deliveryId}', deliveryId);
    await _dio.post(path);
  }

  Future<void> markPickedUp(String deliveryId) async {
    final path = Endpoints.pickupDelivery.replaceFirst('{deliveryId}', deliveryId);
    await _dio.post(path);
  }

  Future<void> markDelivered(String deliveryId) async {
    final path = Endpoints.deliveredDelivery.replaceFirst('{deliveryId}', deliveryId);
    await _dio.post(path);
  }
}
