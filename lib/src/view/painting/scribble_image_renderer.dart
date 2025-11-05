import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:scribble/src/domain/model/sketch/sketch.dart';
import 'package:scribble/src/view/painting/scribble_painter.dart';

/// Renders the provided [sketch] to an offscreen image without relying on a
/// widget tree or an attached render object.
///
/// The resulting [ByteData] can be stored or converted into an
/// [Image.memory] widget in a consuming application.
Future<ByteData> renderSketchOffscreen({
  required Sketch sketch,
  required Size size,
  double scaleFactor = 1.0,
  bool simulatePressure = true,
  EdgeInsets padding = EdgeInsets.zero,
  ui.Color backgroundColor = const ui.Color(0x00000000),
  double pixelRatio = 1.0,
  ui.ImageByteFormat format = ui.ImageByteFormat.png,
}) async {
  if (size.width <= 0 || size.height <= 0) {
    throw ArgumentError.value(
      size,
      'size',
      'Width and height must be positive.',
    );
  }
  if (pixelRatio <= 0) {
    throw ArgumentError.value(
      pixelRatio,
      'pixelRatio',
      'Pixel ratio must be greater than zero.',
    );
  }

  final painter = ScribblePainter(
    sketch: sketch,
    scaleFactor: scaleFactor,
    simulatePressure: simulatePressure,
  );

  final totalWidth = size.width + padding.horizontal;
  final totalHeight = size.height + padding.vertical;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, totalWidth, totalHeight),
      ui.Paint()..color = backgroundColor,
    )
    ..translate(padding.left, padding.top);

  painter.paint(canvas, size);

  final picture = recorder.endRecording();
  final widthPx = math.max(1, (totalWidth * pixelRatio).round());
  final heightPx = math.max(1, (totalHeight * pixelRatio).round());
  final image = await picture.toImage(
    widthPx,
    heightPx,
  );
  final bytes = await image.toByteData(format: format);
  if (bytes == null) {
    throw StateError('Failed to encode scribble sketch to ByteData.');
  }
  return bytes;
}
