import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/google_translate_service.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/locale/locale_extensions.dart';
import '../../../../injection_container.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/product_entity.dart';
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
  List<ProductEntity> _displayProducts = [];
  List<ProductEntity> _sourceProducts = [];
  bool _translating = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadAllProductEvent());
    context.read<AuthBloc>().add(GetCurrentUserEvent());
  }

  Future<void> _applyLocale(List<ProductEntity> products) async {
    _sourceProducts = products;
    if (!mounted) return;

    final lang = context.read<LocaleCubit>().state;
    if (lang == 'en') {
      setState(() {
        _displayProducts = products;
        _translating = false;
      });
      return;
    }

    setState(() => _translating = true);
    try {
      final translated =
          await sl<GoogleTranslateService>().translateProducts(products);
      if (mounted) {
        setState(() {
          _displayProducts = translated;
          _translating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayProducts = products;
          _translating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocaleCubit, String>(
          listener: (context, state) {
            if (_sourceProducts.isNotEmpty) {
              _applyLocale(_sourceProducts);
            }
          },
        ),
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is LoadedAllProductState) {
              _applyLocale(state.products);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                      if (state is ProductLoading || _translating) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF3F51F3)),
                        );
                      }
                      if (state is LoadedAllProductState || _displayProducts.isNotEmpty) {
                        final products = _displayProducts.isNotEmpty
                            ? _displayProducts
                            : (state is LoadedAllProductState ? state.products : []);
                        return RefreshIndicator(
                          color: const Color(0xFF3F51F3),
                          onRefresh: () async {
                            context.read<ProductBloc>().add(LoadAllProductEvent());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return MyCardBox(product: products[index]);
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
                                onPressed: () =>
                                    context.read<ProductBloc>().add(LoadAllProductEvent()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F51F3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  context.tr('retry'),
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/product_add_page'),
          backgroundColor: const Color(0xFF3F51F3),
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            context.tr('postItem'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
