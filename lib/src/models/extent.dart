import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A class representing the extent of a row or column in a table grid.
/// Only [Extent.range] supports resizing.
/// Other extents are fixed and do not change during resizing.
sealed class Extent extends Equatable {
  const Extent();

  const factory Extent.fixed(double pixels) = _FixedExtent;
  const factory Extent.range({
    double? min,
    double? max,
    required double pixels,
  }) = _RangeExtent;

  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  });

  double get currentPixels;

  bool get isDynamic => false;

  Extent accept(double delta);

  /// Returns an [Extent] that behaves like this extent but is dynamic,
  /// meaning it will be measured and respect the content size instead of being fixed to a specific pixel value.
  Extent auto() {
    if (this is _AutoExtent) {
      return this;
    }

    return _AutoExtent(this);
  }
}

final class _FixedExtent extends Extent {
  final double pixels;

  const _FixedExtent(this.pixels);

  @override
  double get currentPixels => pixels;

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
  List<Object?> get props => [pixels];
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
  double get currentPixels => pixels;

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
  List<Object?> get props => [min, max, pixels];
}

final class _AutoExtent extends Extent {
  // we must give a fixed/ranged extent as reference to layout in the first layout phase,
  // otherwise we don't know how to compute the row metrics before starting layout
  final Extent reference;

  const _AutoExtent(this.reference)
      : assert(
            reference is! _AutoExtent, 'Nested auto extents are not allowed');

  @override
  double get currentPixels => reference.currentPixels;

  @override
  bool get isDynamic => true;

  @override
  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  }) {
    return reference.calculate(
      viewportExtent,
      remainingSpace: remainingSpace,
      pinned: pinned,
    );
  }

  @override
  Extent accept(double delta) {
    return switch (reference) {
      _FixedExtent _ => Extent.fixed(delta),
      _RangeExtent range => Extent.range(
          min: range.min != null ? math.min(range.min!, delta) : delta,
          max: range.max != null ? math.max(range.max!, delta) : delta,
          pixels: delta,
        ),
      _ => throw StateError("Never reached")
    };
  }

  @override
  List<Object?> get props => [reference];
}
