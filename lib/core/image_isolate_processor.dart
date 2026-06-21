import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// Data class to pass arguments to the Isolate
class IsolateData {
  final List<PlaneData> planes;
  final int width;
  final int height;
  final int rotation; // Sensor orientation
  final CameraLensDirection lensDirection;
  final ImageFormatGroup formatGroup;
  final List<List<int>> faceCoordinates; // [left, top, width, height]
  final int targetWidth;
  final int targetHeight;

  IsolateData({
    required this.planes,
    required this.width,
    required this.height,
    required this.rotation,
    required this.lensDirection,
    required this.formatGroup,
    required this.faceCoordinates,
    required this.targetWidth,
    required this.targetHeight,
  });
}

/// Helper class to copy plane data since Plane objects are not sending across Isolates easily
class PlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;

  PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
  });

  factory PlaneData.fromPlane(Plane plane) {
    return PlaneData(
      bytes: Uint8List.fromList(plane.bytes),
      bytesPerRow: plane.bytesPerRow,
      bytesPerPixel: plane.bytesPerPixel,
    );
  }
}

class ImageIsolateProcessor {
  /// Entry point for the Isolate
  static Future<List<img.Image>> process(IsolateData data) async {
    return await compute(_processInternal, data);
  }

  static List<img.Image> _processInternal(IsolateData data) {
    try {
      // ─────────────────────────────────────────────────────────────────────
      // STEP 1: Convert the FULL raw buffer → RGB image
      // ─────────────────────────────────────────────────────────────────────
      // We convert the full frame first, then crop.
      // The old approach tried to crop in raw space first using _mapRectToRaw(),
      // then rotate the crop — but MLKit already returns bounding boxes in
      // "upright" (rotated) space, so applying _mapRectToRaw was a double
      // transformation that produced wrong crop regions.
      img.Image fullImage;
      if (data.formatGroup == ImageFormatGroup.yuv420 ||
          data.formatGroup == ImageFormatGroup.nv21) {
        fullImage = _convertYUV420Full(data.planes, data.width, data.height);
      } else if (data.formatGroup == ImageFormatGroup.bgra8888) {
        fullImage = _convertBGRAFull(data.planes, data.width, data.height);
      } else {
        debugPrint("Isolate: Unsupported format ${data.formatGroup}");
        return [];
      }

      // ─────────────────────────────────────────────────────────────────────
      // STEP 2: Rotate the full image to "upright" orientation
      // ─────────────────────────────────────────────────────────────────────
      // The raw camera buffer is rotated relative to the screen. After this
      // step the image has the same orientation that MLKit used when it
      // produced the bounding boxes, so we can crop directly.
      img.Image uprightImage = img.copyRotate(fullImage, angle: data.rotation);

      // ─────────────────────────────────────────────────────────────────────
      // STEP 3: Mirror for front camera
      // ─────────────────────────────────────────────────────────────────────
      // MLKit already accounts for the front camera mirror, so we match that
      // here so that the crop coordinates align exactly.
      if (data.lensDirection == CameraLensDirection.front) {
        uprightImage = img.flipHorizontal(uprightImage);
      }

      // ─────────────────────────────────────────────────────────────────────
      // STEP 4: Crop each face directly from the upright image, then resize
      // ─────────────────────────────────────────────────────────────────────
      final List<img.Image> results = [];

      for (var coords in data.faceCoordinates) {
        // coords = [left, top, width, height] in upright/MLKit space
        final int l = coords[0].clamp(0, uprightImage.width - 1);
        final int t = coords[1].clamp(0, uprightImage.height - 1);
        final int w = coords[2].clamp(1, uprightImage.width - l);
        final int h = coords[3].clamp(1, uprightImage.height - t);

        final img.Image faceCrop = img.copyCrop(
          uprightImage,
          x: l,
          y: t,
          width: w,
          height: h,
        );

        // Resize to model input dimensions.
        // Linear (bilinear) interpolation matches the default behaviour of
        // cv2.resize() and PIL.Image.resize() used during training.
        final img.Image resized = img.copyResize(
          faceCrop,
          width: data.targetWidth,
          height: data.targetHeight,
          interpolation: img.Interpolation.linear,
        );

        results.add(resized);
      }

      return results;
    } catch (e) {
      debugPrint("Isolate Error: $e");
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Full-frame YUV420 → RGB conversion
  // ──────────────────────────────────────────────────────────────────────────
  static img.Image _convertYUV420Full(
    List<PlaneData> planes,
    int width,
    int height,
  ) {
    final img.Image image = img.Image(width: width, height: height);

    final int uvRowStride = planes[1].bytesPerRow;
    final int uvPixelStride = planes[1].bytesPerPixel ?? 1;

    final Uint8List yBytes = planes[0].bytes;
    final Uint8List uBytes = planes[1].bytes;
    final Uint8List vBytes = planes[2].bytes;

    for (int y = 0; y < height; y++) {
      final int yOffset = y * planes[0].bytesPerRow;
      final int uvYOffset = (y >> 1) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int yIndex = yOffset + x;
        final int uvIndex = uvYOffset + (x >> 1) * uvPixelStride;

        final int yp = yBytes[yIndex];
        final int up = uBytes[uvIndex];
        final int vp = vBytes[uvIndex];

        final int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        final int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        final int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Full-frame BGRA8888 → RGB conversion (iOS)
  // ──────────────────────────────────────────────────────────────────────────
  static img.Image _convertBGRAFull(
    List<PlaneData> planes,
    int width,
    int height,
  ) {
    final img.Image image = img.Image(width: width, height: height);
    final Uint8List bytes = planes[0].bytes;
    final int bytesPerRow = planes[0].bytesPerRow;

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * bytesPerRow;
      for (int x = 0; x < width; x++) {
        final int pixelOffset = rowOffset + x * 4;
        final int b = bytes[pixelOffset];
        final int g = bytes[pixelOffset + 1];
        final int r = bytes[pixelOffset + 2];
        final int a = bytes[pixelOffset + 3];
        image.setPixelRgba(x, y, r, g, b, a);
      }
    }
    return image;
  }
}
