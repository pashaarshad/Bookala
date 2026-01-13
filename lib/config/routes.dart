import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/customers/nearby_customers_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String customerList = '/customers';
  static const String customerDetail = '/customer-detail';
  static const String addCustomer = '/add-customer';
  static const String nearbyCustomers = '/nearby-customers';
  static const String addTransaction = '/add-transaction';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen());
      case home:
        return _buildRoute(const HomeScreen());
      case customerList:
        return _buildRoute(const CustomerListScreen());
      case customerDetail:
        final customerId = settings.arguments as String;
        return _buildRoute(CustomerDetailScreen(customerId: customerId));
      case addCustomer:
        return _buildRoute(const AddCustomerScreen());
      case nearbyCustomers:
        return _buildRoute(const NearbyCustomersScreen());
      case addTransaction:
        final customerId = settings.arguments as String;
        return _buildRoute(AddTransactionScreen(customerId: customerId));
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());
      default:
        return _buildRoute(const LoginScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
