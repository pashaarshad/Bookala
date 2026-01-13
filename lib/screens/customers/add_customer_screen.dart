import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/contact_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  final ContactService _contactService = ContactService();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _useCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentPosition != null && _useCurrentLocation) {
      setState(() {
        _latitude = locationProvider.currentPosition!.latitude;
        _longitude = locationProvider.currentPosition!.longitude;
      });
    }
  }

  Future<void> _pickContact() async {
    final contact = await _contactService.pickContact();
    if (contact != null) {
      setState(() {
        _nameController.text = contact.name;
        _phoneController.text = contact.phone;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );

      final customer = Customer(
        id: '',
        name: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        radius: double.tryParse(_radiusController.text) ?? 100.0,
        createdAt: DateTime.now(),
      );

      final id = await customerProvider.addCustomer(customer);

      if (id != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer added successfully'),
            backgroundColor: AppTheme.creditColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding customer'),
          backgroundColor: AppTheme.debitColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Import from Contacts Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: InkWell(
                  onTap: _pickContact,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contact_phone_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Import from Contacts',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Customer Details Section
              Text(
                'Customer Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Name',
                hint: 'Enter customer name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Shop Name',
                hint: 'Enter shop name (optional)',
                controller: _shopNameController,
                prefixIcon: Icons.store_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Location Section
              Text(
                'Location Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _latitude != null
                                ? AppTheme.creditColor.withValues(alpha: 0.2)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _latitude != null
                                ? Icons.location_on
                                : Icons.location_off_outlined,
                            color: _latitude != null
                                ? AppTheme.creditColor
                                : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _latitude != null
                                    ? 'Location Set'
                                    : 'No Location',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (_latitude != null && _longitude != null)
                                Text(
                                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _getCurrentLocation,
                          child: Text(
                            'Use Current',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detection Radius',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _radiusController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        suffixText: 'meters',
                                        suffixStyle: GoogleFonts.inter(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be notified when you are within this radius of the customer location',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Save Customer',
                  isLoading: _isLoading,
                  onPressed: _saveCustomer,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
