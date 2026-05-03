import 'dart:typed_data';

import 'package:beepbip/core/services/watermark_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Helper: build a solid-color test image and encode it to PNG bytes so we can
/// feed it through the watermark pipeline.
Uint8List _solidPng({
  required int width,
  required int height,
  int r = 200,
  int g = 200,
  int b = 200,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('WatermarkService', () {
    const service = WatermarkService();

    test('returns input unchanged when serialId is empty', () async {
      final input = _solidPng(width: 200, height: 200);
      final out = await service.apply(input, serialId: '');
      expect(out, equals(input));
    });

    test('produces decodable JPEG bytes', () async {
      final input = _solidPng(width: 800, height: 600);
      final out = await service.apply(input, serialId: 'BP-A1B2C3');

      final decoded = img.decodeImage(out);
      expect(decoded, isNotNull,
          reason: 'Output must be decodable as a raster image.');
      expect(out.length, greaterThan(0));
    });

    test('preserves dimensions when below the maxLongEdge limit', () async {
      final input = _solidPng(width: 800, height: 600);
      final out = await service.apply(input, serialId: 'BP-A1B2C3');

      final decoded = img.decodeImage(out)!;
      expect(decoded.width, 800);
      expect(decoded.height, 600);
    });

    test('downscales when long edge exceeds maxLongEdge', () async {
      const tight = WatermarkService(maxLongEdge: 256);
      final input = _solidPng(width: 1024, height: 512);
      final out = await tight.apply(input, serialId: 'BP-A1B2C3');

      final decoded = img.decodeImage(out)!;
      expect(decoded.width, 256);
      expect(decoded.height, 128, reason: 'aspect ratio must be preserved');
    });

    test('mutates the bottom-right pixels (visible watermark drawn there)',
        () async {
      // Use a uniform mid-grey so any pixel that changes can only be the
      // watermark.
      final input = _solidPng(width: 400, height: 400, r: 128, g: 128, b: 128);
      final out = await service.apply(input, serialId: 'BP-XYZ123');

      final decoded = img.decodeImage(out)!;

      // Sample a pixel inside the bottom-right region where the pill sits.
      final brPixel = decoded.getPixel(decoded.width - 20, decoded.height - 20);
      // Sample a pixel in the top-left, well away from the watermark.
      final tlPixel = decoded.getPixel(20, 20);

      bool sameRgb(img.Pixel a, img.Pixel b) {
        return a.r == b.r && a.g == b.g && a.b == b.b;
      }

      expect(sameRgb(brPixel, tlPixel), isFalse,
          reason:
              'Bottom-right region should differ from background after stamping.');
    });

    test('throws FormatException on undecodable input', () async {
      final junk = Uint8List.fromList(List<int>.filled(32, 0));
      expect(
        () => service.apply(junk, serialId: 'BP-A1B2C3'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
