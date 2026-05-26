import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/constants/constants.dart';
import '../../../../../core/error/exception.dart';
import '../../../../authentication/data/data_sources/local/local_data_source.dart';
import '../../models/product_model.dart';
import 'remote_data_source.dart';

class RemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  RemoteDataSourceImpl(
      {required this.authLocalDataSource, required this.client});

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    String token = await authLocalDataSource.getToken();

    final response = await client.post(
      Uri.parse(Urls2.addProduct),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      return ProductModel.fromJson(json.decode(response.body)['data']);
    } else {
      throw ServerException();
    }
  }

  @override
  Future<bool> deleteProduct(String id) async {
    String token = await authLocalDataSource.getToken();

    final response =
        await client.delete(Uri.parse(Urls2.deleteProductId(id)), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return true;
    } else {
      throw ServerException();
    }
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    String token = await authLocalDataSource.getToken();

    final response =
        await client.get(Uri.parse(Urls2.getProductId(id)), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body)['data']);
    } else {
      throw ServerException();
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    String token = await authLocalDataSource.getToken();
    final response = await client.get(Uri.parse(Urls2.getProducts), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    List<dynamic> jsonDecoded = jsonDecode(response.body)['data'];
    final products =
        jsonDecoded.map((products) => ProductModel.fromJson(products)).toList();
    if (response.statusCode == 200) {
      return products;
    } else {
      throw ServerException();
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    String token = await authLocalDataSource.getToken();

    final response =
        await client.put(Uri.parse(Urls2.updateProductId(product.id)),
            body: jsonEncode({
              'name': product.name,
              'description': product.description,
              'price': product.price,
            }),
            headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        });
    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body)['data']);
    } else {
      throw ServerException();
    }
  }
}
