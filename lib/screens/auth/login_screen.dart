import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Google...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (!success && mounted) {
        final error = authProvider.errorMessage ?? 'Sign in failed';
        setState(() {
          _statusMessage = error;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAsDemo() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Logging in as Demo User...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInAsDemo();
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                children: [
                  _buildLogo()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 24),
                  Text(
                        'Bookala',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = AppTheme.primaryGradient.createShader(
                              const Rect.fromLTWH(0, 0, 200, 70),
                            ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Account Management',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  const SizedBox(height: 48),
                  ..._buildFeatures(),
                  const SizedBox(height: 48),

                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.inter(
                          color:
                              _statusMessage.contains('Error') ||
                                  _statusMessage.contains('failed')
                              ? AppTheme.debitColor
                              : AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(),
                    ),

                  // Google Sign In Button
                  _buildGoogleButton()
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 600.ms)
                      .slideY(begin: 0.5, end: 0),
                  const SizedBox(height: 16),
                  // Demo Login Button
                  _buildDemoButton()
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 600.ms)
                      .slideY(begin: 0.5, end: 0),
                  const SizedBox(height: 24),
                  Text(
                    'Sign in with Google to sync your data across devices',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildFeatures() {
    final features = [
      ('📍', 'Location-Based Activation'),
      ('💰', 'Track Credits & Debits'),
      ('📱', 'Automatic SMS Notifications'),
      ('☁️', 'Cloud Sync & Backup'),
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;

      return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(feature.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  feature.$2,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: (500 + index * 100).ms, duration: 400.ms)
          .slideX(begin: -0.2, end: 0);
    }).toList();
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: 'Continue with Google',
        icon: Icons.g_mobiledata_rounded,
        isLoading: _isLoading,
        onPressed: _signInWithGoogle,
      ),
    );
  }

  Widget _buildDemoButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInAsDemo,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Demo Mode (Offline)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
      ),
    );
  }
}
