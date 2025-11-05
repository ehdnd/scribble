import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';
import 'package:scribble/src/view/painting/scribble_image_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Sketch buildSampleSketch() {
    const points = <Point>[
      Point(10, 10),
      Point(50, 30),
      Point(80, 60),
    ];
    return const Sketch(
      lines: [
        SketchLine(
          points: points,
          color: 0xFF123456,
          width: 4,
        ),
      ],
    );
  }

  Future<ui.Image> decodePng(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  test('renderSketchOffscreen renders sketch to requested size', () async {
    final sketch = buildSampleSketch();
    final bytes = await renderSketchOffscreen(
      sketch: sketch,
      size: const ui.Size(100, 80),
    );

    expect(bytes.lengthInBytes, greaterThan(0));
    final image = await decodePng(bytes.buffer.asUint8List());
    expect(image.width, 100);
    expect(image.height, 80);
  });

  test('renderSketchOffscreen respects padding and pixelRatio', () async {
    final sketch = buildSampleSketch();
    final bytes = await renderSketchOffscreen(
      sketch: sketch,
      size: const ui.Size(50, 40),
      padding: const EdgeInsets.all(10),
      pixelRatio: 2,
    );

    final image = await decodePng(bytes.buffer.asUint8List());
    expect(image.width, (50 + 20) * 2);
    expect(image.height, (40 + 20) * 2);
  });

  test('renderCurrentSketchOffscreen mirrors renderSketchOffscreen', () async {
    final sketch = buildSampleSketch();
    final notifier = ScribbleNotifier(sketch: sketch)..setScaleFactor(1.5);

    final fromNotifier = await notifier.renderCurrentSketchOffscreen(
      size: const ui.Size(120, 90),
      simulatePressure: false,
      pixelRatio: 1.5,
    );
    final fromUtility = await renderSketchOffscreen(
      sketch: notifier.value.sketch,
      size: const ui.Size(120, 90),
      scaleFactor: notifier.value.scaleFactor,
      simulatePressure: false,
      pixelRatio: 1.5,
    );

    expect(
      fromNotifier.buffer.asUint8List(),
      equals(fromUtility.buffer.asUint8List()),
    );
  });
}
