import 'dart:math' as math;

import 'package:flutter/widgets.dart';

// todo: child builder logic
mixin CellLayoutExtentDelegate on TwoDimensionalChildDelegate {
  int get rowCount;
  int get columnCount;
  int get pinnedRowCount;
  int get pinnedColumnCount;

  Extent getColumnExtent(int index);
  Extent getRowExtent(int index);
}

sealed class Extent {
  const Extent();

  const factory Extent.fixed(double pixels) = _FixedExtent;
  const factory Extent.fractional(double fraction) = _FractionalExtent;
  const factory Extent.remaining() = _RemainingExtent;

  double calculate(
    double viewportExtent, {
    required double remainingSpace,
    bool pinned = false,
  });
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
}

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
}

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
}
