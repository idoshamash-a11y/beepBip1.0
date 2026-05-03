import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _hasSearched = false;

  final List<String> _recentSearches = ['coffee shop', 'events tonight', 'Rivera', 'tech meetup'];
  final List<String> _trendingHashtags = ['#nearby', '#events', '#foodie', '#tech', '#meetup', '#beepbip', '#lost', '#forsale'];

  final List<_Result> _mockPeople = [
    _Result(id: '1', title: 'Rivera M.', subtitle: '180m away · 3 mutual', avatar: 'https://picsum.photos/seed/Rivera/150/150', type: 'person'),
    _Result(id: '2', title: 'Sasha K.', subtitle: '420m away · 1 mutual', avatar: 'https://picsum.photos/seed/Sasha/150/150', type: 'person'),
  ];
  final List<_Result> _mockPosts = [
    _Result(id: '3', title: 'Free coffee at Corner Café', subtitle: '#foodie · 200m away · 5 min ago', avatar: '', type: 'post'),
    _Result(id: '4', title: 'Tech meetup tonight 7PM', subtitle: '#tech #events · 0.8km · 1 hr ago', avatar: '', type: 'post'),
    _Result(id: '5', title: 'Lost: Black wallet near Park St', subtitle: '#lost · 300m away · 2 hrs ago', avatar: '', type: 'post'),
  ];
  final List<_Result> _mockPlaces = [
    _Result(id: '6', title: 'Corner Café', subtitle: 'Coffee Shop · 200m away', avatar: '', type: 'place'),
    _Result(id: '7', title: 'Tech Hub Coworking', subtitle: 'Business · 0.8km away', avatar: '', type: 'place'),
  ];

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

  void _onSearch(String v) => setState(() { _query = v; _hasSearched = v.isNotEmpty; });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: c.inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15),
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search people, posts, places...',
                    hintStyle: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent, size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: c.textSecondary, size: 18),
                            onPressed: () { _searchController.clear(); _onSearch(''); },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            if (_hasSearched)
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2.5,
                labelColor: AppColors.accent,
                unselectedLabelColor: c.textSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
                tabs: const [Tab(text: 'People'), Tab(text: 'Posts'), Tab(text: 'Places')],
              ),
            Expanded(
              child: _hasSearched ? _buildResults(c) : _buildDiscover(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscover(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _BrowseListingsCard(onTap: () => context.push('/listings')),
          const SizedBox(height: 16),
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text('Clear', style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 13)),
                ),
              ],
            ),
            ..._recentSearches.map((term) => ListTile(
              contentPadding: EdgeInsets.zero, dense: true,
              leading: Icon(Icons.history_rounded, color: c.textSecondary, size: 18),
              title: Text(term, style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 14)),
              trailing: Icon(Icons.north_west_rounded, color: c.textSecondary, size: 14),
              onTap: () { _searchController.text = term; _onSearch(term); },
            )),
            const SizedBox(height: 8),
          ],
          Text('Trending Nearby',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _trendingHashtags.map((tag) => GestureDetector(
              onTap: () { _searchController.text = tag; _onSearch(tag); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Text(tag, style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 13)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('Explore',
              style: GoogleFonts.outfit(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.5,
            children: [
              _CategoryCard(icon: Icons.restaurant_rounded, label: 'Food & Drink', color: const Color(0xFFEF5350), c: c),
              _CategoryCard(icon: Icons.event_rounded, label: 'Events', color: const Color(0xFF7986CB), c: c),
              _CategoryCard(icon: Icons.shopping_bag_outlined, label: 'For Sale', color: const Color(0xFF66BB6A), c: c),
              _CategoryCard(icon: Icons.support_agent_rounded, label: 'Services', color: const Color(0xFF26A69A), c: c),
              _CategoryCard(icon: Icons.find_in_page_outlined, label: 'Lost & Found', color: const Color(0xFFFFCA28), c: c),
              _CategoryCard(icon: Icons.people_rounded, label: 'People', color: AppColors.accent, c: c),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildResults(AppColors c) {
    return TabBarView(
      controller: _tabController,
      children: [
        _ResultList(results: _mockPeople, query: _query, c: c),
        _ResultList(results: _mockPosts, query: _query, c: c),
        _ResultList(results: _mockPlaces, query: _query, c: c),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppColors c;
  const _CategoryCard({required this.icon, required this.label, required this.color, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<_Result> results;
  final String query;
  final AppColors c;
  const _ResultList({required this.results, required this.query, required this.c});

  @override
  Widget build(BuildContext context) {
    final filtered = results.where((r) =>
        r.title.toLowerCase().contains(query.toLowerCase()) ||
        r.subtitle.toLowerCase().contains(query.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: c.textSecondary, size: 44),
            const SizedBox(height: 10),
            Text('No results for "$query"',
                style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(color: c.divider, height: 1),
      itemBuilder: (context, i) {
        final r = filtered[i];
        Widget leading;
        if (r.type == 'person' && r.avatar.isNotEmpty) {
          leading = Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border)),
            child: ClipOval(child: Image.network(r.avatar, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: c.surface2,
                    child: Center(child: Text(r.title[0],
                        style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold)))))),
          );
        } else {
          leading = Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
            child: Icon(r.type == 'post' ? Icons.article_outlined : Icons.place_outlined,
                color: AppColors.accent, size: 22),
          );
        }
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: leading,
          title: Text(r.title,
              style: GoogleFonts.outfit(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(r.subtitle,
              style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 12)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 20),
        );
      },
    );
  }
}

class _Result {
  final String id, title, subtitle, avatar, type;
  const _Result({required this.id, required this.title, required this.subtitle, required this.avatar, required this.type});
}

/// Pinned hero card pointing into the listings vertical. Replaces the empty
/// "search but for nothing real" feel of this screen until we wire up the
/// proper full-text + hashtag search against `public.listings.search_vector`.
class _BrowseListingsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BrowseListingsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.18),
                AppColors.accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse listings in SoHo',
                      style: GoogleFonts.outfit(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Services, items and events from local businesses',
                      style: GoogleFonts.outfit(
                        color: c.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
