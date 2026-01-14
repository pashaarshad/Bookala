import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showNearbyAlert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh location when app is resumed
      _refreshLocation();
    }
  }

  Future<void> _initializeData() async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Await async init methods
    await customerProvider.init();
    await transactionProvider.init();
    await locationProvider.init();

    // Get initial location and check for nearby customers
    await _refreshLocation();
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

    // Update customers in location provider
    locationProvider.updateCustomers(customerProvider.allCustomers);

    // Get current location
    await locationProvider.getCurrentLocation();

    // Check for nearby customers
    if (locationProvider.hasNearbyCustomers && !_showNearbyAlert) {
      setState(() => _showNearbyAlert = true);
      _showNearbyCustomersDialog();
    }
  }

  void _showNearbyCustomersDialog() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.nearbyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: AppTheme.nearbyColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Nearby Customers',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are near ${locationProvider.nearbyCustomers.length} customer(s)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locationProvider.nearbyCustomers.length,
                  itemBuilder: (context, index) {
                    final nearbyCustomer =
                        locationProvider.nearbyCustomers[index];
                    return CustomerCard(
                      customer: nearbyCustomer.customer,
                      isNearby: true,
                      distanceText: locationProvider.formatDistance(
                        nearbyCustomer.distance,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.customerDetail,
                          arguments: nearbyCustomer.customer.id,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.nearbyCustomers);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'View All',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((_) {
      setState(() => _showNearbyAlert = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildDashboard(), _buildCustomersTab()],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDashboard() {
    return Consumer2<CustomerProvider, TransactionProvider>(
      builder: (context, customerProvider, transactionProvider, child) {
        return RefreshIndicator(
          onRefresh: _refreshLocation,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Balance Cards
                    _buildBalanceCards(customerProvider),
                    const SizedBox(height: 24),
                    // Location Status
                    _buildLocationStatus(),
                    const SizedBox(height: 24),
                    // Recent Transactions
                    _buildSectionHeader('Recent Transactions', () {}),
                    const SizedBox(height: 12),
                    if (transactionProvider.recentTransactions.isEmpty)
                      _buildEmptyState(
                        'No transactions yet',
                        'Add your first transaction',
                        Icons.receipt_long_outlined,
                      )
                    else
                      ...transactionProvider.recentTransactions
                          .take(5)
                          .map((t) => TransactionTile(transaction: t)),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${authProvider.userProfile?.name.split(' ').first ?? 'User'} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your accounts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        // Location refresh button
        Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            return IconButton(
              icon: Icon(
                locationProvider.isTracking
                    ? Icons.location_on
                    : Icons.location_off_outlined,
                color: locationProvider.isTracking
                    ? AppTheme.nearbyColor
                    : AppTheme.textMuted,
              ),
              onPressed: () async {
                if (locationProvider.isTracking) {
                  await locationProvider.stopTracking();
                } else {
                  await locationProvider.startTracking();
                }
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBalanceCards(CustomerProvider customerProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BalanceCard(
                title: 'Total To Receive',
                amount: customerProvider.totalCredit,
                icon: Icons.arrow_downward_rounded,
                gradient: AppTheme.creditGradient,
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  BalanceCard(
                        title: 'Total To Pay',
                        amount: customerProvider.totalDebit,
                        icon: Icons.arrow_upward_rounded,
                        gradient: AppTheme.debitGradient,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideX(begin: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${customerProvider.totalCustomers} Customers',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${customerProvider.totalBalance.abs().toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    customerProvider.totalBalance >= 0
                        ? 'You will receive'
                        : 'You need to pay',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (!locationProvider.hasLocationPermission) {
          return _buildLocationPermissionCard();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: locationProvider.hasNearbyCustomers
                  ? AppTheme.nearbyColor
                  : AppTheme.cardColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: locationProvider.hasNearbyCustomers
                      ? AppTheme.nearbyColor.withValues(alpha: 0.2)
                      : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  locationProvider.hasNearbyCustomers
                      ? Icons.location_on
                      : Icons.location_searching,
                  color: locationProvider.hasNearbyCustomers
                      ? AppTheme.nearbyColor
                      : AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationProvider.hasNearbyCustomers
                          ? '${locationProvider.nearbyCustomers.length} Nearby Customer(s)'
                          : 'No Nearby Customers',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationProvider.isTracking
                          ? 'Auto-detecting location'
                          : 'Tap refresh to update',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (locationProvider.hasNearbyCustomers)
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.nearbyCustomers),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.nearbyColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _refreshLocation,
                  icon: locationProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Icon(Icons.refresh, color: AppTheme.primaryColor),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
      },
    );
  }

  Widget _buildLocationPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.debitColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.debitColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_off,
              color: AppTheme.debitColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Permission Required',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable location for nearby detection',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final locationProvider = Provider.of<LocationProvider>(
                context,
                listen: false,
              );
              await locationProvider.init();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Enable',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            'View All',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Customers',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: customerProvider.setSearchQuery,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textMuted,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (customerProvider.customers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: _buildEmptyState(
                    'No customers yet',
                    'Add your first customer',
                    Icons.people_outline,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                  }, childCount: customerProvider.customers.length),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppTheme.surfaceColor,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(1, Icons.people_outline, Icons.people, 'Customers'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryColor : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isActive ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.addCustomer),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
