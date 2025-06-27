import 'package:example/models/custom_data_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class TableColumnSelector extends StatelessWidget {
  final List<ColumnKey> selectedColumns;
  final List<CustomDataGridModel> allColumns;
  final ColumnSelectionCallback onSubmit;
  const TableColumnSelector({
    super.key,
    required this.allColumns,
    required this.selectedColumns,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Select Columns"),
              content: SingleChildScrollView(
                child: _TableColumnSelections(
                  allColumns: allColumns,
                  selected: selectedColumns,
                  onSubmit: (willAdded, willRemoved) {
                    onSubmit(willAdded, willRemoved);
                  },
                ),
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.table_chart),
      label: Text("Select Columns"),
    );
  }
}

typedef ColumnSelectionCallback = void Function(
  List<HeaderData> willAdded,
  List<ColumnKey> willRemoved,
);

class _TableColumnSelections extends StatefulWidget {
  final List<CustomDataGridModel> allColumns;
  final List<ColumnKey> selected;
  final ColumnSelectionCallback onSubmit;

  const _TableColumnSelections({
    required this.allColumns,
    required this.selected,
    required this.onSubmit,
  });

  @override
  State<_TableColumnSelections> createState() => __TableColumnSelectionsState();
}

class __TableColumnSelectionsState extends State<_TableColumnSelections> {
  final _all = <ColumnKey, HeaderData<CustomDataGridModel>>{};
  final Set<ColumnKey> _selected = {};
  final Set<ColumnKey> _unselected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.selected);

    for (final column in widget.allColumns) {
      final key = column.columnKey;
      _all[key] = HeaderData(key: key, data: column);
      if (!_selected.contains(key)) {
        _unselected.add(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.allColumns.map(
          (column) {
            return CheckboxListTile(
              value: _selected.contains(column.columnKey),
              title: Text(column.displayName ?? column.columnName),
              onChanged: (value) {
                if (value == null) return;

                if (value) {
                  _selected.add(column.columnKey);
                  _unselected.remove(column.columnKey);
                } else {
                  _unselected.add(column.columnKey);
                  _selected.remove(column.columnKey);
                }

                setState(() {});
              },
            );
          },
        ),
        const Divider(),
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final willAdded = _selected
                    .where(
                      (key) => !widget.selected.contains(key),
                    )
                    .map((key) => _all[key]!)
                    .toList();

                final willRemoved = widget.selected
                    .where(
                      (key) => _unselected.contains(key),
                    )
                    .toList();

                widget.onSubmit(willAdded, willRemoved);
                Navigator.of(context).pop();
              },
              child: Text("Apply"),
            ),
          ],
        ),
      ],
    );
  }
}
