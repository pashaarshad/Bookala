import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  // Check and request contacts permission
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.contacts.status;

    if (status.isDenied) {
      final result = await Permission.contacts.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // Pick a contact from the phone's contact list
  Future<ContactInfo?> pickContact() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      // Request full contact access
      final contact = await FlutterContacts.openExternalPick();

      if (contact == null) return null;

      // Get full contact details
      final fullContact = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: false,
      );

      if (fullContact == null) return null;

      // Extract name and phone
      String name = fullContact.displayName;
      String phone = '';

      if (fullContact.phones.isNotEmpty) {
        phone = fullContact.phones.first.number;
      }

      return ContactInfo(name: name, phone: phone);
    } catch (e) {
      print('Error picking contact: $e');
      return null;
    }
  }

  // Get all contacts
  Future<List<ContactInfo>> getAllContacts() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return [];

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      return contacts
          .where((c) => c.phones.isNotEmpty)
          .map(
            (c) =>
                ContactInfo(name: c.displayName, phone: c.phones.first.number),
          )
          .toList();
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  // Search contacts by name
  Future<List<ContactInfo>> searchContacts(String query) async {
    if (query.isEmpty) return [];

    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return [];

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final lowercaseQuery = query.toLowerCase();

      return contacts
          .where(
            (c) =>
                c.displayName.toLowerCase().contains(lowercaseQuery) &&
                c.phones.isNotEmpty,
          )
          .map(
            (c) =>
                ContactInfo(name: c.displayName, phone: c.phones.first.number),
          )
          .toList();
    } catch (e) {
      print('Error searching contacts: $e');
      return [];
    }
  }
}

// Simple class to hold contact info
class ContactInfo {
  final String name;
  final String phone;

  ContactInfo({required this.name, required this.phone});
}
