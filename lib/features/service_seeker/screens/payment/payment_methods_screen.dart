import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedPaymentMethod = 'cash_on_delivery';
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentPreference();
  }

  Future<void> _loadPaymentPreference() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('service_seekers').doc(user.uid).get();

        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            selectedPaymentMethod =
                data?['preferredPaymentMethod'] ?? 'cash_on_delivery';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading payment preference: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _savePaymentPreference(String method) async {
    setState(() {
      isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('service_seekers').doc(user.uid).update({
          'preferredPaymentMethod': method,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          selectedPaymentMethod = method;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment preference saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving payment preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showComingSoonDialog(String methodName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$methodName - Coming Soon'),
        content: Text(
          'We\'re working hard to bring you $methodName payment option. '
          'Stay tuned for updates!\n\n'
          'For now, you can use Cash on Delivery for all your bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your preferred payment method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cash on Delivery - Active
                  _PaymentMethodCard(
                    icon: Icons.money,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay in cash when service is completed',
                    value: 'cash_on_delivery',
                    isSelected: selectedPaymentMethod == 'cash_on_delivery',
                    isActive: true,
                    onTap: () => _savePaymentPreference('cash_on_delivery'),
                  ),

                  const SizedBox(height: 12),

                  // Credit/Debit Card - Coming Soon
                  _PaymentMethodCard(
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card',
                    subtitle: 'Pay securely with your card',
                    value: 'card',
                    isSelected: selectedPaymentMethod == 'card',
                    isActive: false,
                    onTap: () => _showComingSoonDialog('Credit/Debit Card'),
                  ),

                  const SizedBox(height: 12),

                  // Digital Wallet - Coming Soon
                  _PaymentMethodCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Digital Wallet',
                    subtitle: 'Pay with PayPal, Apple Pay, Google Pay',
                    value: 'wallet',
                    isSelected: selectedPaymentMethod == 'wallet',
                    isActive: false,
                    onTap: () => _showComingSoonDialog('Digital Wallet'),
                  ),

                  const SizedBox(height: 12),

                  // Bank Transfer - Coming Soon
                  _PaymentMethodCard(
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Direct transfer from your bank account',
                    value: 'bank_transfer',
                    isSelected: selectedPaymentMethod == 'bank_transfer',
                    isActive: false,
                    onTap: () => _showComingSoonDialog('Bank Transfer'),
                  ),

                  const SizedBox(height: 32),

                  // Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Cash on Delivery is currently the only available payment method\n'
                          '• Payment is made directly to the service provider after work completion\n'
                          '• Make sure to have exact change ready\n'
                          '• More payment options will be added soon',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSaving) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Saving preference...'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _PaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isActive ? onTap : () => onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isSelected ? Colors.blue : Colors.grey[200])
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? (isSelected ? Colors.white : Colors.grey[600])
                      : Colors.grey[500],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? (isDarkMode ? Colors.white : Colors.black87)
                                : Colors.grey[500],
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive
                            ? (isDarkMode ? Colors.white70 : Colors.grey[600])
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Radio<String>(
                  value: value,
                  groupValue: selectedPaymentMethod,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _savePaymentPreference(newValue);
                    }
                  },
                  activeColor: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
