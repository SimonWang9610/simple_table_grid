import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Custom Table Grid Example',
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _extentManager = TableExtentManager(
    defaultColumnExtent: TableExtent.fixed(150),
    defaultRowExtent: TableExtent.fixed(50),
  );

  late final _controller = TableController(
    columns: ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
        .map(
          (e) => ColumnKey(e),
        )
        .toList(),
    extentManager: _extentManager,
    hoveringStrategies: [
      FocusStrategy.row,
    ],
    selectionStrategies: [
      FocusStrategy.row,
    ],
  );

  @override
  void dispose() {
    _extentManager.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Table Grid Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableGrid(
          controller: _controller,
          cellBuilder: _buildCell,
          columnBuilder: _buildColumn,
          // border: TableGridBorder(
          //     // vertical: BorderSide(
          //     //   color: Colors.red,
          //     //   width: 2,
          //     // ),
          //     // horizontal: BorderSide(
          //     //   color: Colors.black,
          //     //   width: 2,
          //     // ),
          //     ),
          // loadingBuilder: (ctx) {
          //   return CircularProgressIndicator(
          //     color: Colors.red,
          //   );
          // },
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
            _controller.removeRows(
              [_controller.getRowKey(1)],
            );
          },
          child: Text("Remove first row"),
        ),
        TextButton(
          onPressed: () {
            _randomRemove(true, false);
          },
          child: Text("Remove first column"),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext ctx, ColumnHeaderDetail detail) {
    return InkWell(
      onTap: () {
        if (detail.isPinned) {
          _controller.unpinColumn(detail.columnKey);
        } else {
          _controller.pinColumn(detail.columnKey);
        }
      },
      child: Container(
        color: detail.isPinned ? Colors.blue : Colors.yellow,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              detail.columnKey.id,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              detail.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext ctx, TableCellDetail detail) {
    final data = detail.cellData;

    final name = data != null ? data.toString() : "N/A";

    return InkWell(
      onTap: () {
        if (!detail.selected) {
          _controller.select(rows: [detail.rowKey]);
        } else {
          _controller.unselect(rows: [detail.rowKey]);
        }
      },
      onLongPress: () {
        if (detail.isPinned) {
          _controller.unpinRow(detail.rowKey);
        } else {
          _controller.pinRow(detail.rowKey);
        }
      },
      onHover: (value) {
        if (value) {
          _controller.hoverOn(row: detail.rowKey);
        } else {
          _controller.hoverOff(row: detail.rowKey);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: detail.hovering ? Colors.grey : Colors.white,
          border: detail.selected
              ? Border.all(
                  color: Colors.green,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            "$name, ${detail.columnKey.id}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _addRows(int count) {
    final columns = _controller.orderedColumns;

    final rows = List.generate(
      count,
      (index) => RowData(
        RowKey(UniqueKey()),
        {
          for (final column in columns)
            column: 'Row ${_controller.dataCount + index}',
        },
      ),
    );

    _controller.addRows(rows);
  }

  void _randomRemove(bool row, bool column) {
    final rnd = Random();

    final nextRow = rnd.nextInt(_controller.dataCount) + 1;
    print("Next row: $nextRow");

    final nextColumn = rnd.nextInt(_controller.columnCount);

    final rowKey = _controller.getRowKey(nextRow);
    final columnKey = _controller.getColumnKey(nextColumn);

    if (row) {
      print("Removing row: $rowKey");
      _controller.removeRows([rowKey]);
    }

    if (column) {
      print("Removing column: $columnKey");
      _controller.removeColumn(columnKey);
    }
  }
}
