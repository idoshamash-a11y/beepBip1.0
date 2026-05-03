import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/widgets/serial_id_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_enums.dart';
import '../providers/profile_provider.dart';

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

  /// Watermarked logo URL once the upload completes.
  String? _logoUrl;
  bool _logoUploading = false;
  final List<String> _selectedServices = [];
  VisibilityStatus _visibilityStatus = VisibilityStatus.open;
  LocationSharing _locationSharing = LocationSharing.visibleWithLocation;

  static const _availableServices = <String>[
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
    final user = ref.read(authStateProvider).asData?.value;
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (user == null || profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Your session is still loading. Try again in a moment.'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (image == null) return;

    setState(() => _logoUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await ref.read(imageUploadServiceProvider).uploadUserImage(
            userId: user.id,
            serialId: profile.serialId,
            feature: ImageUploadFeature.businessLogos,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() => _logoUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload logo. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _logoUploading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_logoUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for the logo upload to finish.')),
      );
      return;
    }

    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your session expired. Please sign in again.')),
      );
      context.go('/login');
      return;
    }

    final controller = ref.read(profileSetupControllerProvider.notifier);
    final ok = await controller.setupBusinessProfile(
      userId: user.id,
      businessName: _businessNameController.text.trim(),
      logoUrl: _logoUrl,
      description: _descriptionController.text,
      category: _categoryController.text,
      services: _selectedServices,
      website: _websiteController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      visibilityStatus: _visibilityStatus,
      locationSharing: _locationSharing,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile created.')),
      );
      context.go('/home');
    } else {
      final error = ref.read(profileSetupControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not create your business profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile Setup')),
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      image: _logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _logoUrl != null
                        ? null
                        : (_logoUploading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : Icon(Icons.business,
                                size: 60, color: Colors.grey[600])),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _logoUploading ? null : _pickLogo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SerialIdChip(
                serialId: ref
                    .watch(currentUserProfileProvider)
                    .asData
                    ?.value
                    ?.serialId,
                snackbarLabel: 'Your serial id was copied',
              ),
            ),
            const SizedBox(height: 24),
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
            Text('Services Offered', style: theme.textTheme.headlineMedium),
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
            Text('Visibility Settings', style: theme.textTheme.headlineMedium),
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
                          setState(() => _visibilityStatus = value);
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
                          setState(() => _locationSharing = value);
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
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Business profiles require a Premium subscription',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state.isLoading ? null : _handleSubmit,
              child: state.isLoading
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
