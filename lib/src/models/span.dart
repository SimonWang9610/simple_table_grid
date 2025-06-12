import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Defines the leading and trailing padding values of a [Span].
class SpanPadding {
  /// Creates a padding configuration for a [Span].
  const SpanPadding({
    this.leading = 0.0,
    this.trailing = 0.0,
  });

  /// Creates padding where both the [leading] and [trailing] are `value`.
  const SpanPadding.all(double value)
      : leading = value,
        trailing = value;

  /// The leading amount of pixels to pad a [Span] by.
  ///
  /// If the [Span] is a row and the vertical [Axis] is not reversed, this
  /// offset will be applied above the row. If the vertical [Axis] is reversed,
  /// this will be applied below the row.
  ///
  /// If the [Span] is a column and the horizontal [Axis] is not reversed,
  /// this offset will be applied to the left the column. If the horizontal
  /// [Axis] is reversed, this will be applied to the right of the column.
  final double leading;

  /// The trailing amount of pixels to pad a [Span] by.
  ///
  /// If the [Span] is a row and the vertical [Axis] is not reversed, this
  /// offset will be applied below the row. If the vertical [Axis] is reversed,
  /// this will be applied above the row.
  ///
  /// If the [Span] is a column and the horizontal [Axis] is not reversed,
  /// this offset will be applied to the right the column. If the horizontal
  /// [Axis] is reversed, this will be applied to the left of the column.
  final double trailing;
}

/// Delegate passed to [SpanExtent.calculateExtent] from the
/// [RenderTableViewport] during layout.
///
/// Provides access to metrics from the [TableView] that a [SpanExtent] may
/// need to calculate its extent.
///
/// Extents will not be computed for every frame unless the delegate has been
/// updated. Otherwise, after the extents are computed during the first layout
/// passed, they are cached and reused in subsequent frames.
class SpanExtentDelegate {
  /// Creates a [SpanExtentDelegate].
  ///
  /// Usually, only [TableView]s need to create instances of this class.
  const SpanExtentDelegate({
    required this.viewportExtent,
    required this.precedingExtent,
  });

  /// The size of the viewport in the axis-direction of the span.
  ///
  /// If the [SpanExtent] calculates the extent of a row, this is the
  /// height of the viewport. If it calculates the extent of a column, this
  /// is the width of the viewport.
  final double viewportExtent;

  /// The scroll extent that has already been used up by previous spans.
  ///
  /// If the [SpanExtent] calculates the extent of a row, this is the
  /// sum of all row extents prior to this row. If it calculates the extent
  /// of a column, this is the sum of all previous columns.
  final double precedingExtent;
}

/// Defines the extent of a [Span].
///
/// If the span is a row, its extent is the height of the row. If the span is
/// a column, it's the width of that column.
abstract class SpanExtent {
  /// Creates a [SpanExtent].
  const SpanExtent();

  /// Calculates the actual extent of the span in pixels.
  ///
  /// To assist with the calculation, span metrics obtained from the provided
  /// [SpanExtentDelegate] may be used.
  double calculateExtent(SpanExtentDelegate delegate);
}

/// A span extent with a fixed [pixels] value.
class FixedSpanExtent extends SpanExtent {
  /// Creates a [FixedSpanExtent].
  ///
  /// The provided [pixels] value must be equal to or greater then zero.
  const FixedSpanExtent(this.pixels) : assert(pixels >= 0.0);

  /// The extent of the span in pixels.
  final double pixels;

  @override
  double calculateExtent(SpanExtentDelegate delegate) => pixels;
}

/// Specified the span extent as a fraction of the viewport extent.
///
/// For example, a column with a 1.0 as [fraction] will be as wide as the
/// viewport.
class FractionalSpanExtent extends SpanExtent {
  /// Creates a [FractionalSpanExtent].
  ///
  /// The provided [fraction] value must be equal to or greater than zero.
  const FractionalSpanExtent(
    this.fraction,
  ) : assert(fraction >= 0.0);

  /// The fraction of the [SpanExtentDelegate.viewportExtent] that the
  /// span should occupy.
  ///
  /// The provided [fraction] value must be equal to or greater than zero.
  final double fraction;

  @override
  double calculateExtent(SpanExtentDelegate delegate) =>
      delegate.viewportExtent * fraction;
}

/// Specifies that the span should occupy the remaining space in the viewport.
///
/// If the previous [Span]s can already fill out the viewport, this will
/// evaluate the span's extent to zero. If the previous spans cannot fill out the
/// viewport, this span's extent will be whatever space is left to fill out the
/// viewport.
///
/// To avoid that the span's extent evaluates to zero, consider combining this
/// extent with another extent. The following example will make sure that the
/// span's extent is at least 200 pixels, but if there's more than that available
/// in the viewport, it will fill all that space:
///
/// ```dart
/// const MaxSpanExtent(FixedSpanExtent(200.0), RemainingSpanExtent());
/// ```
class RemainingSpanExtent extends SpanExtent {
  /// Creates a [RemainingSpanExtent].
  const RemainingSpanExtent();

  @override
  double calculateExtent(SpanExtentDelegate delegate) {
    return math.max(0.0, delegate.viewportExtent - delegate.precedingExtent);
  }
}

/// Signature for a function that combines the result of two
/// [SpanExtent.calculateExtent] invocations.
///
/// Used by [CombiningSpanExtent];
typedef SpanExtentCombiner = double Function(double, double);

/// Runs the result of two [SpanExtent]s through a `combiner` function
/// to determine the ultimate pixel extent of a span.
class CombiningSpanExtent extends SpanExtent {
  /// Creates a [CombiningSpanExtent];
  const CombiningSpanExtent(this._extent1, this._extent2, this._combiner);

  final SpanExtent _extent1;
  final SpanExtent _extent2;
  final SpanExtentCombiner _combiner;

  @override
  double calculateExtent(SpanExtentDelegate delegate) {
    return _combiner(
      _extent1.calculateExtent(delegate),
      _extent2.calculateExtent(delegate),
    );
  }
}

/// Returns the larger pixel extent of the two provided [SpanExtent].
class MaxSpanExtent extends CombiningSpanExtent {
  /// Creates a [MaxSpanExtent].
  const MaxSpanExtent(
    SpanExtent extent1,
    SpanExtent extent2,
  ) : super(extent1, extent2, math.max);
}

/// Returns the smaller pixel extent of the two provided [SpanExtent].
class MinSpanExtent extends CombiningSpanExtent {
  /// Creates a [MinSpanExtent].
  const MinSpanExtent(
    SpanExtent extent1,
    SpanExtent extent2,
  ) : super(extent1, extent2, math.min);
}
