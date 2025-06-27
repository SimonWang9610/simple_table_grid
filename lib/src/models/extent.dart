import 'dart:math' as math;

/// A class representing the extent of a row or column in a table grid.
/// Only [Extent.range] supports resizing.
/// Other extents are fixed and do not change during resizing.
sealed class Extent {
  const Extent();

  const factory Extent.fixed(double pixels) = _FixedExtent;
  const factory Extent.range({
    double? min,
    double? max,
    required double pixels,
  }) = _RangeExtent;
  // const factory Extent.fractional(double fraction) = _FractionalExtent;
  // const factory Extent.remaining() = _RemainingExtent;

  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  });

  Extent accept(double delta);
}

final class _FixedExtent extends Extent {
  final double pixels;

  const _FixedExtent(this.pixels);

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    if (!pinned) {
      return pixels;
    }

    final allowed = math.min(pixels, remainingSpace);
    return allowed >= 0 ? allowed : 0;
  }

  @override
  Extent accept(double delta) => this;
}

// ignore: unused_element
final class _FractionalExtent extends Extent {
  final double fraction;

  const _FractionalExtent(this.fraction);

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    final double pixels = fraction * viewportExtent;

    if (!pinned) {
      return pixels;
    }

    final double allowed = math.min(pixels, remainingSpace);

    return allowed >= 0 ? allowed : 0;
  }

  @override
  Extent accept(double delta) => this;
}

// ignore: unused_element
final class _RemainingExtent extends Extent {
  const _RemainingExtent();

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    return remainingSpace > 0 ? remainingSpace : 0;
  }

  @override
  Extent accept(double delta) => this;
}

final class _RangeExtent extends Extent {
  final double? min;
  final double? max;
  final double pixels;

  const _RangeExtent({
    this.min,
    this.max,
    required this.pixels,
  })  : assert(min == null || min >= 0),
        assert(max == null || max >= 0),
        assert(pixels >= 0),
        assert((pixels >= (min ?? 0)) && (pixels <= (max ?? double.infinity)),
            'pixels must be within the range defined by min and max');

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    if (!pinned) {
      return _insidePixels;
    }

    final allowed = math.min(_insidePixels, remainingSpace);
    return allowed >= 0 ? allowed : 0;
  }

  double get _insidePixels {
    if (min != null && pixels < min!) {
      return min!;
    } else if (max != null && pixels > max!) {
      return max!;
    }
    return pixels;
  }

  @override
  Extent accept(double delta) {
    final newPixels = _insidePixels + delta;

    final accepted =
        newPixels >= (min ?? 0) && newPixels <= (max ?? double.infinity);

    if (accepted && newPixels != pixels) {
      // print('Range extent accepted: $newPixels');
      return _RangeExtent(min: min, max: max, pixels: newPixels);
    } else {
      return this; // No change if outside the range
    }
  }
}
