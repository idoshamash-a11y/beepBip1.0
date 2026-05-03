import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Burns a user's `serial_id` (e.g. `BP-A1B2C3`) into the bottom-right corner
/// of a raster image so that ownership survives screenshots, downloads, and
/// re-uploads.
///
/// The watermark is intentionally subtle but unambiguous: a small rounded
/// dark pill containing the serial id in light text, sized relative to the
/// image's shorter edge so it scales gracefully from thumbnails to full-res.
///
/// This service is pure and synchronous in spirit (the API is async only to
/// keep room for off-thread isolates later) — feed it bytes, get watermarked
/// bytes back. No I/O, no network, no plugin channels.
class WatermarkService {
  const WatermarkService({
    this.jpegQuality = 85,
    this.maxLongEdge = 2048,
  });

  /// Output JPEG quality (0-100). 85 is a sane default for user photos.
  final int jpegQuality;

  /// Downscale so the long edge is at most this many pixels. Keeps uploads
  /// fast and storage cheap; users rarely benefit from 12 MP listing photos.
  final int maxLongEdge;

  /// Decode [input], draw the watermark, return JPEG-encoded bytes.
  ///
  /// Returns the input unchanged if [serialId] is empty (defensive — callers
  /// should always pass a real id, but a missing watermark is better than a
  /// failed upload).
  Future<Uint8List> apply(
    Uint8List input, {
    required String serialId,
  }) async {
    if (serialId.trim().isEmpty) return input;

    final decoded = img.decodeImage(input);
    if (decoded == null) {
      throw const FormatException(
        'WatermarkService: could not decode image bytes.',
      );
    }

    final resized = _maybeResize(decoded);
    final stamped = _drawWatermark(resized, serialId.trim());

    return Uint8List.fromList(
      img.encodeJpg(stamped, quality: jpegQuality),
    );
  }

  img.Image _maybeResize(img.Image src) {
    final longEdge = src.width >= src.height ? src.width : src.height;
    if (longEdge <= maxLongEdge) return src;

    if (src.width >= src.height) {
      return img.copyResize(
        src,
        width: maxLongEdge,
        interpolation: img.Interpolation.linear,
      );
    }
    return img.copyResize(
      src,
      height: maxLongEdge,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _drawWatermark(img.Image src, String text) {
    // Pick a font sized roughly to the image. The `image` package ships a
    // handful of built-in bitmap fonts; we step up as the image gets larger.
    final shortEdge = src.width <= src.height ? src.width : src.height;
    final font = _fontFor(shortEdge);

    // Measure the rendered text. The bitmap fonts expose a uniform character
    // width via `lineHeight` so we approximate width as glyph-count * size/2.
    // This is a tiny over-estimate, which is fine for padding.
    final glyphHeight = font.lineHeight;
    final glyphWidth = (glyphHeight * 0.55).round();
    final textWidth = (text.length * glyphWidth).clamp(1, src.width);
    final textHeight = glyphHeight;

    final padX = (shortEdge * 0.02).round().clamp(6, 32);
    final padY = (shortEdge * 0.015).round().clamp(4, 24);

    final pillWidth = textWidth + padX * 2;
    final pillHeight = textHeight + padY * 2;
    final marginX = (shortEdge * 0.025).round().clamp(8, 40);
    final marginY = marginX;

    final pillX = src.width - pillWidth - marginX;
    final pillY = src.height - pillHeight - marginY;

    // Semi-transparent dark backdrop so the text reads on busy photos.
    img.fillRect(
      src,
      x1: pillX,
      y1: pillY,
      x2: pillX + pillWidth,
      y2: pillY + pillHeight,
      color: img.ColorRgba8(0, 0, 0, 140),
    );

    img.drawString(
      src,
      text,
      font: font,
      x: pillX + padX,
      y: pillY + padY,
      color: img.ColorRgba8(255, 255, 255, 235),
    );

    return src;
  }

  img.BitmapFont _fontFor(int shortEdge) {
    if (shortEdge >= 1600) return img.arial48;
    if (shortEdge >= 900) return img.arial24;
    if (shortEdge >= 500) return img.arial14;
    return img.arial14;
  }
}
