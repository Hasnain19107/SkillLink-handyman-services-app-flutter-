import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String? selectedPaymentMethod;

  const PaymentMethodScreen({
    Key? key,
    this.selectedPaymentMethod,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedPaymentMethod = 'cod'; // Default to Cash on Delivery

  @override
  void initState() {
    super.initState();
    if (widget.selectedPaymentMethod != null) {
      _selectedPaymentMethod = widget.selectedPaymentMethod!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.blue.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Choose Payment Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select how you want to pay for this service',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Available Payment Methods
                  const Text(
                    'Available Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cash on Delivery Option
                  _buildPaymentOption(
                    icon: Icons.money,
                    title: 'Cash on Delivery',
                    subtitle:
                        'Pay directly to the service provider after job completion',
                    value: 'cod',
                    isRecommended: true,
                    isAvailable: true,
                  ),

                  const SizedBox(height: 32),

                  // Coming Soon Payment Methods
                  const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card',
                    subtitle: 'Pay securely with your card',
                    value: 'card',
                    isAvailable: false,
                  ),

                  const SizedBox(height: 12),

                  _buildPaymentOption(
                    icon: Icons.account_balance_wallet,
                    title: 'Digital Wallet',
                    subtitle: 'PayPal, Apple Pay, Google Pay',
                    value: 'wallet',
                    isAvailable: false,
                  ),

                  const SizedBox(height: 12),

                  _buildPaymentOption(
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Direct bank account transfer',
                    value: 'bank',
                    isAvailable: false,
                  ),

                  const SizedBox(height: 32),

                  // Payment Security Info
                  _buildSecurityInfo(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selected payment method info
                if (_selectedPaymentMethod == 'cod')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cash on Delivery selected - Pay after service completion',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedPaymentMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue with Selected Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    bool isRecommended = false,
    bool isAvailable = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPaymentMethod == value;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isAvailable
          ? (isDark ? Colors.grey[850] : Colors.white)
          : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected && isAvailable
              ? Colors.blue
              : Colors.grey.withOpacity(0.3),
          width: isSelected && isAvailable ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: isAvailable
            ? () {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              }
            : null,
        enabled: isAvailable,
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                // ignore: deprecated_member_use
                color: isAvailable ? Colors.blue : Colors.grey,
                size: 24,
              ),
            ),
            if (isRecommended && isAvailable)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isAvailable
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey.shade600,
                ),
              ),
            ),
            if (isRecommended && isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isAvailable
                  ? (isDark ? Colors.grey[400] : Colors.grey[600])
                  : Colors.grey.shade500,
            ),
          ),
        ),
        trailing: isAvailable
            ? Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                onChanged: (selectedValue) {
                  setState(() {
                    _selectedPaymentMethod = selectedValue!;
                  });
                },
                activeColor: Colors.blue,
              )
            : Icon(
                Icons.lock_outline,
                color: Colors.grey.shade400,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Secure Payment',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Payment will be processed after the service provider accepts your booking\n'
            '• Your payment information is protected with bank-level security\n'
            '• You can contact support anytime for payment-related queries',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
