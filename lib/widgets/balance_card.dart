import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Gradient gradient;
  final String? subtitle;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get text theme (which uses Merriweather/Lato)
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
