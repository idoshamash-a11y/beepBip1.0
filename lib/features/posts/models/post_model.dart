import 'package:latlong2/latlong.dart';

class PostModel {
  final String id;
  final String text;
  final List<String> hashtags;
  final String category;
  final bool isPublic;
  final bool hasLocation;
  final LatLng? location;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.text,
    required this.hashtags,
    required this.category,
    required this.isPublic,
    required this.hasLocation,
    this.location,
    required this.createdAt,
  });
}
