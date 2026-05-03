export 'globe_embed_stub.dart'
  if (dart.library.html) 'globe_embed_web.dart'
  if (dart.library.io) 'globe_embed_io.dart';
