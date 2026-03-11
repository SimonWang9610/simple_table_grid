import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';
import 'package:simple_table_grid/custom_render/render.dart';

class TableGridViewport extends TwoDimensionalViewport {
  final BorderSide verticalBorderSide;
  final BorderSide horizontalBorderSide;

  const TableGridViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required CellLayoutExtentDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior,
    this.verticalBorderSide = BorderSide.none,
    this.horizontalBorderSide = BorderSide.none,
  });

  @override
  RenderTableGridViewport createRenderObject(BuildContext context) {
    return RenderTableGridViewport(
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      delegate: delegate as CellLayoutExtentDelegate,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      verticalBorderSide: verticalBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      childManager: context as TwoDimensionalChildManager,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableGridViewport renderObject,
  ) {
    renderObject
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..delegate = delegate as CellLayoutExtentDelegate
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior
      ..verticalBorderSide = verticalBorderSide
      ..horizontalBorderSide = horizontalBorderSide;
  }
}
