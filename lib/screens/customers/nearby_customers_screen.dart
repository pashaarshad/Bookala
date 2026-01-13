import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/customer_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/customer_card.dart';

class NearbyCustomersScreen extends StatefulWidget {
  const NearbyCustomersScreen({super.key});

  @override
  State<NearbyCustomersScreen> createState() => _NearbyCustomersScreenState();
}

class _NearbyCustomersScreenState extends State<NearbyCustomersScreen> {
  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );

    locationProvider.updateCustomers(customerProvider.allCustomers);
    await locationProvider.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Customers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return IconButton(
                icon: locationProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _refreshLocation,
              );
            },
          ),
        ],
      ),
      body: Consumer2<LocationProvider, CustomerProvider>(
        builder: (context, locationProvider, customerProvider, child) {
          if (locationProvider.isLoading &&
              locationProvider.currentPosition == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (!locationProvider.hasLocationPermission) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 64,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location Permission Required',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable location permission to detect nearby customers',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await locationProvider.init();
                        if (locationProvider.hasLocationPermission) {
                          _refreshLocation();
                        }
                      },
                      child: const Text('Enable Location'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (locationProvider.currentPosition == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_searching,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to get location',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure location services are enabled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshLocation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final nearbyCustomers = locationProvider.nearbyCustomers;
          final otherCustomers = locationProvider
              .getCustomersWithDistance()
              .where((nc) => !nc.isNearby)
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshLocation,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                // Current Location Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Location',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '${locationProvider.latitude?.toStringAsFixed(4)}, ${locationProvider.longitude?.toStringAsFixed(4)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _refreshLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ),
                // Nearby Customers Section
                if (nearbyCustomers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.nearbyColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.nearbyColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nearby (${nearbyCustomers.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.nearbyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final nearbyCustomer = nearbyCustomers[index];
                        return CustomerCard(
                          customer: nearbyCustomer.customer,
                          isNearby: true,
                          distanceText: locationProvider.formatDistance(
                            nearbyCustomer.distance,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.customerDetail,
                              arguments: nearbyCustomer.customer.id,
                            );
                          },
                        ).animate().fadeIn(
                          duration: 300.ms,
                          delay: (index * 100).ms,
                        );
                      }, childCount: nearbyCustomers.length),
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Nearby Customers',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Move closer to a customer location or expand their radius',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ),
                ],
                // Other Customers Section
                if (otherCustomers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Other Customers',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final nearbyCustomer = otherCustomers[index];
                        return CustomerCard(
                          customer: nearbyCustomer.customer,
                          distanceText: locationProvider.formatDistance(
                            nearbyCustomer.distance,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.customerDetail,
                              arguments: nearbyCustomer.customer.id,
                            );
                          },
                        );
                      }, childCount: otherCustomers.length),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }
}
