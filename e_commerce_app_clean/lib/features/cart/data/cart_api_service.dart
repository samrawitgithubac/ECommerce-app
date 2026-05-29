import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/constants.dart';
import '../../../core/error/exception.dart';
import '../../authentication/data/data_sources/local/local_data_source.dart';
import '../../product/data/models/product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final ProductModel product;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
    );
  }

  double get lineTotal => product.price * quantity;
}

class CartSummary {
  final List<CartItemModel> items;
  final double total;

  CartSummary({required this.items, required this.total});
}

class PaymentMethodModel {
  final String id;
  final String name;
  final String description;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}

class StripeCheckoutResult {
  final String sessionId;
  final String url;

  StripeCheckoutResult({required this.sessionId, required this.url});

  factory StripeCheckoutResult.fromJson(Map<String, dynamic> json) {
    return StripeCheckoutResult(
      sessionId: json['sessionId'] as String,
      url: json['url'] as String,
    );
  }
}

class PaymentMethodsResult {
  final List<PaymentMethodModel> methods;
  final bool demoMode;
  final bool stripeEnabled;

  PaymentMethodsResult({
    required this.methods,
    required this.demoMode,
    required this.stripeEnabled,
  });

  static List<PaymentMethodModel> fallbackMethods() => [
        PaymentMethodModel(
          id: 'card',
          name: 'Card (Demo)',
          description: 'Simulated payment – no real charge',
        ),
        PaymentMethodModel(
          id: 'cod',
          name: 'Cash on Delivery',
          description: 'Pay when you receive the order',
        ),
      ];
}

class StripeConfigModel {
  final bool enabled;
  final String publishableKey;
  final String currency;

  StripeConfigModel({
    required this.enabled,
    required this.publishableKey,
    required this.currency,
  });

  factory StripeConfigModel.fromJson(Map<String, dynamic> json) {
    return StripeConfigModel(
      enabled: json['enabled'] as bool? ?? false,
      publishableKey: json['publishableKey'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

class OrderSummaryModel {
  final String id;
  final double total;
  final String paymentMethod;
  final String status;
  final int itemCount;

  OrderSummaryModel({
    required this.id,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.itemCount,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      id: json['id'] as String,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String? ?? 'paid',
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

class CartApiService {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;

  CartApiService({
    required this.client,
    required this.authLocalDataSource,
  });

  Future<Map<String, String>> _headers() async {
    final token = await authLocalDataSource.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<CartSummary> getCart() async {
    final response = await client.get(
      Uri.parse(Urls2.cart),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (data['total'] as num).toDouble();
      return CartSummary(items: items, total: total);
    }
    throw ServerException();
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final response = await client.post(
      Uri.parse(Urls2.cart),
      headers: await _headers(),
      body: json.encode({'productId': productId, 'quantity': quantity}),
    );

    if (response.statusCode != 201) {
      throw ServerException();
    }
  }

  Future<void> removeFromCart(String itemId) async {
    final response = await client.delete(
      Uri.parse(Urls2.cartItem(itemId)),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw ServerException();
    }
  }

  Future<PaymentMethodsResult> getPaymentMethods() async {
    final response = await client.get(
      Uri.parse(Urls2.paymentMethods),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>;
      return PaymentMethodsResult(
        methods: list
            .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        demoMode: body['demoMode'] as bool? ?? true,
        stripeEnabled: body['stripeEnabled'] as bool? ?? false,
      );
    }
    throw ServerException();
  }

  Future<OrderSummaryModel> demoCheckout({String paymentMethod = 'card'}) async {
    final response = await client.post(
      Uri.parse(Urls2.demoCheckout),
      headers: await _headers(),
      body: json.encode({'paymentMethod': paymentMethod}),
    );

    if (response.statusCode == 201) {
      return OrderSummaryModel.fromJson(
        json.decode(response.body)['data'] as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 400) {
      final body = json.decode(response.body);
      throw Exception(body['message']?.toString() ?? 'Checkout failed');
    }
    throw ServerException();
  }

  Future<OrderSummaryModel> checkout(String paymentMethod) async {
    final response = await client.post(
      Uri.parse(Urls2.checkout),
      headers: await _headers(),
      body: json.encode({'paymentMethod': paymentMethod}),
    );

    if (response.statusCode == 201) {
      return OrderSummaryModel.fromJson(
        json.decode(response.body)['data'] as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 400) {
      final body = json.decode(response.body);
      throw Exception(body['message']?.toString() ?? 'Checkout failed');
    }
    throw ServerException();
  }

  Future<StripeConfigModel> getStripeConfig() async {
    final response = await client.get(
      Uri.parse(Urls2.stripeConfig),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return StripeConfigModel.fromJson(
        json.decode(response.body)['data'] as Map<String, dynamic>,
      );
    }
    throw ServerException();
  }

  Future<StripeCheckoutResult> createStripeCheckoutSession() async {
    final response = await client.post(
      Uri.parse(Urls2.stripeCreateSession),
      headers: await _headers(),
    );

    if (response.statusCode == 201) {
      return StripeCheckoutResult.fromJson(
        json.decode(response.body)['data'] as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 503) {
      final body = json.decode(response.body);
      throw Exception(body['message']?.toString() ?? 'Stripe not configured');
    }
    if (response.statusCode == 400) {
      final body = json.decode(response.body);
      throw Exception(body['message']?.toString() ?? 'Cannot start checkout');
    }
    throw ServerException();
  }

  Future<OrderSummaryModel> verifyStripeSession(String sessionId) async {
    final response = await client.get(
      Uri.parse(Urls2.stripeVerifySession(sessionId)),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return OrderSummaryModel.fromJson(
        json.decode(response.body)['data'] as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 402) {
      final body = json.decode(response.body);
      throw Exception(body['message']?.toString() ?? 'Payment not completed');
    }
    throw ServerException();
  }

  Future<List<OrderSummaryModel>> getOrders() async {
    final response = await client.get(
      Uri.parse(Urls2.orders),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final list = json.decode(response.body)['data'] as List<dynamic>;
      return list
          .map((e) => OrderSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ServerException();
  }
}
