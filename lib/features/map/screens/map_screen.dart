import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../posts/providers/posts_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  double _radius = 2.0;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  late AnimationController _bottomSheetController;
  late Animation<Offset> _bottomSlide;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<_NearbyPin> _nearbyPins = [
    _NearbyPin(lat: 40.7148, lng: -74.0038, name: 'Rivera M.', distance: '180m'),
    _NearbyPin(lat: 40.7108, lng: -74.0078, name: 'Sasha K.', distance: '420m'),
    _NearbyPin(lat: 40.7148, lng: -74.0100, name: 'Zara P.', distance: '610m'),
  ];

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bottomSheetController, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _determinePosition();
    Future.delayed(const Duration(milliseconds: 400),
        () => _bottomSheetController.forward());
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = context.isDark;
    final posts = ref.watch(postsProvider);
    final center = _currentLocation ?? const LatLng(40.7128, -74.0060);

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14.0,
                minZoom: 2.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.beepbip.app',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      // User location pulse
                      Marker(
                        point: _currentLocation!,
                        width: 56,
                        height: 56,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: (1 - _pulseAnim.value) * 0.5,
                                child: Container(
                                  width: 48 * _pulseAnim.value,
                                  height: 48 * _pulseAnim.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                              Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Nearby people
                      ..._nearbyPins.map((pin) => Marker(
                        point: LatLng(pin.lat, pin.lng),
                        width: 44, height: 44,
                        child: _UserPin(name: pin.name),
                      )),
                      // Posts from the feed
                      ...posts.where((p) => p.hasLocation).map((post) {
                        final offset = posts.indexOf(post);
                        final postLat = (_currentLocation?.latitude ?? 40.7128) + (offset * 0.003);
                        final postLng = (_currentLocation?.longitude ?? -74.0060) + (offset * 0.002);
                        return Marker(
                          point: LatLng(postLat, postLng),
                          width: 140, height: 58,
                          child: _PostPin(post: post),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Top search bar
                Positioned(
                  top: 12, left: 16, right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.surface.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                blurRadius: 16, offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: c.textSecondary, size: 20),
                              const SizedBox(width: 10),
                              Text('Search places or people...',
                                  style: GoogleFonts.outfit(color: c.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MapBtn(icon: Icons.notifications_none_rounded, surfaceColor: c.surface, borderColor: c.border, isDark: isDark, onTap: () {}),
                    ],
                  ),
                ),

                // Zoom controls
                Positioned(
                  right: 16, top: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      children: [
                        _ZoomBtn(icon: Icons.add_rounded, textColor: c.textPrimary,
                            onTap: () => _mapController.move(
                                _mapController.camera.center, _mapController.camera.zoom + 1)),
                        Container(height: 1, width: 28, color: c.border),
                        _ZoomBtn(icon: Icons.remove_rounded, textColor: c.textPrimary,
                            onTap: () => _mapController.move(
                                _mapController.camera.center, _mapController.camera.zoom - 1)),
                      ],
                    ),
                  ),
                ),

                // Locate button
                Positioned(
                  right: 16, top: 160,
                  child: _MapBtn(
                    icon: Icons.my_location_rounded,
                    surfaceColor: AppColors.accent,
                    borderColor: Colors.transparent,
                    isDark: isDark,
                    isAccent: true,
                    onTap: _determinePosition,
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: _bottomSlide,
              child: _BottomSheet(
                radius: _radius,
                nearbyCount: _nearbyPins.length,
                postCount: posts.length,
                pins: _nearbyPins,
                surfaceColor: c.overlay,
                borderColor: c.border,
                textPrimary: c.textPrimary,
                textSecondary: c.textSecondary,
                onRadiusChanged: (v) => setState(() => _radius = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _PostPin extends StatelessWidget {
  final dynamic post;
  const _PostPin({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.article_outlined, color: AppColors.accent, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  post.text.length > 20 ? '${post.text.substring(0, 20)}…' : post.text,
                  style: GoogleFonts.outfit(
                    color: context.colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 2, height: 6,
          color: AppColors.accent.withValues(alpha: 0.6),
        ),
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _UserPin extends StatelessWidget {
  final String name;
  const _UserPin({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: ClipOval(
            child: Image.network(
              'https://picsum.photos/seed/$name/80/80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: context.colors.surface2,
                child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 18),
              ),
            ),
          ),
        ),
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: AppColors.accent, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

class _MapBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;
  final bool isDark;
  final bool isAccent;
  const _MapBtn({
    required this.icon, required this.onTap,
    required this.surfaceColor, required this.borderColor, required this.isDark,
    this.isAccent = false,
  });

  @override
  State<_MapBtn> createState() => _MapBtnState();
}

class _MapBtnState extends State<_MapBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.1),
                blurRadius: 12, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(widget.icon,
            color: widget.isAccent ? const Color(0xFF0D0D0D) : context.colors.textPrimary,
            size: 22),
        ),
      ),
    );
  }
}

class _ZoomBtn extends StatefulWidget {
  final IconData icon;
  final Color textColor;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.textColor, required this.onTap});

  @override
  State<_ZoomBtn> createState() => _ZoomBtnState();
}

class _ZoomBtnState extends State<_ZoomBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 44, height: 44,
        color: _pressed ? context.colors.surface2 : Colors.transparent,
        child: Icon(widget.icon, color: widget.textColor, size: 20),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final double radius;
  final int nearbyCount;
  final int postCount;
  final List<_NearbyPin> pins;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<double> onRadiusChanged;

  const _BottomSheet({
    required this.radius, required this.nearbyCount, required this.postCount,
    required this.pins, required this.surfaceColor, required this.borderColor,
    required this.textPrimary, required this.textSecondary, required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nearby',
                            style: GoogleFonts.outfit(
                                color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('$nearbyCount people · $postCount posts within ${radius.toStringAsFixed(1)} km',
                            style: GoogleFonts.outfit(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text('Live',
                              style: GoogleFonts.outfit(
                                  color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Nearby avatars
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      ...pins.map((pin) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'https://picsum.photos/seed/${pin.name}/80/80',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: context.colors.surface2,
                                    child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(pin.distance,
                                style: GoogleFonts.outfit(color: textSecondary, fontSize: 9)),
                          ],
                        ),
                      )),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/contacts'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surface2,
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(Icons.add_rounded, color: textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('Radius', style: GoogleFonts.outfit(color: textSecondary, fontSize: 13)),
                    const Spacer(),
                    Text('${radius.toStringAsFixed(1)} km',
                        style: GoogleFonts.outfit(
                            color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: borderColor,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.12),
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(value: radius, min: 0.5, max: 10.0, onChanged: onRadiusChanged),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.5 km', style: GoogleFonts.outfit(color: textSecondary, fontSize: 11)),
                    Text('10 km', style: GoogleFonts.outfit(color: textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _NearbyPin {
  final double lat, lng;
  final String name, distance;
  const _NearbyPin({required this.lat, required this.lng, required this.name, required this.distance});
}
