import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class AutoRowExtentExample extends StatefulWidget {
  const AutoRowExtentExample({super.key});

  @override
  State<AutoRowExtentExample> createState() => _AutoRowExtentExampleState();
}

class _AutoRowExtentExampleState extends State<AutoRowExtentExample> {
  late final TableController _controller;

  static final ColumnKey _idColumn = const ColumnKey('id');
  static final ColumnKey _nameColumn = const ColumnKey('name');
  static final ColumnKey _notesColumn = const ColumnKey('notes');

  @override
  void initState() {
    super.initState();

    _controller = TableController(
      columns: [
        HeaderData(key: _idColumn, data: 'ID'),
        HeaderData(key: _nameColumn, data: 'Name'),
        HeaderData(key: _notesColumn, data: 'Notes'),
      ],
      defaultRowExtent: Extent.auto(max: 100),
      defaultColumnExtent: const Extent.fixed(180),
      columnExtents: {
        _idColumn: const Extent.fixed(80),
        _nameColumn: const Extent.fixed(180),
        _notesColumn: const Extent.fixed(420),
      },
      initialRows: [
        RowData(
          const RowKey('r0'),
          data: {
            _idColumn: '1',
            _nameColumn: 'Alice',
            _notesColumn: 'Short note.',
          },
        ),
        RowData(
          const RowKey('r1'),
          data: {
            _idColumn: '2',
            _nameColumn: 'Bob',
            _notesColumn:
                'This row uses Extent.auto. The notes cell contains a much longer message that should wrap across multiple lines and make the row height grow to fit the tallest cell.',
          },
        ),
        RowData(
          const RowKey('r2'),
          data: {
            _idColumn: '3',
            _nameColumn: 'Cathy',
            _notesColumn: 'Still fixed height because this row is not auto.',
          },
        ),
        RowData(
          const RowKey('r3'),
          data: {
            _idColumn: '4',
            _nameColumn: 'Dylan',
            _notesColumn:
                'Another Extent.auto row. Resize the Notes column to see this row recompute and cache a different height based on wrapped text.',
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Row Extent Example')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rows 2 and 4 use Extent.auto; others stay fixed at 44 px.',
            ),
            Expanded(
              child: TableGrid(
                controller: _controller,
                reorderRow: true,
                theme: const TableGridThemeData(
                  border: TableGridBorder(
                    vertical: BorderSide(color: Colors.black26, width: 0.5),
                    horizontal: BorderSide(color: Colors.black26, width: 0.5),
                  ),
                ),
                builder: (_, detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        detail.cellData?.toString() ?? '',
                        softWrap: true,
                      ),
                    ),
                  );
                },
                headerBuilder: (_, detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        detail.data?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
