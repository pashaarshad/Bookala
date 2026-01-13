import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/customer_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/customer_card.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Customers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addCustomer),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (customerProvider.customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No customers yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first customer to get started',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.addCustomer),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: customerProvider.setSearchQuery,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name, shop, or phone...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: customerProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: customerProvider.clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
              // Customer List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customerProvider.customers.length,
                  itemBuilder: (context, index) {
                    final customer = customerProvider.customers[index];
                    final locationProvider = Provider.of<LocationProvider>(
                      context,
                      listen: false,
                    );
                    final isNearby = locationProvider.isNearCustomer(customer);
                    final distance = locationProvider.getDistanceToCustomer(
                      customer,
                    );

                    return CustomerCard(
                      customer: customer,
                      isNearby: isNearby,
                      distanceText: distance != null
                          ? locationProvider.formatDistance(distance)
                          : null,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.customerDetail,
                          arguments: customer.id,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
