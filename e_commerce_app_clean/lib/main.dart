import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/cover_page.dart';
import 'features/authentication/presentation/pages/sign_in_page.dart';
import 'features/authentication/presentation/pages/sign_up_page.dart';
import 'features/product/domain/entities/product_entity.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/product/presentation/pages/details_page.dart';
import 'features/product/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/product_add_page.dart';
import 'features/product/presentation/pages/product_search_page.dart';
import 'features/product/presentation/pages/update_page.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
        BlocProvider<ProductBloc>(create: (context) => sl<ProductBloc>()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primaryColor: const Color(0xFF3F51F3),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51F3),
            primary: const Color(0xFF3F51F3),
            error: const Color(0xFFFF5252),
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          fontFamily: 'Poppins',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        initialRoute: '/cover_page',
        onGenerateRoute: (settings) {
          if (settings.name == '/sign_in_page') {
            return _createRoute(SignInPage());
          } else if (settings.name == '/sign_up_page') {
            return _createRoute(const SignUpPage());
          } else if (settings.name == '/cover_page') {
            return _createRoute(const CoverPage());
          } else if (settings.name == '/home_page') {
            return _createRoute(const Home());
          } else if (settings.name == '/product_add_page') {
            return _createRoute(const AddProudctPage());
          } else if (settings.name == '/product_search_page') {
            return _createRoute(const ProductSearchPage());
          } else if (settings.name == '/details_page') {
            return _createRoute(DetailsPage(selectedProduct: settings.arguments as ProductEntity));
          } else if (settings.name == '/update_page') {
            return _createRoute(UpdatePage(selectedProduct: settings.arguments as ProductEntity));
          }
          return null;
        },
        title: 'ECOM Shop',
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

PageRouteBuilder _createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
