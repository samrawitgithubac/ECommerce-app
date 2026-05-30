import 'package:flutter/material.dart';

/// Provides the active language to descendants without resetting [MaterialApp].
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.languageCode,
    required super.child,
  });

  final String languageCode;

  static LocaleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>();
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) {
    return oldWidget.languageCode != languageCode;
  }
}
