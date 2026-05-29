import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/locale/locale_cubit.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(value: di.sl<LocaleCubit>()),
        BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
        BlocProvider<ProductBloc>(create: (context) => di.sl<ProductBloc>()),
      ],
      child: const EcomApp(),
    ),
  );
}
