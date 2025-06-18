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
  late final _controller = TableController(
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
    defaultRowExtent: Extent.fixed(60),
    defaultColumnExtent: Extent.range(pixels: 100, min: 60),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Table Grid Example'),
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
          child: TableGrid(
            controller: _controller,
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
            builder: _buildCell,
            headerBuilder: _buildColumn,
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
            _randomRemove(true, false);
          },
          child: Text("Remove first column"),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext ctx, ColumnHeaderDetail detail) {
    return Container(
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
              // size: 16,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {},
      onHover: (value) {
        if (value) {
          _controller.focuser.hoverOn(column: detail.columnKey);
        } else {
          _controller.focuser.hoverOff(column: detail.columnKey);
        }
      },
      child: Container(
        color: detail.isPinned
            ? Colors.blue
            : detail.hovering
                ? Colors.yellow
                : Colors.transparent,
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
    final columns = _controller.columns.ordered;

    final rows = List.generate(
      count,
      (index) => RowData(
        RowKey(UniqueKey()),
        {
          for (final column in columns)
            column: 'Row ${_controller.rows.dataCount + index}',
        },
      ),
    );

    _controller.rows.addAll(rows);
  }

  void _randomRemove(bool row, bool column) {
    final rnd = Random();

    final nextRow = rnd.nextInt(_controller.rows.dataCount) + 1;
    print("Next row: $nextRow");

    final nextColumn = rnd.nextInt(_controller.columnCount);

    final rowKey = _controller.finder.getRowKey(nextRow);
    final columnKey = _controller.finder.getColumnKey(nextColumn);

    if (row) {
      print("Removing row: $rowKey");
      _controller.rows.remove(rowKey!);
    }

    if (column) {
      print("Removing column: $columnKey");
      _controller.columns.remove(columnKey);
    }
  }
}
