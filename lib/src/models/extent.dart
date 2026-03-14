import 'dart:math' as math;

abstract interface class ExtentMeasurable {
  bool get isMeasured;

  void reset();
  Extent acceptMeasurement(double measuredPixels);

  (double, double) get range;
}

/// A class representing the extent of a row or column in a table grid.
/// Only [Extent.range] supports resizing.
/// Other extents are fixed and do not change during resizing.
sealed class Extent implements ExtentMeasurable {
  const Extent();

  const factory Extent.fixed(double pixels) = _FixedExtent;
  const factory Extent.range({
    double? min,
    double? max,
    required double pixels,
  }) = _RangeExtent;

  factory Extent.auto({
    double? min,
    double? max,
  }) = AutoExtent;

  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  });

  Extent accept(double delta);

  @override
  bool get isMeasured => true;

  @override
  Extent acceptMeasurement(double measuredPixels) => this;

  @override
  void reset() {}

  /// Designed for [AutoExtent],
  /// as [AutoExtent] will be updated in-place after measurement,
  /// so we need to clone it when assigning to ensure the default extent is not affected by the measurement.
  Extent clone();
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

  @override
  (double, double) get range => (pixels, pixels);

  @override
  Extent clone() => _FixedExtent(pixels);

  @override
  int get hashCode => pixels.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FixedExtent &&
          runtimeType == other.runtimeType &&
          pixels == other.pixels;

  @override
  String toString() {
    return "_FixedExtent(pixels: $pixels)";
  }
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

  @override
  (double, double) get range => (min ?? pixels, max ?? pixels);

  @override
  Extent clone() => _RangeExtent(min: min, max: max, pixels: pixels);

  @override
  int get hashCode => Object.hash(min, max, pixels);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RangeExtent &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max &&
          pixels == other.pixels;

  @override
  String toString() {
    return "_RangeExtent(min: $min, max: $max, pixels: $pixels)";
  }
}

final class AutoExtent extends Extent {
  final double? min;
  final double? max;

  AutoExtent({
    this.min,
    this.max,
  })  : assert(min == null || min >= 0),
        assert(max == null || max >= 0);

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    final pixels = _measuredPixels ?? 0;

    if (!pinned) {
      return pixels;
    }

    final allowed = math.min(pixels, remainingSpace);
    return allowed >= 0 ? allowed : 0;
  }

  @override
  Extent accept(double delta) {
    if (_measuredPixels != null) {
      final newPixels = _measuredPixels! + delta;

      final accepted =
          newPixels >= (min ?? 0) && newPixels <= (max ?? double.infinity);

      if (accepted) {
        _measuredPixels = newPixels;
      }
    }

    return this; // No change if not measured yet or outside the range
  }

  @override
  (double, double) get range => (
        _measuredPixels ?? (min ?? 0),
        _measuredPixels ?? (max ?? double.infinity)
      );

  double? _measuredPixels;

  @override
  bool get isMeasured => _measuredPixels != null;

  @override
  Extent acceptMeasurement(double measuredPixels) {
    if (min != null && measuredPixels < min!) {
      _measuredPixels = min!;
    } else if (max != null && measuredPixels > max!) {
      _measuredPixels = max!;
    } else {
      _measuredPixels = measuredPixels;
    }

    return this;
  }

  @override
  void reset() {
    _measuredPixels = null;
  }

  @override
  Extent clone() {
    return AutoExtent(min: min, max: max);
  }

  @override
  int get hashCode => Object.hash(min, max, _measuredPixels);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoExtent &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max &&
          _measuredPixels == other._measuredPixels;

  @override
  String toString() {
    return "AutoExtent(min: $min, max: $max, measuredPixels: $_measuredPixels)";
  }
}
