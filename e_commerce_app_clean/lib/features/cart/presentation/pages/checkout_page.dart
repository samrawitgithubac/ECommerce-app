import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/locale/locale_extensions.dart';
import '../../../../core/widgets/app_bar_language_actions.dart';
import '../../../../injection_container.dart';
import '../../data/cart_api_service.dart';

class CheckoutPage extends StatefulWidget {
  final double cartTotal;

  const CheckoutPage({super.key, required this.cartTotal});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cartApi = CartApiService(client: sl(), authLocalDataSource: sl());

  bool _loading = true;
  bool _placing = false;
  String? _error;
  List<PaymentMethodModel> _methods = [];
  String? _selectedMethodId;
  bool _stripeEnabled = false;
  bool _demoMode = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final result = await _cartApi.getPaymentMethods();

      if (!mounted) return;
      setState(() {
        _methods = result.methods;
        _demoMode = result.demoMode;
        _stripeEnabled = result.stripeEnabled;
        _selectedMethodId =
            result.methods.isNotEmpty ? result.methods.first.id : null;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _methods = PaymentMethodsResult.fallbackMethods();
        _demoMode = true;
        _stripeEnabled = false;
        _selectedMethodId = 'card';
        _loading = false;
        _error = null;
      });
    }
  }

  IconData _iconForMethod(String id) {
    switch (id) {
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet_outlined;
      case 'mobile':
        return Icons.phone_android;
      case 'cod':
        return Icons.local_shipping_outlined;
      default:
        return Icons.payment;
    }
  }

  Future<void> _showOrderSuccess(OrderSummaryModel order, String paymentLabel) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            const SizedBox(width: 8),
            Text(context.tr('orderPlaced'), style: const TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        content: Text(
          'Order #${order.id.substring(0, 8)}...\n'
          'Total: \$${order.total.toStringAsFixed(2)}\n'
          'Payment: $paymentLabel',
          style: const TextStyle(fontFamily: 'Poppins', height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51F3),
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('done')),
          ),
        ],
      ),
    );
  }

  Future<void> _payDemoCard() async {
    final order = await _cartApi.demoCheckout(paymentMethod: 'card');
    if (!mounted) return;
    await _showOrderSuccess(order, 'Demo card (no charge)');
  }

  Future<void> _payWithStripe() async {
    if (!_stripeEnabled) {
      await _payDemoCard();
      return;
    }

    final session = await _cartApi.createStripeCheckoutSession();
    final uri = Uri.parse(session.url);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw Exception('Could not open Stripe checkout page');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('completeStripe'), style: const TextStyle(fontFamily: 'Poppins')),
        content: Text(
          context.tr('stripeSteps'),
          style: const TextStyle(fontFamily: 'Poppins', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _placing = true);
              try {
                final order = await _cartApi.verifyStripeSession(session.sessionId);
                if (!mounted) return;
                await _showOrderSuccess(order, 'Stripe');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: const Color(0xFFFF5252),
                  ),
                );
              } finally {
                if (mounted) setState(() => _placing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51F3),
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('confirmPayment')),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedMethodId == null) return;

    setState(() => _placing = true);
    try {
      if (_selectedMethodId == 'card') {
        await _payWithStripe();
        return;
      }

      final order = await _cartApi.checkout(_selectedMethodId!);
      if (!mounted) return;

      final paymentLabel = _methods
              .where((m) => m.id == order.paymentMethod)
              .map((m) => m.name)
              .firstOrNull ??
          order.paymentMethod;

      await _showOrderSuccess(order, paymentLabel);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  String _payButtonLabel(BuildContext context) {
    if (_selectedMethodId == 'card') {
      return _demoMode && !_stripeEnabled
          ? context.tr('payDemo')
          : context.tr('payStripe');
    }
    return _demoMode ? context.tr('placeOrderDemo') : context.tr('placeOrder');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          context.tr('payment'),
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: appBarLanguageActions(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F51F3)))
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3F51F3), Color(0xFF6C63FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('orderTotal'),
                            style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                          ),
                          Text(
                            '\$${widget.cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_demoMode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _stripeEnabled ? Icons.lock_outline : Icons.science_outlined,
                                color: _stripeEnabled
                                    ? const Color(0xFF635BFF)
                                    : const Color(0xFF4CAF50),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _stripeEnabled
                                      ? context.tr('stripeTestBanner')
                                      : context.tr('demoModeBanner'),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        context.tr('selectPayment'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _methods.length,
                        itemBuilder: (context, index) {
                          final method = _methods[index];
                          final selected = _selectedMethodId == method.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => setState(() => _selectedMethodId = method.id),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF3F51F3)
                                          : Colors.grey[200]!,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _iconForMethod(method.id),
                                        color: const Color(0xFF3F51F3),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method.name,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              method.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: method.id,
                                        groupValue: _selectedMethodId,
                                        onChanged: (v) =>
                                            setState(() => _selectedMethodId = v),
                                        activeColor: const Color(0xFF3F51F3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _placing ? null : _placeOrder,
                  icon: _selectedMethodId == 'card'
                      ? const Icon(Icons.lock, size: 20)
                      : const Icon(Icons.payment, size: 20),
                  label: Text(
                    _payButtonLabel(context),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMethodId == 'card' && _stripeEnabled
                        ? const Color(0xFF635BFF)
                        : const Color(0xFF3F51F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
    );
  }
}
