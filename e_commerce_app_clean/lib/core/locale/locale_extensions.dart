import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_strings.dart';
import 'locale_cubit.dart';
import 'locale_scope.dart';

extension LocaleContext on BuildContext {
  String get lang {
    final scope = LocaleScope.maybeOf(this);
    return scope?.languageCode ?? read<LocaleCubit>().state;
  }

  String tr(String key) => AppStrings.get(key, lang);
}
