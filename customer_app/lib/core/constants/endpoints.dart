class Endpoints {
  static const baseUrl = 'http://localhost:4000';


  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';

  static const addresses = '/addresses';
  static const stores = '/stores';
  static const menuByStore = '/menu/store/{storeId}';
  static const products = '/stores/{storeId}/products';

  static const createOrder = '/orders';
  static const orderDetails = '/orders/{orderId}';
}
