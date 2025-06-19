import 'package:flutter/widgets.dart';

class TableGridBorder {
  final BorderSide vertical;
  final BorderSide horizontal;

  const TableGridBorder({
    this.vertical = BorderSide.none,
    this.horizontal = BorderSide.none,
  });

  const TableGridBorder.none()
      : vertical = BorderSide.none,
        horizontal = BorderSide.none;

  const TableGridBorder.all({BorderSide side = const BorderSide()})
      : vertical = side,
        horizontal = side;

  EdgeInsets calculatePadding(bool rightEdge, bool bottomEdge) {
    final vPadding = vertical.width;
    final hPadding = horizontal.width;

    return EdgeInsets.only(
      left: vPadding,
      right: rightEdge ? vPadding : 0.0,
      top: hPadding,
      bottom: bottomEdge ? hPadding : 0.0,
    );
  }

  Border calculateBorder(bool rightEdge, bool bottomEdge) {
    return Border(
      left: vertical,
      right: rightEdge ? vertical : BorderSide.none,
      top: horizontal,
      bottom: bottomEdge ? horizontal : BorderSide.none,
    );
  }
}
