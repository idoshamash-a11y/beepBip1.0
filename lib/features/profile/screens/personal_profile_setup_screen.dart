import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/widgets/serial_id_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_enums.dart';
import '../providers/profile_provider.dart';

class PersonalProfileSetupScreen extends ConsumerStatefulWidget {
  const PersonalProfileSetupScreen({super.key});

  @override
  ConsumerState<PersonalProfileSetupScreen> createState() =>
      _PersonalProfileSetupScreenState();
}

class _PersonalProfileSetupScreenState
    extends ConsumerState<PersonalProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  /// Watermarked photo URL once the upload completes. Null until the user
  /// picks an image *and* the upload settles.
  String? _photoUrl;
  bool _photoUploading = false;
  final List<String> _selectedInterests = [];
  VisibilityStatus _visibilityStatus = VisibilityStatus.open;
  LocationSharing _locationSharing = LocationSharing.dontShare;

  // Local list — long-term these should come from `public.interests` so the
  // labels match the canonical taxonomy. Tracked in FOLLOWUPS as a V1.5 item.
  static const _availableInterests = <String>[
    'Sports',
    'Music',
    'Art',
    'Technology',
    'Food',
    'Travel',
    'Photography',
    'Gaming',
    'Reading',
    'Fitness',
    'Movies',
    'Cooking',
    'Fashion',
    'Nature',
    'Pets',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

    setState(() => _photoUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await ref.read(imageUploadServiceProvider).uploadUserImage(
            userId: user.id,
            serialId: profile.serialId,
            feature: ImageUploadFeature.profilePhotos,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for the photo upload to finish.')),
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
    final ok = await controller.setupPersonalProfile(
      userId: user.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text,
      bio: _bioController.text,
      interests: _selectedInterests,
      photoUrl: _photoUrl,
      visibilityStatus: _visibilityStatus,
      locationSharing: _locationSharing,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile created.')),
      );
      context.go('/home');
    } else {
      final error = ref.read(profileSetupControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not create your profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Profile Setup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null
                        ? (_photoUploading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : Icon(Icons.person,
                                size: 60, color: Colors.grey[600]))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _photoUploading ? null : _pickImage,
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
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
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                prefixIcon: Icon(Icons.info),
                hintText: 'Tell us about yourself',
              ),
            ),
            const SizedBox(height: 24),
            Text('Interests & Tags', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Privacy Settings', style: theme.textTheme.headlineMedium),
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
