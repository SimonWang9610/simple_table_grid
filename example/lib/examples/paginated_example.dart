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
  final columnModels = [
    CustomDataGridModel(
        columnName: 'Menu',
        isDisplayed: true,
        width: 100,
        position: 0,
        isPinned: true),
    CustomDataGridModel(
        columnName: 'Surname', isDisplayed: true, width: 200, position: 1),
    CustomDataGridModel(
        columnName: 'GivenName', isDisplayed: true, width: 200, position: 2),
    CustomDataGridModel(
        columnName: 'PhoneNumber', isDisplayed: true, width: 200, position: 4),
    CustomDataGridModel(
        columnName: 'CardAssignments',
        isDisplayed: true,
        width: 400,
        position: 5),
    CustomDataGridModel(
        columnName: 'BadgeType', isDisplayed: true, width: 400, position: 6),
    CustomDataGridModel(
        columnName: 'Tags', isDisplayed: true, width: 300, position: 7),
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
      pageSize: 10,
      columns: columns,
      pinnedColumns: pinnedColumns,
      defaultRowExtent: Extent.range(pixels: 80, min: 60, max: 100),
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
        DropdownButton<int>(
          value: 5,
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
            }
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
      return IconButton(
        onPressed: () {},
        icon: Icon(Icons.menu),
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
