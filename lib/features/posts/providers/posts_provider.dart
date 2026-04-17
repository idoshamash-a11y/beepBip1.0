import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../models/post_model.dart';

final postsProvider =
    StateNotifierProvider<PostsNotifier, List<PostModel>>((ref) {
  return PostsNotifier();
});

class PostsNotifier extends StateNotifier<List<PostModel>> {
  PostsNotifier() : super([]);

  void addPost({
    required String text,
    required List<String> hashtags,
    required String category,
    required bool isPublic,
    required bool hasLocation,
    LatLng? location,
  }) {
    final post = PostModel(
      id: const Uuid().v4(),
      text: text,
      hashtags: hashtags,
      category: category,
      isPublic: isPublic,
      hasLocation: hasLocation,
      location: location,
      createdAt: DateTime.now(),
    );
    state = [post, ...state];
  }

  void removePost(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}
