import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_enums.dart';
import '../models/business_hours_model.dart';
import '../services/profile_service.dart';
import '../../auth/providers/auth_provider.dart';

class BusinessProfileSetupScreen extends ConsumerStatefulWidget {
  const BusinessProfileSetupScreen({super.key});

  @override
  ConsumerState<BusinessProfileSetupScreen> createState() =>
      _BusinessProfileSetupScreenState();
}

class _BusinessProfileSetupScreenState
    extends ConsumerState<BusinessProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _logoPath;
  List<String> _selectedServices = [];
  VisibilityStatus _visibilityStatus = VisibilityStatus.open;
  LocationSharing _locationSharing = LocationSharing.visibleWithLocation;
  bool _isLoading = false;

  final List<String> _availableServices = [
    'Delivery',
    'Pickup',
    'Dine-in',
    'Consultation',
    'Online Service',
    'Installation',
    'Repair',
    'Maintenance',
    'Custom Orders',
    'Reservations',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user == null) throw Exception('User not authenticated');

      final profileService = ProfileService();

      // Create profile with premium subscription (required for business)
      final profile = await profileService.createProfile(
        userId: user.id,
        profileType: ProfileType.business,
        subscriptionTier: SubscriptionTier.premium,
      );

      // Create business profile
      await profileService.createBusinessProfile(
        profileId: profile.id,
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        services: _selectedServices,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        // TODO: Upload logo to Supabase Storage
        // logoUrl: uploadedLogoUrl,
      );

      // Update profile settings
      await profileService.updateProfile(
        profileId: profile.id,
        visibilityStatus: _visibilityStatus,
        locationSharing: _locationSharing,
        isProfileComplete: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile created successfully!')),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile Setup'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _logoPath == null
                        ? Icon(Icons.business, size: 60, color: Colors.grey[600])
                        : null,
                    // TODO: Display selected logo
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickLogo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                prefixIcon: Icon(Icons.category),
                hintText: 'e.g., Restaurant, Retail, Service',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe your business',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                prefixIcon: Icon(Icons.language),
                hintText: 'https://yourwebsite.com',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Services Offered',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableServices.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Visibility Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Profile Visibility'),
                    subtitle: Text(_visibilityStatus.description),
                    trailing: DropdownButton<VisibilityStatus>(
                      value: _visibilityStatus,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _visibilityStatus = value;
                          });
                        }
                      },
                      items: VisibilityStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.displayName),
                              ))
                          .toList(),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Location Sharing'),
                    subtitle: Text(_locationSharing.description),
                    trailing: DropdownButton<LocationSharing>(
                      value: _locationSharing,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _locationSharing = value;
                          });
                        }
                      },
                      items: LocationSharing.values
                          .map((sharing) => DropdownMenuItem(
                                value: sharing,
                                child: Text(sharing.displayName),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Business profiles require a Premium subscription',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
