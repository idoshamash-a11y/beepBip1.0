import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_enums.dart';
import '../services/profile_service.dart';
import '../../auth/providers/auth_provider.dart';

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

  String? _photoPath;
  List<String> _selectedInterests = [];
  VisibilityStatus _visibilityStatus = VisibilityStatus.open;
  LocationSharing _locationSharing = LocationSharing.dontShare;
  bool _isLoading = false;

  final List<String> _availableInterests = [
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
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _photoPath = image.path;
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

      // Create profile
      final profile = await profileService.createProfile(
        userId: user.id,
        profileType: ProfileType.personal,
      );

      // Create personal profile
      await profileService.createPersonalProfile(
        profileId: profile.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        interests: _selectedInterests,
        // TODO: Upload photo to Supabase Storage
        // photoUrl: uploadedPhotoUrl,
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
        const SnackBar(content: Text('Profile created successfully!')),
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
        title: const Text('Personal Profile Setup'),
      ),
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
                    child: _photoPath == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                        : null,
                    // TODO: Display selected image
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
            Text(
              'Interests & Tags',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
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
            Text(
              'Privacy Settings',
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
