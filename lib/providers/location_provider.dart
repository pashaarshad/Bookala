import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/customer.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  List<NearbyCustomer> _nearbyCustomers = [];
  bool _isLoading = false;
  bool _isTracking = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionSubscription;
  List<Customer> _allCustomers = [];

  // Getters
  Position? get currentPosition => _currentPosition;
  List<NearbyCustomer> get nearbyCustomers => _nearbyCustomers;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get hasNearbyCustomers => _nearbyCustomers.isNotEmpty;
  String? get errorMessage => _errorMessage;

  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  // Initialize location service
  Future<void> init() async {
    _hasLocationPermission = await _locationService.checkAndRequestPermission();
    notifyListeners();
  }

  // Update customers list (called from customer provider)
  void updateCustomers(List<Customer> customers) {
    _allCustomers = customers;
    if (_currentPosition != null) {
      _updateNearbyCustomers();
    }
  }

  // Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentPosition = await _locationService.getCurrentLocation();

      if (_currentPosition != null) {
        _updateNearbyCustomers();
      }

      _isLoading = false;
      notifyListeners();

      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Error getting location';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Start continuous location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _locationService.startLocationUpdates();

      _positionSubscription = _locationService.locationStream.listen(
        (position) {
          _currentPosition = position;
          _updateNearbyCustomers();
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Location tracking error';
          notifyListeners();
        },
      );

      _isTracking = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error starting location tracking';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    await _locationService.stopLocationUpdates();
    _isTracking = false;
    notifyListeners();
  }

  // Toggle tracking
  Future<void> toggleTracking() async {
    if (_isTracking) {
      await stopTracking();
    } else {
      await startTracking();
    }
  }

  // Refresh location and nearby customers
  Future<void> refresh() async {
    await getCurrentLocation();
  }

  // Update nearby customers based on current position
  void _updateNearbyCustomers() {
    if (_currentPosition == null || _allCustomers.isEmpty) {
      _nearbyCustomers = [];
      return;
    }

    _nearbyCustomers = _locationService.getNearbyCustomers(
      _allCustomers,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  // Get all customers with distance
  List<NearbyCustomer> getCustomersWithDistance() {
    if (_currentPosition == null) return [];

    return _locationService.getCustomersWithDistance(
      _allCustomers,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  // Calculate distance to a specific customer
  double? getDistanceToCustomer(Customer customer) {
    if (_currentPosition == null) return null;
    if (customer.latitude == 0 && customer.longitude == 0) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      customer.latitude,
      customer.longitude,
    );
  }

  // Format distance for display
  String formatDistance(double meters) {
    return _locationService.formatDistance(meters);
  }

  // Check if current position is within a customer's geofence
  bool isNearCustomer(Customer customer) {
    if (_currentPosition == null) return false;
    if (customer.latitude == 0 && customer.longitude == 0) return false;

    return _locationService.isWithinGeofence(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      customer.latitude,
      customer.longitude,
      customer.radius,
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
