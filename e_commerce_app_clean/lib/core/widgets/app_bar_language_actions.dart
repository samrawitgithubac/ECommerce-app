import 'package:flutter/material.dart';

import 'language_toggle.dart';

/// Language toggle for app bars — use on every page so users can switch anytime.
List<Widget> appBarLanguageActions() => const [
      LanguageToggle(compact: true),
      SizedBox(width: 8),
    ];
