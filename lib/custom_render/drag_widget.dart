import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

typedef DragCellCallback<T extends CellDetail> = void Function(
  T from,
  T to,
);

class DraggableCellWidget<T extends CellDetail> extends StatelessWidget {
  final T detail;
  final Widget child;
  final Widget? feedback;
  final DragCellCallback<T> onAccept;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  const DraggableCellWidget({
    super.key,
    required this.detail,
    required this.onAccept,
    this.onDragStarted,
    this.onDragEnd,
    required this.child,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final target = DragTarget<T>(
      onAcceptWithDetails: (from) => onAccept(from.data, detail),
      builder: (ctx, _, __) => child,
    );

    final draggable = Draggable<T>(
      data: detail,
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnd != null ? (_) => onDragEnd?.call() : null,
      feedback: feedback ??
          Material(
            elevation: 6.0,
            child: child,
          ),
      childWhenDragging: const SizedBox.shrink(),
      child: target,
    );

    return draggable;
  }
}
