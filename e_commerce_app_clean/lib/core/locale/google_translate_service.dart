import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../../features/authentication/data/data_sources/local/local_data_source.dart';
import '../../features/product/domain/entities/product_entity.dart';

class GoogleTranslateService {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;

  final Map<String, String> _cache = {};

  GoogleTranslateService({
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

  Future<List<String>> translateTexts(
    List<String> texts, {
    String target = 'am',
    String source = 'en',
  }) async {
    if (texts.isEmpty) return [];
    if (target == source) return texts;

    final uncached = <String>[];
    final results = List<String>.filled(texts.length, '');

    for (var i = 0; i < texts.length; i++) {
      final t = texts[i];
      final cacheKey = '$source|$target|$t';
      if (_cache.containsKey(cacheKey)) {
        results[i] = _cache[cacheKey]!;
      } else {
        uncached.add(t);
      }
    }

    if (uncached.isEmpty) {
      for (var i = 0; i < texts.length; i++) {
        results[i] = _cache['$source|$target|${texts[i]}'] ?? texts[i];
      }
      return results;
    }

    try {
      final response = await client.post(
        Uri.parse('${Urls2.baseUrl}/translate'),
        headers: await _headers(),
        body: json.encode({
          'texts': uncached,
          'target': target,
          'source': source,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final translations = (body['data']['translations'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();

        for (var i = 0; i < uncached.length; i++) {
          _cache['$source|$target|${uncached[i]}'] = translations[i];
        }
      }
    } catch (_) {
      for (final t in uncached) {
        _cache['$source|$target|$t'] = t;
      }
    }

    for (var i = 0; i < texts.length; i++) {
      results[i] = _cache['$source|$target|${texts[i]}'] ?? texts[i];
    }
    return results;
  }

  Future<List<ProductEntity>> translateProducts(List<ProductEntity> products) async {
    if (products.isEmpty) return products;

    final names = products.map((p) => p.name).toList();
    final descriptions = products.map((p) => p.description).toList();
    final categories = products.map((p) => p.category).toList();

    final translatedNames = await translateTexts(names);
    final translatedDescs = await translateTexts(descriptions);
    final translatedCats = await translateTexts(categories);

    return List.generate(products.length, (i) {
      final p = products[i];
      return ProductEntity(
        id: p.id,
        name: translatedNames[i],
        description: translatedDescs[i],
        price: p.price,
        imageUrl: p.imageUrl,
        category: translatedCats[i],
        rating: p.rating,
      );
    });
  }
}
