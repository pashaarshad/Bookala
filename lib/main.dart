import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BulkSMSApp());
}

class BulkSMSApp extends StatelessWidget {
  const BulkSMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bulk SMS Sender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
