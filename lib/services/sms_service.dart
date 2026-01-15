import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class SmsService {
  static const platform = MethodChannel('com.bookala.bookala/sms');

  // Check SMS permission status
  Future<PermissionStatus> checkPermissionStatus() async {
    return await Permission.sms.status;
  }

  // Request SMS permission
  Future<bool> requestPermission() async {
    final status = await Permission.sms.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.sms.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      // Open app settings so user can manually enable
      debugPrint('SMS permission permanently denied, opening settings...');
      await openAppSettings();
      return false;
    }

    return false;
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

  // Send SMS - tries automatic first, falls back to SMS app
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (Platform.isAndroid) {
        // First check permission
        final status = await Permission.sms.status;

        if (status.isGranted) {
          // Try direct SMS using Native Channel
          try {
            final String result = await platform.invokeMethod('sendSms', {
              'phone': cleanNumber,
              'message': message,
            });
            debugPrint('SMS sent automatically: $result');
            if (result == 'sent') {
              return true;
            }
          } catch (e) {
            debugPrint("Native SMS failed: '$e'. Falling back to SMS app.");
          }
        }

        // Fallback: Open SMS app with pre-filled message
        debugPrint('Opening SMS app as fallback...');
        return await openSmsApp(phoneNumber: cleanNumber, message: message);
      } else {
        // iOS - always use SMS app
        return await openSmsApp(phoneNumber: phoneNumber, message: message);
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  // Open SMS app with pre-filled message (user taps send)
  Future<bool> openSmsApp({
    required String phoneNumber,
    required String message,
  }) async {
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
      debugPrint('Error opening SMS app: $e');
      return false;
    }
  }

  // Send transaction SMS
  Future<bool> sendTransactionSms({
    required Customer customer,
    required CustomerTransaction transaction,
    required String businessName,
  }) async {
    final message = formatMessage(
      customerName: customer.name,
      transactionType: transaction.type == TransactionType.credit
          ? 'Credit (You gave)'
          : 'Debit (You received)',
      amount: transaction.amount,
      date: transaction.date,
      currentBalance: customer.balance,
      businessName: businessName,
    );

    return await sendSms(phoneNumber: customer.phone, message: message);
  }

  // Send reminder SMS
  Future<bool> sendReminderSms({
    required Customer customer,
    required String businessName,
  }) async {
    final message =
        '''
From Bookala:
Dear ${customer.name},

This is a friendly reminder that you have an outstanding balance of ₹${customer.balance.toStringAsFixed(2)}.

Please clear your dues at your earliest convenience.

Thank you!
- $businessName
''';

    return await sendSms(phoneNumber: customer.phone, message: message);
  }

  // Clean phone number
  String _cleanPhoneNumber(String phone) {
    // Remove all non-numeric characters except + at the start
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it doesn't start with +, add India code
    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        cleaned = '+91$cleaned';
      }
    }

    return cleaned;
  }
}
