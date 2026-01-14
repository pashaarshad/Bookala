import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/transaction_tile.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    customerProvider.selectCustomer(widget.customerId);
    transactionProvider.listenToCustomerTransactions(widget.customerId);
  }

  @override
  void dispose() {
    Provider.of<CustomerProvider>(
      context,
      listen: false,
    ).clearSelectedCustomer();
    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).stopListeningToCustomer();
    super.dispose();
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _messageCustomer(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Delete Customer',
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this customer and all their transactions? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final customerProvider = Provider.of<CustomerProvider>(
                context,
                listen: false,
              );
              await customerProvider.deleteCustomer(widget.customerId);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.debitColor,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CustomerProvider, TransactionProvider>(
      builder: (context, customerProvider, transactionProvider, child) {
        final customer = customerProvider.selectedCustomer;

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final locationProvider = Provider.of<LocationProvider>(
          context,
          listen: false,
        );
        final distance = locationProvider.getDistanceToCustomer(customer);
        final isNearby = locationProvider.isNearCustomer(customer);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              customer.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (customer.shopName.isNotEmpty)
                              Text(
                                customer.shopName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            if (isNearby) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.nearbyColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Nearby • ${locationProvider.formatDistance(distance!)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: AppTheme.surfaceColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Navigate to edit screen
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: AppTheme.debitColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                color: AppTheme.debitColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            _showDeleteConfirmation,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Contact Actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone,
                            label: 'Call',
                            color: AppTheme.creditColor,
                            onTap: () => _callCustomer(customer.phone),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.message,
                            label: 'Message',
                            color: AppTheme.primaryColor,
                            onTap: () => _messageCustomer(customer.phone),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),
                    // Balance Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            'Total Credit',
                            '₹${customer.totalCredit.toStringAsFixed(0)}',
                            AppTheme.creditColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniCard(
                            'Total Debit',
                            '₹${customer.totalDebit.toStringAsFixed(0)}',
                            AppTheme.debitColor,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    const SizedBox(height: 12),
                    // Balance Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: customer.balance >= 0
                            ? AppTheme.creditGradient
                            : AppTheme.debitGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (customer.balance >= 0
                                        ? AppTheme.creditColor
                                        : AppTheme.debitColor)
                                    .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${customer.balance.abs().toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                customer.balance >= 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                                size: 32,
                              ),
                              Text(
                                customer.balance > 0
                                    ? 'To Receive'
                                    : customer.balance < 0
                                    ? 'To Pay'
                                    : 'Settled',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                    const SizedBox(height: 24),
                    // Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${transactionProvider.transactions.length} entries',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Transactions List
                    if (transactionProvider.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions yet',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...transactionProvider.transactions.map(
                        (t) => TransactionTile(
                          transaction: t,
                          onLongPress: () => _showDeleteTransactionDialog(t),
                        ),
                      ),
                    const SizedBox(height: 80), // Space for FAB
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.addTransaction,
                arguments: widget.customerId,
              );
            },
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Transaction',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final transactionProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              await transactionProvider.deleteTransaction(transaction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.debitColor,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
