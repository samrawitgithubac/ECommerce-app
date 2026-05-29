import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import '../../data/cart_api_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _cartApi = CartApiService(client: sl(), authLocalDataSource: sl());

  bool _loading = true;
  String? _error;
  CartSummary? _cart;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await _cartApi.getCart();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load cart. Is the backend running?';
        _loading = false;
      });
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      await _cartApi.removeFromCart(itemId);
      await _loadCart();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _cart != null && _cart!.items.isNotEmpty
          ? _buildCheckoutBar()
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3F51F3)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadCart, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_cart == null || _cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Add items to order them', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Browse products'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _cart!.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _cart!.items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.product.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              title: Text(
                item.product.name,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Qty: ${item.quantity} · \$${item.lineTotal.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                onPressed: () => _removeItem(item.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                    '\$${_cart!.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F51F3),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final placed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(cartTotal: _cart!.total),
                  ),
                );
                if (placed == true) {
                  await _loadCart();
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
