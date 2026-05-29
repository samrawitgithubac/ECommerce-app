import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<String> {
  static const _prefKey = 'app_language';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_prefs.getString(_prefKey) ?? 'en');

  String get languageCode => state;
  bool get isAmharic => state == 'am';

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'am') return;
    await _prefs.setString(_prefKey, code);
    emit(code);
  }

  Future<void> toggle() async {
    await setLanguage(state == 'en' ? 'am' : 'en');
  }
}
