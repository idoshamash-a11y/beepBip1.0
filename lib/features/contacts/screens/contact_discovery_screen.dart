import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ContactDiscoveryScreen extends StatefulWidget {
  const ContactDiscoveryScreen({super.key});

  @override
  State<ContactDiscoveryScreen> createState() => _ContactDiscoveryScreenState();
}

class _ContactDiscoveryScreenState extends State<ContactDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_NearbyUser> _nearbyUsers = [
    _NearbyUser(id: '1', name: 'Rivera M.', distance: '180m', avatar: 'https://picsum.photos/seed/Rivera/150/150', isOnline: true, mutualConnections: 3),
    _NearbyUser(id: '2', name: 'Sasha K.', distance: '420m', avatar: 'https://picsum.photos/seed/Sasha/150/150', isOnline: true, mutualConnections: 1),
    _NearbyUser(id: '3', name: 'Zara P.', distance: '610m', avatar: 'https://picsum.photos/seed/Zara/150/150', isOnline: false, mutualConnections: 0),
    _NearbyUser(id: '4', name: 'Dani T.', distance: '0.9km', avatar: 'https://picsum.photos/seed/Dani/150/150', isOnline: false, mutualConnections: 5),
    _NearbyUser(id: '5', name: 'Arlo V.', distance: '1.2km', avatar: 'https://picsum.photos/seed/Arlo/150/150', isOnline: true, mutualConnections: 2),
  ];

  final Set<String> _connected = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_NearbyUser> get _filtered {
    if (_searchQuery.isEmpty) return _nearbyUsers;
    return _nearbyUsers.where((u) =>
        u.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Discover People',
            style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: c.border),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2.5,
                labelColor: AppColors.accent,
                unselectedLabelColor: c.textSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
                tabs: const [Tab(text: 'Nearby'), Tab(text: 'By Phone'), Tab(text: 'By Email')],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: c.inputBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: c.textPrimary),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                  prefixIcon: Icon(Icons.search, color: c.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNearbyTab(c),
                _buildPhoneTab(c),
                _buildEmailTab(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab(AppColors c) {
    final users = _filtered;
    if (users.isEmpty) {
      return Center(child: Text('No users found nearby',
          style: GoogleFonts.outfit(color: c.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      separatorBuilder: (_, __) => Divider(color: c.divider, height: 1),
      itemBuilder: (context, i) => _UserTile(user: users[i], c: c,
          isConnected: _connected.contains(users[i].id),
          onConnect: () => setState(() => _connected.add(users[i].id))),
    );
  }

  Widget _buildPhoneTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.phone_android_rounded, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Find by phone number',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Enter a phone number to find someone on BEEPBIP',
              style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: c.inputBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              style: GoogleFonts.outfit(color: c.textPrimary),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+1 (555) 000-0000',
                hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.accent, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Search',
                  style: GoogleFonts.outfit(color: c.bg, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.contacts_outlined, color: AppColors.accent, size: 18),
            label: Text('Import from Contacts',
                style: GoogleFonts.outfit(color: AppColors.accent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.email_outlined, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Find by email',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Enter an email address to find someone on BEEPBIP',
              style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: c.inputBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              style: GoogleFonts.outfit(color: c.textPrimary),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@example.com',
                hintStyle: GoogleFonts.outfit(color: c.textSecondary),
                prefixIcon: const Icon(Icons.email_rounded, color: AppColors.accent, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Search',
                  style: GoogleFonts.outfit(color: c.bg, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _NearbyUser user;
  final AppColors c;
  final bool isConnected;
  final VoidCallback onConnect;
  const _UserTile({required this.user, required this.c, required this.isConnected, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Stack(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border)),
            child: ClipOval(
              child: Image.network(user.avatar, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: c.surface2,
                      child: Center(child: Text(user.name[0],
                          style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold))))),
            ),
          ),
          if (user.isOnline)
            Positioned(
              bottom: 1, right: 1,
              child: Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle,
                  border: Border.all(color: c.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(user.name,
          style: GoogleFonts.outfit(color: c.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 13),
            const SizedBox(width: 2),
            Text(user.distance, style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12)),
          ]),
          if (user.mutualConnections > 0)
            Text('${user.mutualConnections} mutual connection${user.mutualConnections > 1 ? 's' : ''}',
                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 11)),
        ],
      ),
      trailing: isConnected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Text('Connected', style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12)),
            )
          : GestureDetector(
              onTap: onConnect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.accent, borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Connect',
                    style: GoogleFonts.outfit(
                        color: c.bg, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
    );
  }
}

class _NearbyUser {
  final String id, name, distance, avatar;
  final bool isOnline;
  final int mutualConnections;
  const _NearbyUser({required this.id, required this.name, required this.distance,
      required this.avatar, required this.isOnline, required this.mutualConnections});
}
