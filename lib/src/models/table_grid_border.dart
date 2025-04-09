import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/models/table_extent.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class TableGridBorder {
  final bool foreground;
  final BorderSide? vertical;
  final BorderSide? horizontal;

  const TableGridBorder({
    this.vertical,
    this.horizontal,
    this.foreground = false,
  });

  TableSpan build({
    required Axis axis,
    required TableExtent extent,
    bool last = false,
  }) {
    final padding = switch (axis) {
      Axis.horizontal => SpanPadding(
          trailing: last ? 0 : horizontal?.width ?? 0,
        ),
      Axis.vertical => SpanPadding(
          trailing: last ? 0 : vertical?.width ?? 0,
        ),
    };

    final border = switch (axis) {
      Axis.horizontal => SpanBorder(
          trailing: last ? BorderSide.none : horizontal ?? BorderSide.none,
        ),
      Axis.vertical => SpanBorder(
          trailing: last ? BorderSide.none : vertical ?? BorderSide.none,
        ),
    };

    final decoration = SpanDecoration(
      consumeSpanPadding: true,
      border: border,
    );

    return TableSpan(
      extent: extent.spanExtent,
      padding: padding,
      backgroundDecoration: !foreground ? decoration : null,
      foregroundDecoration: foreground ? decoration : null,
    );
  }

  @override
  bool operator ==(covariant TableGridBorder other) {
    if (identical(this, other)) return true;

    return other.foreground == foreground &&
        other.vertical == vertical &&
        other.horizontal == horizontal;
  }

  @override
  int get hashCode {
    return foreground.hashCode ^ vertical.hashCode ^ horizontal.hashCode;
  }
}
