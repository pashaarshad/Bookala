class AppConstants {
  // App Info
  static const String appName = 'Bookala';
  static const String appTagline = 'Smart Account Management';
  static const String appVersion = '1.0.0';

  // Geofence Settings
  static const double defaultGeofenceRadius = 100.0; // meters
  static const double minGeofenceRadius = 50.0;
  static const double maxGeofenceRadius = 500.0;

  // Location Settings
  static const int locationUpdateInterval = 5000; // milliseconds
  static const int locationDistanceFilter = 10; // meters

  // SMS Template
  static const String smsTemplate = '''
From Bookala:
Dear {{customerName}},

Transaction Update:
Type: {{type}}
Amount: ₹{{amount}}
Date: {{date}}

Current Balance: ₹{{balance}}
{{balanceStatus}}

Thank you for your business!
- {{businessName}}
''';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String customersCollection = 'customers';
  static const String transactionsCollection = 'transactions';

  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefBusinessName = 'business_name';
  static const String prefAutoLocation = 'auto_location';
  static const String prefSendSms = 'send_sms';
  static const String prefOfflineMode = 'offline_mode';

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
}
