import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_strings.dart';
import 'locale_cubit.dart';

extension LocaleContext on BuildContext {
  String get lang => read<LocaleCubit>().languageCode;

  String tr(String key) => AppStrings.get(key, lang);
}
