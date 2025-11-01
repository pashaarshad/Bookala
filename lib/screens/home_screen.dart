import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_sms/flutter_sms.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> phoneNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers();
  }

  Future<void> _loadPhoneNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? numbersJson = prefs.getString('phone_numbers');
    if (numbersJson != null) {
      setState(() {
        phoneNumbers = List<String>.from(json.decode(numbersJson));
      });
    }
  }

  Future<void> _savePhoneNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_numbers', json.encode(phoneNumbers));
  }

  void _addPhoneNumber(String number) {
    if (number.isNotEmpty && !phoneNumbers.contains(number)) {
      setState(() {
        phoneNumbers.add(number);
      });
      _savePhoneNumbers();
    }
  }

  void _deletePhoneNumber(int index) {
    setState(() {
      phoneNumbers.removeAt(index);
    });
    _savePhoneNumbers();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      ContactsPage(
        phoneNumbers: phoneNumbers,
        onAdd: _addPhoneNumber,
        onDelete: _deletePhoneNumber,
      ),
      SendSMSPage(phoneNumbers: phoneNumbers),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk SMS Sender'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages.elementAt(_selectedIndex),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddContactDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Send SMS',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            prefixText: '+',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addPhoneNumber(phoneController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  final List<String> phoneNumbers;
  final Function(String) onAdd;
  final Function(int) onDelete;

  const ContactsPage({
    super.key,
    required this.phoneNumbers,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: Text('${widget.phoneNumbers.length} contacts saved'),
              subtitle: const Text('Tap + to add new contact'),
            ),
          ),
        ),
        Expanded(
          child: widget.phoneNumbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts,
                        size: 100,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No contacts yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap the + button to add contacts',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.phoneNumbers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          widget.phoneNumbers[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Contact'),
                                content: const Text(
                                  'Are you sure you want to delete this contact?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      widget.onDelete(index);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SendSMSPage extends StatefulWidget {
  final List<String> phoneNumbers;

  const SendSMSPage({super.key, required this.phoneNumbers});

  @override
  State<SendSMSPage> createState() => _SendSMSPageState();
}

class _SendSMSPageState extends State<SendSMSPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendBulkSMS() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    if (widget.phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts available')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      String message = _messageController.text.trim();
      List<String> recipients = widget.phoneNumbers;

      String result = await sendSMS(
        message: message,
        recipients: recipients,
        sendDirect: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS sent to ${recipients.length} contacts!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: Text('Recipients: ${widget.phoneNumbers.length}'),
              subtitle: widget.phoneNumbers.isEmpty
                  ? const Text('Add contacts first')
                  : Text(widget.phoneNumbers.join(', ')),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 8,
            maxLength: 160,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendBulkSMS,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending ? 'Sending...' : 'Send to All Contacts',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
