import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final String? distanceText;
  final bool isNearby;
  final bool showLocationIndicator;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.distanceText,
    this.isNearby = false,
    this.showLocationIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNearby
              ? AppTheme.nearbyColor
              : Colors.white.withValues(alpha: 0.05),
          width: isNearby ? 1.5 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar - Simple and Elegant
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNearby) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppTheme.nearbyColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.shopName.isNotEmpty
                                  ? customer.shopName
                                  : 'No shop name',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(height: 2),
                        Text(distanceText!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),

                // Balance - Right aligned
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${customer.balance.abs().toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        color: customer.balance >= 0
                            ? AppTheme.creditColor
                            : AppTheme.debitColor,
                      ),
                    ),
                    Text(
                      (customer.balance > 0
                              ? 'Receive'
                              : customer.balance < 0
                              ? 'Pay'
                              : 'Settled')
                          .toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
