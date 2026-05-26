import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../bloc/product_bloc.dart';
import '../widgets/components/header.dart';
import '../widgets/components/product_card.dart';
import '../widgets/components/styles/snack_bar_style.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadAllProductEvent());
    context.read<AuthBloc>().add(GetCurrentUserEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: HeaderView(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      customSnackBar(state.message, const Color(0xFFFF5252)),
                    );
                  }
                },
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF3F51F3)),
                      );
                    }
                    if (state is LoadedAllProductState) {
                      return RefreshIndicator(
                        color: const Color(0xFF3F51F3),
                        onRefresh: () async {
                          context.read<ProductBloc>().add(LoadAllProductEvent());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              return MyCardBox(product: state.products[index]);
                            },
                          ),
                        ),
                      );
                    } else if (state is ProductErrorState) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<ProductBloc>().add(LoadAllProductEvent()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F51F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/product_add_page'),
        backgroundColor: const Color(0xFF3F51F3),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }
}
