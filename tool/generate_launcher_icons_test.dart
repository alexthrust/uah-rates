import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _background = Color(0xFF0B7A6F);
const _coin = Color(0xFFF4FBF9);

const _legacySizes = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

void main() {
  testWidgets('generate legacy launcher icons', (tester) async {
    await tester.runAsync(() async {
      for (final entry in _legacySizes.entries) {
        final file = File('android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png');
        await file.writeAsBytes(await _render(entry.value));
      }
      await File('tool/icon_preview.png').writeAsBytes(await _render(512));
    });
  });
}

Future<List<int>> _render(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final scale = size / 72;
  canvas
    ..scale(scale)
    ..translate(-18, -18);
  _paintIcon(canvas);
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void _paintIcon(Canvas canvas) {
  const center = Offset(54, 54);
  canvas.drawCircle(center, 36, Paint()..color = _background);
  canvas.drawCircle(center, 25, Paint()..color = _coin);
  canvas.drawCircle(
    center,
    21.5,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _background.withValues(alpha: 0.25),
  );

  final glyph = Path()
    ..moveTo(44, 45)
    ..cubicTo(44, 41, 48, 39, 54, 39)
    ..cubicTo(60, 39, 64, 41.5, 64, 45.5)
    ..cubicTo(64, 50, 59, 52, 54, 54)
    ..cubicTo(49, 56, 44, 58, 44, 62.5)
    ..cubicTo(44, 66.5, 48, 69, 54, 69)
    ..cubicTo(60, 69, 64, 67, 64, 63);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..color = _background
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  canvas.drawPath(glyph, stroke..strokeWidth = 5);
  stroke.strokeWidth = 3.6;
  canvas.drawLine(const Offset(41, 51), const Offset(67, 51), stroke);
  canvas.drawLine(const Offset(41, 57.5), const Offset(67, 57.5), stroke);
}
