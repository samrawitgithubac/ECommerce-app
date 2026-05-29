import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../locale/locale_cubit.dart';
import '../locale/locale_extensions.dart';

class LanguageToggle extends StatelessWidget {
  final bool compact;

  const LanguageToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(
      builder: (context, code) {
        if (compact) {
          return PopupMenuButton<String>(
            tooltip: context.tr('language'),
            icon: const Icon(Icons.language, size: 20),
            onSelected: (v) => context.read<LocaleCubit>().setLanguage(v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    if (code == 'en') const Icon(Icons.check, size: 18, color: Color(0xFF3F51F3)),
                    if (code == 'en') const SizedBox(width: 8),
                    Text(context.tr('english')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'am',
                child: Row(
                  children: [
                    if (code == 'am') const Icon(Icons.check, size: 18, color: Color(0xFF3F51F3)),
                    if (code == 'am') const SizedBox(width: 8),
                    Text(context.tr('amharic')),
                  ],
                ),
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangChip(
                label: 'EN',
                selected: code == 'en',
                onTap: () => context.read<LocaleCubit>().setLanguage('en'),
              ),
              _LangChip(
                label: 'አማ',
                selected: code == 'am',
                onTap: () => context.read<LocaleCubit>().setLanguage('am'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3F51F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
