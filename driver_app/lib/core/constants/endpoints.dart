class Endpoints {
  static const baseUrl = 'http://localhost:4001';

  // Auth
  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const me = '/auth/me';

  // Driver
  static const driverStatus = '/driver/status';
  static const driverOnline = '/driver/online';
  static const driverOffline = '/driver/offline';
  static const availableDeliveries = '/driver/deliveries/available';
  static const activeDeliveries = '/driver/deliveries/active';
  static const deliveryById = '/driver/deliveries/{deliveryId}';
  static const acceptDelivery = '/driver/deliveries/{deliveryId}/accept';
  static const rejectDelivery = '/driver/deliveries/{deliveryId}/reject';
  static const pickupDelivery = '/driver/deliveries/{deliveryId}/pickup';
  static const deliveredDelivery = '/driver/deliveries/{deliveryId}/delivered';

  // Dummy endpoints for unused services
  static const addresses = '/addresses';
  static const menuByStore = '/menu/store/{storeId}';
  static const createOrder = '/orders';
  static const orderDetails = '/orders/{orderId}';
  static const stores = '/stores';
}
