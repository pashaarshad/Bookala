import 'dart:io';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class SmsService {
  static const platform = MethodChannel('com.bookala.bookala/sms');

  // Check and request SMS permission
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.sms.status;

    if (status.isDenied) {
      final result = await Permission.sms.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // Format SMS message from template
  String formatMessage({
    required String customerName,
    required String transactionType,
    required double amount,
    required DateTime date,
    required double currentBalance,
    required String businessName,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(date);

    String balanceStatus;
    if (currentBalance > 0) {
      balanceStatus = 'Amount Due: ₹${currentBalance.toStringAsFixed(2)}';
    } else if (currentBalance < 0) {
      balanceStatus = 'Advance: ₹${currentBalance.abs().toStringAsFixed(2)}';
    } else {
      balanceStatus = 'All dues cleared!';
    }

    return '''
From Bookala:
Dear $customerName,

Transaction Update:
Type: $transactionType
Amount: ₹${amount.toStringAsFixed(2)}
Date: $formattedDate

$balanceStatus

Thank you for your business!
- $businessName
''';
  }

  // Send SMS directly (requires SEND_SMS permission) - FULLY AUTOMATIC
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (Platform.isAndroid) {
        final hasPermission = await checkAndRequestPermission();
        if (!hasPermission) {
          // Permission denied - cannot send automatically
          debugPrint('SMS permission denied');
          return false;
        }

        // Try direct SMS using Native Channel - FULLY AUTOMATIC
        try {
          final String result = await platform.invokeMethod('sendSms', {
            'phone': cleanNumber,
            'message': message,
          });
          debugPrint('SMS sent automatically: $result');
          return result == 'sent';
        } catch (e) {
          debugPrint("Failed to send SMS natively: '$e'.");
          // Don't fall back to intent - just return false for automatic mode
          return false;
        }
      } else {
        // iOS doesn't support direct SMS
        debugPrint('iOS does not support automatic SMS');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  // Send SMS via intent (opens SMS app with pre-filled message)
  Future<bool> _sendSmsIntent(String phoneNumber, String message) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      final encodedMessage = Uri.encodeComponent(message);

      final Uri smsUri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening SMS app: $e');
      return false;
    }
  }

  // Open SMS app with pre-filled message (for user to tap send)
  Future<bool> openSmsApp({
    required String phoneNumber,
    required String message,
  }) async {
    return await _sendSmsIntent(phoneNumber, message);
  }

  // Send transaction notification SMS
  Future<bool> sendTransactionSms({
    required Customer customer,
    required CustomerTransaction transaction,
    required String businessName,
  }) async {
    final message = formatMessage(
      customerName: customer.name,
      transactionType: transaction.type == TransactionType.credit
          ? 'Credit'
          : 'Debit',
      amount: transaction.amount,
      date: transaction.date,
      currentBalance:
          customer.balance +
          (transaction.type == TransactionType.credit
              ? transaction.amount
              : -transaction.amount),
      businessName: businessName.isNotEmpty ? businessName : 'Bookala',
    );

    return await sendSms(phoneNumber: customer.phone, message: message);
  }

  // Clean phone number (remove spaces, dashes, etc.)
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Add country code if not present (assuming India)
    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        cleaned = '+91$cleaned';
      }
    }

    return cleaned;
  }
}
