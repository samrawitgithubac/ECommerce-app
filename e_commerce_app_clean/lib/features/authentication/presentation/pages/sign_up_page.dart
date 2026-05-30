import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/locale_extensions.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/password_text_field.dart';
import '../../../product/presentation/widgets/components/styles/snack_bar_style.dart';
import '../../domain/entities/sign_up.dart';
import '../bloc/auth_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSignedInState) {
            ScaffoldMessenger.of(context).showSnackBar(
              customSnackBar(context.tr('accountCreated'), const Color(0xFF3F51F3)),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/home_page', (_) => false);
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              customSnackBar(state.message, const Color(0xFFFF5252)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoadingState) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3F51F3)));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Color(0xFF3F51F3)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3F51F3), Color(0xFF6C63FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ECOM',
                          style: TextStyle(fontFamily: 'CaveatBrush', fontSize: 24, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const LanguageToggle(compact: true),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('createAccount'),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('joinUs'),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildLabel(context.tr('fullName')),
                  const SizedBox(height: 8),
                  _buildTextField(controller: usernameController, hint: 'John Smith', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildLabel(context.tr('email')),
                  const SizedBox(height: 8),
                  _buildTextField(controller: emailController, hint: 'your@email.com', icon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildLabel(context.tr('password')),
                  const SizedBox(height: 8),
                  PasswordTextField(
                    controller: passwordController,
                    hint: 'Min 6 characters',
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context.tr('confirmPassword')),
                  const SizedBox(height: 8),
                  PasswordTextField(
                    controller: confirmPasswordController,
                    hint: 'Re-enter password',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) => setState(() => isChecked = value!),
                          activeColor: const Color(0xFF3F51F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(context.tr('termsAgree'), style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[600])),
                      Text(
                        context.tr('termsConditions'),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3F51F3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        context.tr('createAccountBtn'),
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('haveAccount'), style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/sign_in_page'),
                        child: Text(
                          ' ${context.tr('signIn')}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3F51F3)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSignUp() {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        customSnackBar(context.tr('allFieldsRequired'), const Color(0xFFFF5252)),
      );
    } else if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        customSnackBar(context.tr('passwordsNoMatch'), const Color(0xFFFF5252)),
      );
    } else if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        customSnackBar(context.tr('acceptTerms'), const Color(0xFFFF5252)),
      );
    } else {
      context.read<AuthBloc>().add(SignUpEvent(
            signUpEntity: SignUpEntity(
              email: emailController.text,
              password: passwordController.text,
              username: usernameController.text,
            ),
          ));
    }
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3F51F3), width: 1.5),
        ),
      ),
    );
  }
}
