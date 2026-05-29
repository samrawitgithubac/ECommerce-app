import 'api_host.dart';

class Urls {
  static String get baseUrl => '$kApiHost/api/v1/products';  static String getProductId(String id) => '$baseUrl/$id';
  static String deleteProductId(String id) => '$baseUrl/$id';
  static String get getProducts => baseUrl;
  static String get addProduct => baseUrl;
  static String updateProductId(String id) => '$baseUrl/$id';
}
class Urls2 {
  static String get baseUrl => '$kApiHost/api/v2';
  static String getCurrentUser() => '$baseUrl/users/me';
  static String login() => '$baseUrl/auth/login';
  static String signUp() => '$baseUrl/auth/register';
  static String getProductId(String id) => '$baseUrl/products/$id';
  static String deleteProductId(String id) => '$baseUrl/products/$id';
  static String get getProducts => '$baseUrl/products';
  static String get addProduct => '$baseUrl/products';
  static String updateProductId(String id) => '$baseUrl/products/$id';
  static String get cart => '$baseUrl/cart';
  static String cartItem(String itemId) => '$cart/$itemId';
  static String get paymentMethods => '$baseUrl/payment-methods';
  static String get orders => '$baseUrl/orders';
  static String get checkout => '$baseUrl/orders/checkout';
  static String orderById(String id) => '$baseUrl/orders/$id';
  static String get demoCheckout => '$baseUrl/payments/demo-checkout';
  static String get stripeConfig => '$baseUrl/payments/stripe/config';
  static String get stripeCreateSession => '$baseUrl/payments/stripe/create-checkout-session';
  static String stripeVerifySession(String sessionId) =>
      '$baseUrl/payments/stripe/verify-session?session_id=$sessionId';
}
