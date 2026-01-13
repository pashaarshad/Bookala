import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/customer.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  // Stream of location updates
  Stream<Position> get locationStream => _locationController.stream;

  // Current position getter
  Position? get currentPosition => _currentPosition;

  // Check if location services are enabled and request permission
  Future<bool> checkAndRequestPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await openAppSettings();
      return false;
    }

    return true;
  }

  // Get current location (one-time fetch)
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return _currentPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Start continuous location updates
  Future<void> startLocationUpdates() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return;

      // Cancel existing subscription
      await stopLocationUpdates();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
            },
            onError: (error) {
              print('Location stream error: $error');
            },
          );
    } catch (e) {
      print('Error starting location updates: $e');
    }
  }

  // Stop location updates
  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if user is within customer's geofence
  bool isWithinGeofence(
    double userLat,
    double userLon,
    double customerLat,
    double customerLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      userLat,
      userLon,
      customerLat,
      customerLon,
    );
    return distance <= radiusInMeters;
  }

  // Get nearby customers based on current location
  List<NearbyCustomer> getNearbyCustomers(
    List<Customer> customers,
    double userLat,
    double userLon,
  ) {
    final nearbyCustomers = <NearbyCustomer>[];

    for (final customer in customers) {
      // Skip customers with no location set
      if (customer.latitude == 0 && customer.longitude == 0) continue;

      final distance = calculateDistance(
        userLat,
        userLon,
        customer.latitude,
        customer.longitude,
      );

      // Check if within customer's geofence radius
      if (distance <= customer.radius) {
        nearbyCustomers.add(
          NearbyCustomer(customer: customer, distance: distance),
        );
      }
    }

    // Sort by distance (nearest first)
    nearbyCustomers.sort((a, b) => a.distance.compareTo(b.distance));

    return nearbyCustomers;
  }

  // Get all customers with distance information (for display purposes)
  List<NearbyCustomer> getCustomersWithDistance(
    List<Customer> customers,
    double userLat,
    double userLon,
  ) {
    final customersWithDistance = <NearbyCustomer>[];

    for (final customer in customers) {
      double distance = double.infinity;

      // Calculate distance if location is set
      if (customer.latitude != 0 || customer.longitude != 0) {
        distance = calculateDistance(
          userLat,
          userLon,
          customer.latitude,
          customer.longitude,
        );
      }

      customersWithDistance.add(
        NearbyCustomer(customer: customer, distance: distance),
      );
    }

    // Sort by distance (nearest first)
    customersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

    return customersWithDistance;
  }

  // Format distance for display
  String formatDistance(double meters) {
    if (meters == double.infinity) {
      return 'Location not set';
    } else if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }
  }

  // Dispose resources
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
}

// Helper class to hold customer with distance info
class NearbyCustomer {
  final Customer customer;
  final double distance;

  NearbyCustomer({required this.customer, required this.distance});

  bool get isNearby => distance <= customer.radius;
}
