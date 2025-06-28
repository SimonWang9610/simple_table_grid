<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->


## Usage

### Infinite Scroll TableGrid

```dart
  /// Creates a new [TableController] with the given parameters.
  ///
  /// [columns] is a list of [ColumnKey]s that define the columns of the table.
  ///
  /// [pinnedColumns] is a list of [ColumnKey]s that define the pinned columns of the table.
  ///
  /// [initialRows] is a list of [RowData] that defines the initial rows
  ///
  /// [alwaysShowHeader] determines whether the header should always be shown whens scrolling.
  ///
  /// [defaultRowExtent] and [defaultColumnExtent] define the default extents for rows and columns.
  ///
  ///
  /// [rowExtents] and [columnExtents] are optional maps that define the extents for specific rows and columns.
  /// if not provided or the key is not found, the default extent will be used.
  ///
  /// NOTE: if the extent of an index is not [Extent.range], resizing will not work for that index.
  ///
  /// [selectionStrategies] and [hoveringStrategies] define the strategies for selection and hovering.
  /// By default, they are set to [FocusStrategy.row] for both selection and hovering.
  ///
  /// When building the cell widget, [CellDetail] would provide the hovering and selection state
  /// for the cell.
  factory TableController({
    required List<HeaderData> columns,
    List<ColumnKey> pinnedColumns = const [],
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  })
```


### Paginated TableGrid
```dart
  /// Creates a new [TableController] with pagination support.
  /// This controller does not support pin/unpin/reorder/setHeaderVisibility operations.
  factory TableController.paginated({
    required int pageSize,
    required List<HeaderData> columns,
    List<ColumnKey> pinnedColumns = const [],
    List<RowData> initialRows = const [],
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  })
```

### Resizing

In order to enable resizing, there are 2 requirements:

- `TableGrid` is configured to enable resize column/row
```dart
  final bool resizeColumn;

  /// Whether to allow resizing of rows by dragging.
  /// only works if the [TableController.paginator] is null.
  final bool resizeRow;
```

- The extent of the column/row is `Extent.range`

    The width/height must be specified by `Extent`. There are 2 kinds of `Extent`:

    1. `Extent.fixed` specifies a fixed extent, which can not be resized. Even though you enable the resize for column/row,
        it will not accept the incoming pixel delta during dragging, and as a result, it will not change its size.

    2. `Extent.range` specifies an initial extent and a range of resizing. During dragging, it will try to accept the incoming pixel delta by comparing its [min, max] of the extent. So the final extent would be constrained between [min, max] of `Extent.range`

## Limitations

- Users must define how to convert the custom data model to `RowData`

- When adding columns, users should care about how to fill the value into the newly added columns for each row.
  - For example, if existing rows only have `col-1, col-2` fields, users should handle how to fill the newly added `col-3` for each row; otherwise, the corresponding `col-3`'s value would be null for each row.

- `performSort` and `performSearch` only work on existing rows in the table, so rows added after those operations would not be sorted/filtered. So users could do either:
  1. replace all existing rows with the sorted/filtered rows
  2. add new rows before sorting/filtering
