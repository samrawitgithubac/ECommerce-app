import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/constants/constants.dart';
import '../../../../../core/error/exception.dart';
import '../../model/log_in_model.dart';
import '../../model/sign_up_model.dart';
import '../../model/user_model.dart';
import '../local/local_data_source.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  final AuthLocalDataSource authLocalDataSource;
  AuthRemoteDatasourceImpl(
      {required this.client, required this.authLocalDataSource});

  String? _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      final message = decoded['message'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      if (message is String) return message;
    } catch (_) {}
    return null;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final token = await authLocalDataSource.getToken();
    final response =
        await client.get(Uri.parse(Urls2.getCurrentUser()), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body)['data']);
      return user;
    } else {
      throw ServerException(
        message: _messageFromBody(response.body) ?? 'Failed to load user',
      );
    }
  }

  @override
  Future<void> logIn(LogInModel logInModel) async {
    final response = await client.post(
      Uri.parse(Urls2.login()),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(logInModel.toJson()),
    );

    if (response.statusCode == 201) {
      await authLocalDataSource
          .cacheToken(jsonDecode(response.body)['data']['access_token']);
      return;
    }
    throw ServerException(
      message: _messageFromBody(response.body) ?? 'Invalid email or password',
    );
  }

  @override
  Future<void> logOut() async {
    try {
      await authLocalDataSource.removeToken();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> signUp(SignUpModel signUpModel) async {
    final response = await client.post(
      Uri.parse(Urls2.signUp()),
      body: jsonEncode(signUpModel.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) return;

    throw ServerException(
      message: _messageFromBody(response.body) ?? 'Registration failed',
    );
  }
}
