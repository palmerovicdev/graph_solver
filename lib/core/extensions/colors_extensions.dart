import 'dart:ui';

extension ColorExtension on Color {
  Color withOpacityOnWhite(double opacity) {
    assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

    int channel255(double component) =>
        (component * 255.0).round().clamp(0, 255);

    final r0 = channel255(this.r);
    final g0 = channel255(this.g);
    final b0 = channel255(this.b);

    final r = ((r0 * opacity) + (255 * (1 - opacity))).round().clamp(0, 255);
    final g = ((g0 * opacity) + (255 * (1 - opacity))).round().clamp(0, 255);
    final b = ((b0 * opacity) + (255 * (1 - opacity))).round().clamp(0, 255);

    return Color.fromRGBO(r, g, b, 1);
  }
}