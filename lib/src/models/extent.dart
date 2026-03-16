import 'dart:math' as math;

abstract interface class ExtentMeasurable {
  /// If this extent has been measured with actual pixels.
  /// If false, [acceptMeasurement] will be called to set the measured pixels for this extent.
  bool get isMeasured;

  /// Reset the measured pixels to the initial state.
  /// If the extent has been given initial pixels, it will reset to the initial pixels;
  /// otherwise, it will reset to null, and the extent will be measured again when needed.
  void resetMeasurement();

  /// Set the measured pixels for this extent.
  /// This method will be called when the extent is measured with actual pixels.
  Extent acceptMeasurement(double measuredPixels);

  /// Get the layout range of this extent, which is a tuple of (min, max).
  /// It is mainly used to estimate the layout range of the row or column when we need to measure the extent of a cell
  /// but the extent of the corresponding row or column is not measured yet.
  (double, double) get range;
}

sealed class Extent implements ExtentMeasurable {
  const Extent();

  /// Create a fixed extent with the given pixels.
  ///
  /// If [pixels] is null, it will be treated as dynamically measured extent,
  /// which means [isMeasured] will be `false` until it is measured with actual pixels.
  ///
  /// Once [acceptMeasurement] is called, the measured pixels will be set for this extent
  /// until [reset] is called to reset the measured pixels to the initial state.
  factory Extent.fixed({double? pixels}) = _FixedExtent;

  /// Create a range extent with the given min, max and pixels.
  ///
  /// If [pixels] is null, it will be treated as dynamically measured extent,
  /// which means [isMeasured] will be `false` until it is measured with actual pixels.
  ///
  /// Once [acceptMeasurement] is called, the measured pixels will be set for this extent
  /// until [reset] is called to reset the measured pixels to the initial state.
  ///
  /// [min] and [max] are used to define the valid range that can be used to limit the resize behavior of this extent.
  ///
  /// Defaults to `0` and `double.infinity`, which means the extent can be resized freely without limits.
  factory Extent.ranged({
    double min,
    double max,
    double? pixels,
  }) = _RangeExtent;

  /// Used to compute the span extent of the row or column with this extent during layout
  /// based on the given [viewportExtent] and [remainingSpace].
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  });

  /// Accept the change of this extent with the given delta, and return the updated extent.
  ///
  /// Typically, this method will be called when the user resize a row or column with drag gesture,
  /// and the delta is the change of the drag gesture.
  ///
  /// For [Extent.fixed], it will ignore the delta and return itself directly since the extent is fixed.
  /// For [Extent.ranged], it will apply the delta to the current pixels within the valid range defined by min and max,
  bool resize(double delta);

  /// Create a copy of this extent with the same properties.
  /// But the dynamic measurement state will be reset to the initial state,
  /// which means if the original extent is measured,
  /// the cloned extent will be unmeasured until it is measured again with actual pixels.
  Extent clone();
}

final class _FixedExtent extends Extent {
  final double? pixels;

  _FixedExtent({this.pixels}) : _pixels = pixels;

  double? _pixels;

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    assert(isMeasured,
        'Extent must be measured before calculating the layout extent');

    if (!pinned) {
      return _pixels ?? 0;
    }

    final allowed = math.min(_pixels ?? 0, remainingSpace);
    return allowed >= 0 ? allowed : 0;
  }

  @override
  bool resize(double delta) => false;

  @override
  bool get isMeasured => _pixels != null;

  @override
  Extent acceptMeasurement(double measuredPixels) {
    _pixels = measuredPixels;

    return this;
  }

  @override
  (double, double) get range => (_pixels ?? 0, _pixels ?? double.infinity);

  @override
  Extent clone() => _FixedExtent(pixels: pixels);

  @override
  void resetMeasurement() {
    _pixels = pixels;
  }

  @override
  int get hashCode => _pixels.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FixedExtent &&
          runtimeType == other.runtimeType &&
          _pixels == other._pixels &&
          pixels == other.pixels;

  @override
  String toString() {
    return "_FixedExtent(pixels: $_pixels)";
  }
}

final class _RangeExtent extends Extent {
  final double min;
  final double max;
  final double? pixels;

  _RangeExtent({
    this.min = 0.0,
    this.max = double.infinity,
    this.pixels,
  })  : assert(min >= 0),
        assert(max >= 0),
        assert(pixels == null || pixels >= 0),
        assert(
            (pixels == null || pixels >= min) &&
                (pixels == null || pixels <= max),
            'pixels must be within the range defined by min and max'),
        _pixels = pixels;

  double? _pixels;

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    assert(isMeasured,
        'Extent must be measured before calculating the layout extent');

    if (!pinned) {
      return _constrainedPixels;
    }

    final allowed = math.min(_constrainedPixels, remainingSpace);
    return allowed >= 0 ? allowed : 0;
  }

  @override
  bool get isMeasured => _pixels != null;

  @override
  Extent acceptMeasurement(double measuredPixels) {
    _pixels = measuredPixels.clamp(min, max);
    return this;
  }

  double get _constrainedPixels {
    final resized = (_pixels ?? 0) + (_accumulatedDelta ?? 0);

    return resized.clamp(min, max);
  }

  double? _accumulatedDelta;

  @override
  bool resize(double delta) {
    assert(isMeasured, 'Extent must be measured before accepting changes');

    final newPixels = _constrainedPixels + delta;

    if (newPixels < min || newPixels > max) {
      return false;
    }

    _accumulatedDelta = (_accumulatedDelta ?? 0) + delta;

    return true;
  }

  @override
  (double, double) get range => (_pixels ?? min, _pixels ?? max);

  @override
  Extent clone() => _RangeExtent(min: min, max: max, pixels: pixels);

  @override
  void resetMeasurement() {
    _pixels = pixels;
  }

  @override
  int get hashCode => Object.hash(min, max, pixels, _pixels);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RangeExtent &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max &&
          pixels == other.pixels &&
          _pixels == other._pixels &&
          _accumulatedDelta == other._accumulatedDelta;

  @override
  String toString() {
    return "_RangeExtent(min: $min, max: $max, pixels: $pixels, measuredPixels: $_pixels)";
  }
}
