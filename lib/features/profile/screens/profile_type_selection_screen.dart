import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/profile_enums.dart';

class ProfileTypeSelectionScreen extends ConsumerStatefulWidget {
  const ProfileTypeSelectionScreen({super.key});

  @override
  ConsumerState<ProfileTypeSelectionScreen> createState() =>
      _ProfileTypeSelectionScreenState();
}

class _ProfileTypeSelectionScreenState
    extends ConsumerState<ProfileTypeSelectionScreen> {
  ProfileType? _selectedType;

  void _handleContinue() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile type')),
      );
      return;
    }

    if (_selectedType == ProfileType.personal) {
      context.go('/setup/personal');
    } else {
      context.go('/setup/business');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Choose Your Profile Type',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select how you want to use BEEPBIP',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProfileTypeCard(
                        icon: Icons.person,
                        title: 'Personal Profile',
                        description:
                            'Connect with people around you. Share your interests and discover others nearby.',
                        features: const [
                          'Free & Premium tiers',
                          'Share interests & hobbies',
                          'Control privacy settings',
                          'Meet new people',
                        ],
                        isSelected: _selectedType == ProfileType.personal,
                        onTap: () {
                          setState(() {
                            _selectedType = ProfileType.personal;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _ProfileTypeCard(
                        icon: Icons.business,
                        title: 'Business Profile',
                        description:
                            'Promote your business and reach customers in your area. Premium only.',
                        features: const [
                          'Premium tier required',
                          'Multiple locations',
                          'Business hours & services',
                          'Reach local customers',
                        ],
                        isSelected: _selectedType == ProfileType.business,
                        onTap: () {
                          setState(() {
                            _selectedType = ProfileType.business;
                          });
                        },
                        isPremiumOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedType == null ? null : _handleContinue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPremiumOnly;

  const _ProfileTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.onTap,
    this.isPremiumOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (isPremiumOnly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
