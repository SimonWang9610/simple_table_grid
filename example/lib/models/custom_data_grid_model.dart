import 'package:simple_table_grid/simple_table_grid.dart';

class CustomDataGridModel {
  String columnName;
  bool isDisplayed;
  double width;
  // Position is what's index of this column in Header list
  int position;
  bool isPinned;
  String? tooltipMessage;
  String? displayName;
  PropertyTypeEnum propertyType;
  final bool allowSorting;
  final bool allowFiltering;
  final bool allowResizing;

  CustomDataGridModel(
      {required this.columnName,
      this.isDisplayed = true,
      this.width = 200,
      required this.position,
      this.isPinned = false,
      this.tooltipMessage,
      this.displayName,
      this.propertyType = PropertyTypeEnum.Text,
      this.allowSorting = false,
      this.allowFiltering = false,
      this.allowResizing = true});

  Map<String, Map<String, dynamic>> toJson(CustomDataGridModel inf) => {
        inf.columnName: {
          'columnName': inf.columnName,
          'isDisplayed': inf.isDisplayed,
          'width': inf.width,
          'position': inf.position,
          'isPinned': inf.isPinned,
          'displayName': inf.displayName,
          'allowSorting': inf.allowSorting,
          'allowFiltering': inf.allowFiltering,
        },
      };

  factory CustomDataGridModel.fromMap(Map<String, dynamic> map) {
    return CustomDataGridModel(
      columnName: map['columnName'] ?? '',
      isDisplayed: map['isDisplayed'] ?? true,
      width: map['width']?.toDouble() ?? 200,
      position: map['position']?.toInt() ?? 0,
      isPinned: map['isPinned'] ?? false,
      displayName: map['displayName'],
      allowSorting: map['allowSorting'] ?? false,
      allowFiltering: map['allowFiltering'] ?? false,
    );
  }
}

enum PropertyTypeEnum {
  TextFormField,
  Text,
  DropdownFormField,
  MultiOptionSelectionDropdown,
  Checkbox,
  DateTimePicker,
  TagsField,
  StringDateTime,
  DateTime,
  String,
  Menu,
  Custom
}

extension ToColumnKeyExt on CustomDataGridModel {
  ColumnKey get columnKey => ColumnKey(columnName);

  Extent buildExtent({double min = 100, double? max}) {
    return Extent.range(
      pixels: width,
      min: min,
      max: max, // Optional max width
    );
  }
}
