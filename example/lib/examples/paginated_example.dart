import 'package:example/examples/column_selector.dart';
import 'package:example/examples/exporter_button.dart';
import 'package:example/helper.dart';
import 'package:example/models/custom_data_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class PaginatedExample extends StatefulWidget {
  const PaginatedExample({super.key});

  @override
  State<StatefulWidget> createState() => _PaginatedExampleState();
}

class _PaginatedExampleState extends State<PaginatedExample> {
  final _pageSize = ValueNotifier<int>(5);

  final columnModels = [
    CustomDataGridModel(
        columnName: 'Menu',
        isDisplayed: true,
        width: 100,
        position: 0,
        isPinned: true,
        allowResizing: false),
    CustomDataGridModel(
      columnName: 'Surname',
      isDisplayed: true,
      width: 200,
      position: 1,
      allowFiltering: true,
    ),
    CustomDataGridModel(
      columnName: 'GivenName',
      isDisplayed: true,
      width: 200,
      position: 2,
      allowSorting: true,
    ),
    CustomDataGridModel(
      columnName: 'PhoneNumber',
      isDisplayed: true,
      width: 200,
      position: 4,
    ),
    CustomDataGridModel(
      columnName: 'CardAssignments',
      isDisplayed: true,
      width: 400,
      position: 5,
    ),
    CustomDataGridModel(
      columnName: 'BadgeType',
      isDisplayed: true,
      width: 400,
      position: 6,
    ),
    CustomDataGridModel(
      columnName: 'Tags',
      isDisplayed: true,
      width: 300,
      position: 7,
    ),
  ];

  late final TableController _tableController;

  @override
  void initState() {
    super.initState();

    final columns = <HeaderData>[];
    final pinnedColumns = <ColumnKey>[];
    final columnExtents = <ColumnKey, Extent>{};

    for (final col in columnModels) {
      final key = col.columnKey;

      if (col.isDisplayed == false) {
        continue; // Skip columns that are not displayed
      }

      columns.add(
        HeaderData(
          key: key,
          data: col,
        ),
      );

      if (col.isPinned) {
        pinnedColumns.add(key);
      }

      columnExtents[key] = col.buildExtent(min: 100);
    }

    _tableController = TableController.paginated(
      pageSize: _pageSize.value,
      columns: columns,
      pinnedColumns: pinnedColumns,
      defaultRowExtent: Extent.fixed(60),
      defaultColumnExtent: Extent.range(pixels: 200, min: 100),
      columnExtents: columnExtents,
    );
  }

  final _keyword = TextEditingController();
  final _loading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _tableController.dispose();
    _keyword.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 15,
          children: [
            Row(
              children: [
                ExcelExportButton(controller: _tableController),
                PdfExportButton(controller: _tableController),
                ListenableBuilder(
                  listenable: _tableController,
                  builder: (_, __) {
                    return TableColumnSelector(
                      allColumns: columnModels,
                      selectedColumns: _tableController.columns.ordered,
                      onSubmit: _onColumnChanged,
                    );
                  },
                ),
              ],
            ),
            TextField(
              controller: _keyword,
              decoration: InputDecoration(
                  labelText: "Search",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _keyword.clear();
                      _search("");
                    },
                    icon: Icon(Icons.close),
                  )),
              onSubmitted: _search,
            ),
            Expanded(
              child: Stack(
                children: [
                  TableGrid(
                    controller: _tableController,
                    theme: TableGridThemeData(
                      cellTheme: CellTheme(
                        hoveringColor: Colors.grey.shade200,
                        selectedColor: Colors.green.shade100,
                        unselectedColor: Colors.white,
                      ),
                      headerTheme: CellTheme(
                        hoveringColor: Colors.blue.shade100,
                        selectedColor: Colors.blue.shade200,
                        unselectedColor: Colors.yellow.shade100,
                      ),
                      border: TableGridBorder(
                        vertical: BorderSide(
                          color: Colors.red,
                          width: 0.5,
                        ),
                        horizontal: BorderSide(
                          color: Colors.black,
                          width: 0.5,
                        ),
                      ),
                    ),
                    builder: (_, detail) =>
                        _CellWidget(_tableController, detail),
                    headerBuilder: (_, detail) =>
                        _HeaderWidget(_tableController, detail),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ValueListenableBuilder(
                      valueListenable: _loading,
                      builder: (context, value, child) =>
                          value ? child! : const SizedBox.shrink(),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            _tableController.rows.replaceAll([]);
          },
          child: const Text("Clear"),
        ),
        ElevatedButton(
          onPressed: () {
            _loadMore(10);
          },
          child: const Text("Load More (10)"),
        ),
        TextButton(
          onPressed: () {
            _tableController.paginator?.previousPage();
          },
          child: const Text("Previous"),
        ),
        TextButton(
          onPressed: () {
            _tableController.paginator?.nextPage();
          },
          child: Text("Next"),
        ),
        ValueListenableBuilder(
          valueListenable: _pageSize,
          builder: (context, value, child) {
            return DropdownButton<int>(
              value: value,
              items: [5, 10, 15, 20]
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e,
                      child: Text("$e items per page"),
                    ),
                  )
                  .toList(),
              onChanged: (e) {
                if (e != null) {
                  _tableController.paginator?.pageSize = e;
                  _pageSize.value = e;
                }
              },
            );
          },
        ),
        ListenableBuilder(
          listenable: _tableController,
          builder: (_, __) {
            final paginator = _tableController.paginator;
            return Text(
              "Page ${paginator!.currentPage} of ${paginator.pages}",
              style: const TextStyle(fontSize: 16),
            );
          },
        )
      ],
    );
  }

  Future<void> _search(String keyword) async {
    final rows = await _mock(6, keyword: keyword);

    if (keyword.isNotEmpty) {
      /// add mock data to show the search case
      _tableController.rows.addAll(rows);
    }

    _tableController.rows.performSearch(
      keyword: keyword,
      matcher: (keyword, row) {
        return row.data.values.any(
          (value) =>
              value.toString().toLowerCase().contains(keyword.toLowerCase()),
        );
      },
    );
  }

  Future<void> _loadMore(int limit) async {
    if (_loading.value) return;
    _loading.value = true;
    final rows = await _mock(limit);
    _tableController.rows.addAll(rows);
    _loading.value = false;
  }

  Future<List<RowData>> _mock(int limit, {String? keyword}) async {
    try {
      final people = await ExampleHelper.mockPeople(limit, keyword: keyword);

      return people.map(
        (e) {
          final jsonData = e.toJson();

          return RowData(
            RowKey(e.key),
            data: {
              /// no matter if the column is displayed or not,
              /// we still need to provide the data for it,
              /// in case it is displayed later
              ///
              /// Otherwise, [TableCellDetail.data] will be null
              for (final col in columnModels)
                col.columnKey: jsonData[col.columnName],
            },
          );
        },
      ).toList();
    } catch (e) {
      debugPrint("Error mocking data: $e");
      return [];
    }
  }

  /// As [CustomDataGridModel] is mutable,
  /// so we can update its isDisplayed property.
  /// The update will be reflected in the element of [columnModels],
  /// as we are mutating the same instance.
  ///
  ///
  /// If [HeaderData.data] is immutable,
  /// we should store [isDisplayed] as part of [HeaderData.data],
  /// as [TableController.columns.ordered] only shows those displaying columns.
  void _onColumnChanged(
    List<HeaderData> willAdded,
    List<ColumnKey> willRemoved,
  ) {
    for (final col in willAdded) {
      if (col.data is! CustomDataGridModel) {
        throw ArgumentError(
          "Column data must be of type CustomDataGridModel",
        );
      }

      (col.data as CustomDataGridModel).isDisplayed = true;
    }

    for (final key in willRemoved) {
      final columnData = _tableController.columns.getHeaderData(key);
      if (columnData is CustomDataGridModel) {
        columnData.isDisplayed = false;
      }
    }

    _tableController.columns.addAll(willAdded);
    _tableController.columns.removeAll(willRemoved);
  }
}

class _CellWidget extends StatelessWidget {
  final TableController controller;
  final TableCellDetail detail;
  const _CellWidget(this.controller, this.detail);

  @override
  Widget build(BuildContext context) {
    final data = detail.cellData;
    final headerData = controller.columns.getHeaderData(detail.columnKey)
        as CustomDataGridModel;

    if (headerData.columnName == "Menu") {
      return InkWell(
        onTap: () {},
        child: Icon(
          Icons.more_vert,
          size: 16,
        ),
      );
    }

    return InkWell(
      onTap: () {
        if (!detail.selected) {
          controller.focuser.select(rows: [detail.rowKey]);
        } else {
          controller.focuser.unselect(rows: [detail.rowKey]);
        }
      },
      onHover: (value) {
        if (value) {
          controller.focuser.hoverOn(row: detail.rowKey);
        } else {
          controller.focuser.hoverOff(row: detail.rowKey);
        }
      },
      child: Text(
        data.toString(),
        style: const TextStyle(),
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _HeaderWidget extends StatefulWidget {
  final TableController controller;

  final TableHeaderDetail detail;
  const _HeaderWidget(this.controller, this.detail);

  @override
  State<_HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<_HeaderWidget> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final data = widget.detail.data as CustomDataGridModel;

    final isMenu = data.columnName == "Menu";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Center(
              child: Text(
                data.displayName ?? data.columnName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (isMenu) return; // Skip if it's the menu column

              if (widget.detail.isPinned) {
                widget.controller.columns.unpin(widget.detail.columnKey);
              } else {
                widget.controller.columns.pin(widget.detail.columnKey);
              }
            },
            child: Icon(
              widget.detail.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 14,
            ),
          ),
          if (data.allowSorting)
            InkWell(
              onTap: () {
                _ascending = !_ascending;

                widget.controller.rows.performSort(
                  compare: (a, b) {
                    final aCell = a[widget.detail.columnKey];
                    final bCell = b[widget.detail.columnKey];

                    if (aCell == null || bCell == null) {
                      return -1; // Handle null values gracefully
                    }

                    if (_ascending) {
                      return aCell.toString().compareTo(bCell.toString());
                    } else {
                      return bCell.toString().compareTo(aCell.toString());
                    }
                  },
                );
              },
              child: Icon(
                Icons.arrow_upward,
                size: 14,
              ),
            )
        ],
      ),
    );
  }
}
