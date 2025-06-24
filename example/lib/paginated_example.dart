import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class PaginatedTableGridExample extends StatefulWidget {
  const PaginatedTableGridExample({super.key});

  @override
  State<PaginatedTableGridExample> createState() =>
      _PaginatedTableGridExampleState();
}

class _PaginatedTableGridExampleState extends State<PaginatedTableGridExample> {
  final _controller = TableController.paginated(
    pageSize: 5,
    columns: ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
        .map(
          (e) => ColumnKey(e),
        )
        .toList(),
    hoveringStrategies: [
      FocusStrategy.row,
      FocusStrategy.column,
    ],
    selectionStrategies: [
      FocusStrategy.row,
    ],
    defaultRowExtent: Extent.range(pixels: 80, min: 60, max: 120),
    defaultColumnExtent: Extent.range(pixels: 100, min: 60),
  );

  final _keyword = TextEditingController();

  @override
  void dispose() {
    _keyword.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paginated Table Grid Example'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8,
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
                child: TableGrid(
                  controller: _controller,
                  // reorderRow: true,
                  // resizeRow: true,
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
                  builder: _buildCell,
                  headerBuilder: _buildColumn,
                ),
              )
            ],
          ),
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addRows(10);
          },
        ),
        TextButton(
          onPressed: () {
            _controller.paginator?.previousPage();
          },
          child: Text("Previous"),
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
              _controller.paginator?.pageSize = e;
            }
          },
        ),
        TextButton(
          onPressed: () {
            _controller.paginator?.nextPage();
          },
          child: Text("Next"),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (_, __) {
            final paginator = _controller.paginator;
            return Text(
              "Page ${paginator!.currentPage} of ${paginator.pages}",
              style: const TextStyle(fontSize: 16),
            );
          },
        )
      ],
    );
  }

  bool _ascending = true;

  Widget _buildColumn(BuildContext ctx, TableHeaderDetail detail) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Center(
            child: Text(
              detail.columnKey.id,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (detail.isPinned) {
              _controller.columns.unpin(detail.columnKey);
            } else {
              _controller.columns.pin(detail.columnKey);
            }
          },
          icon: Icon(
            detail.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 16,
          ),
        ),
        IconButton(
          onPressed: () {
            _ascending = !_ascending;

            _controller.rows.performSort(
              compare: (a, b) {
                final aCell = a[detail.columnKey];
                final bCell = b[detail.columnKey];

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
          icon: Icon(
            Icons.arrow_upward,
            size: 16,
          ),
        )
      ],
    );
  }

  Widget _buildCell(BuildContext ctx, TableCellDetail detail) {
    final data = detail.cellData;

    final name = data != null ? data.toString() : "N/A";

    return InkWell(
      onTap: () {
        if (!detail.selected) {
          _controller.focuser.select(rows: [detail.rowKey]);
        } else {
          _controller.focuser.unselect(rows: [detail.rowKey]);
        }
      },
      onLongPress: () {
        if (detail.isPinned) {
          _controller.rows.unpin(detail.rowKey);
        } else {
          _controller.rows.pin(detail.rowKey);
        }
      },
      onHover: (value) {
        if (value) {
          _controller.focuser.hoverOn(row: detail.rowKey);
        } else {
          _controller.focuser.hoverOff(row: detail.rowKey);
        }
      },
      child: Center(
        child: Text(
          "$name, ${detail.columnKey.id}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _addRows(int count) {
    final columns = _controller.columns.ordered;

    final rows = List.generate(
      count,
      (index) => RowData(
        RowKey(UniqueKey()),
        data: {
          for (final column in columns)
            column: 'Row ${_controller.rows.dataCount + index}',
        },
      ),
    );

    _controller.rows.addAll(rows);
  }

  void _search(String keyword) {
    _controller.rows.performSearch(
      keyword: keyword,
      matcher: (keyword, data) {
        return data.data.values.any(
          (value) =>
              value.toString().toLowerCase().contains(keyword.toLowerCase()),
        );
      },
    );
  }
}
