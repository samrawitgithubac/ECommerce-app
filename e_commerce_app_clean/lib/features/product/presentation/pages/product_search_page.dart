import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/locale_extensions.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../injection_container.dart';
import '../bloc/product_bloc.dart';
import '../widgets/components/product_card.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocProvider(
        create: (_) => sl<ProductBloc>()..add(LoadAllProductEvent()),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF3F51F3), size: 20),
                    ),
                    Expanded(
                      child: Text(
                        context.tr('searchProducts'),
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ),
                    const LanguageToggle(compact: true),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: context.tr('searchByName'),
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: Colors.grey[400],
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3F51F3), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF3F51F3)));
                    } else if (state is LoadedAllProductState) {
                      return _FilteredList(
                        allProducts: state.products,
                        searchController: _searchController,
                      );
                    } else if (state is ProductErrorState) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600]),
                        ),
                      );
                    }
                    return Center(
                      child: Text(context.tr('startSearching'), style: const TextStyle(fontFamily: 'Poppins')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredList extends StatefulWidget {
  final List allProducts;
  final TextEditingController searchController;

  const _FilteredList({required this.allProducts, required this.searchController});

  @override
  State<_FilteredList> createState() => _FilteredListState();
}

class _FilteredListState extends State<_FilteredList> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? widget.allProducts
        : widget.allProducts
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              context.tr('noResults'),
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) => MyCardBox(product: filtered[index]),
      ),
    );
  }
}
