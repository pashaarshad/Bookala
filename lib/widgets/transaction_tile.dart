import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final CustomerTransaction transaction;
  final String? customerName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.customerName,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.type == TransactionType.credit;
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon - Cleaner look
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        (isCredit ? AppTheme.creditColor : AppTheme.debitColor)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (isCredit
                                  ? AppTheme.creditColor
                                  : AppTheme.debitColor)
                              .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isCredit
                        ? AppTheme.creditColor
                        : AppTheme.debitColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCredit ? 'Payment Received' : 'Credit Given',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (transaction.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (customerName != null && customerName!.isNotEmpty)
                        Text(
                          customerName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dateFormat.format(transaction.date)} • ${timeFormat.format(transaction.date)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (transaction.smsSent) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 12,
                              color: AppTheme.successColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Amount
                Text(
                  '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCredit
                        ? AppTheme.creditColor
                        : AppTheme.debitColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
