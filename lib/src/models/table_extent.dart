import 'package:simple_table_grid/src/models/span.dart';

sealed class TableExtent {
  const TableExtent();

  SpanExtent get spanExtent;

  factory TableExtent.fixed(double pixels) {
    return _FixedTableExtent(pixels);
  }
  factory TableExtent.fractional(double fraction) {
    return _FractionalTableExtent(fraction);
  }

  factory TableExtent.ranged(double min, double max) {
    return _RangedTableExtent(min, max);
  }
}

final class _FixedTableExtent extends TableExtent {
  final double pixels;

  const _FixedTableExtent(this.pixels)
      : assert(pixels >= 0, "pixels must be non-negative");

  @override
  SpanExtent get spanExtent => FixedSpanExtent(pixels);
}

final class _FractionalTableExtent extends TableExtent {
  final double fraction;

  const _FractionalTableExtent(this.fraction)
      : assert(
            fraction >= 0 && fraction <= 1, "fraction must be between 0 and 1");

  @override
  SpanExtent get spanExtent => FractionalSpanExtent(fraction);
}

final class _RangedTableExtent extends TableExtent {
  final double min;
  final double max;

  const _RangedTableExtent(this.min, this.max)
      : assert(min >= 0 && max >= min, "min and max must be non-negative");

  @override
  SpanExtent get spanExtent {
    if (max == min) {
      return FixedSpanExtent(min);
    } else {
      return MaxSpanExtent(
        FixedSpanExtent(min),
        FixedSpanExtent(max),
      );
    }
  }
}
