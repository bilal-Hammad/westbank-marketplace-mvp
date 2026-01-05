class Endpoints {
  /// Update this when running on a real device/emulator.
  /// - Android emulator: http://10.0.2.2:4000
  /// - iOS simulator: http://localhost:4000
  /// - LAN device: http://<YOUR_PC_IP>:4000
  static const baseUrl = 'http://localhost:4001';

  // Auth
  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const me = '/auth/me';

  // Store orders (Stage 2)
  static const storeOrdersInbox = '/store/orders/inbox';
  static const storeOrderAccept = '/store/orders/accept';
  static const storeOrderReject = '/store/orders/reject';
  static const storeOrderReady = '/store/orders/ready';

  // Dev helper (simulate taxi office reply)
  static const taxiWhatsappReply = '/taxi/whatsapp-reply';
}
