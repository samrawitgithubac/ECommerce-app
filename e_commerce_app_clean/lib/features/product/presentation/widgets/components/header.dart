import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/locale/locale_extensions.dart';
import '../../../../../core/widgets/language_toggle.dart';
import '../../../../authentication/presentation/bloc/auth_bloc.dart';

class HeaderView extends StatelessWidget {
  const HeaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F51F3), Color(0xFF6C63FF)],
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(context),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthUserLoaded) {
                        return Text(
                          state.userEntity.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const LanguageToggle(compact: true),
            const SizedBox(width: 4),
            _buildIconButton(
              icon: Icons.search_rounded,
              onPressed: () => Navigator.pushNamed(context, '/product_search_page'),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.shopping_cart_outlined,
              onPressed: () => Navigator.pushNamed(context, '/cart_page'),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.logout_rounded,
              filled: true,
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              context.tr('discoverProducts'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('goodMorning');
    if (hour < 17) return context.tr('goodAfternoon');
    return context.tr('goodEvening');
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool badge = false,
    bool filled = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF3F51F3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 20),
            color: filled ? Colors.white : Colors.grey[700],
            onPressed: onPressed,
          ),
        ),
        if (badge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('logout'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: Text(context.tr('logoutConfirm'), style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel'), style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogOutEvent());
              Navigator.popAndPushNamed(ctx, '/sign_in_page');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('logout'), style: const TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}
