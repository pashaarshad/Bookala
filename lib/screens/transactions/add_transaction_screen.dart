import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';
import '../../services/sms_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String customerId;

  const AddTransactionScreen({super.key, required this.customerId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _smsService = SmsService();

  TransactionType _selectedType = TransactionType.credit;
  bool _sendSms = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check SMS permission on load
    _checkSmsPermission();
  }

  Future<void> _checkSmsPermission() async {
    final status = await _smsService.checkPermissionStatus();
    if (!status.isGranted && _sendSms) {
      // SMS toggle is on but permission not granted
      // Show info that permission is needed
    }
  }

  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.sms.request();
      if (result.isGranted) return true;
    }

    // Permission denied or permanently denied - show dialog
    if (mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            '📱 SMS Permission Required',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'To send automatic SMS notifications to your customers, please enable SMS permission in Settings.\n\nWithout this, you\'ll need to manually tap "Send" each time.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }

    return false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    // If SMS is enabled, check permission first
    if (_sendSms) {
      final hasPermission = await _requestSmsPermission();
      if (!hasPermission && mounted) {
        // Show snackbar that SMS will open manually
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS permission not granted. SMS app will open for you to send manually.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() => _isLoading = true);

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final customer = customerProvider.selectedCustomer;
      if (customer == null) {
        throw Exception('Customer not found');
      }

      final transaction = CustomerTransaction(
        id: const Uuid().v4(),
        customerId: widget.customerId,
        type: _selectedType,
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        date: DateTime.now(),
        smsSent: _sendSms,
        createdAt: DateTime.now(),
      );

      final success = await transactionProvider.addTransaction(
        transaction: transaction,
        customer: customer,
        sendSms: _sendSms,
        businessName: authProvider.userProfile?.businessName ?? 'Bookala',
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _selectedType == TransactionType.credit
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedType == TransactionType.credit ? 'Credit' : 'Debit'} of ₹${_amountController.text} added',
                ),
                if (_sendSms) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.sms, color: Colors.white, size: 16),
                ],
              ],
            ),
            backgroundColor: _selectedType == TransactionType.credit
                ? AppTheme.creditColor
                : AppTheme.debitColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding transaction: $e'),
          backgroundColor: AppTheme.debitColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Transaction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.selectedCustomer;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Card
                  if (customer != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Current Balance: ₹${customer.balance.abs().toStringAsFixed(0)} ${customer.balance >= 0 ? 'due' : 'advance'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: customer.balance >= 0
                                        ? AppTheme.creditColor
                                        : AppTheme.debitColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Transaction Type Selection
                  Text(
                    'Transaction Type',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          type: TransactionType.credit,
                          icon: Icons.arrow_downward_rounded,
                          label: 'Credit',
                          subtitle: 'Money received',
                          color: AppTheme.creditColor,
                          gradient: AppTheme.creditGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeButton(
                          type: TransactionType.debit,
                          icon: Icons.arrow_upward_rounded,
                          label: 'Debit',
                          subtitle: 'Money given',
                          color: AppTheme.debitColor,
                          gradient: AppTheme.debitGradient,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount Field
                  CustomTextField(
                    label: 'Amount',
                    hint: 'Enter amount',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: Icons.currency_rupee,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description Field
                  CustomTextField(
                    label: 'Description (Optional)',
                    hint: 'What is this transaction for?',
                    controller: _descriptionController,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // SMS Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _sendSms
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.sms_outlined,
                            color: _sendSms
                                ? AppTheme.primaryColor
                                : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send SMS Notification',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Customer will receive transaction details via SMS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _sendSms,
                          onChanged: (value) =>
                              setState(() => _sendSms = value),
                          activeThumbColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Quick Amount Buttons
                  Text(
                    'Quick Amounts',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [100, 500, 1000, 2000, 5000, 10000].map((amount) {
                      return ActionChip(
                        label: Text('₹$amount'),
                        labelStyle: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                        ),
                        backgroundColor: AppTheme.cardColor,
                        onPressed: () {
                          _amountController.text = amount.toString();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: 'Save Transaction',
                      isLoading: _isLoading,
                      gradient: _selectedType == TransactionType.credit
                          ? AppTheme.creditGradient
                          : AppTheme.debitGradient,
                      onPressed: _saveTransaction,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeButton({
    required TransactionType type,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Gradient gradient,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
