import 'dart:io';
import 'package:example/models/person_mock.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

final _fake = Faker();

class ExampleHelper {
  static Future<List<MockPersonInfo>> mockPeople(int limit,
      {String? keyword}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return generateMockPeople(limit);
  }

  static List<MockPersonInfo> generateMockPeople(int count) {
    return List.generate(
      count,
      (index) => MockPersonInfo(
        key: _fake.guid.guid(),
        surname: _fake.person.lastName(),
        givenName: _fake.person.firstName(),
        phoneNumber: _fake.phoneNumber.us(),
        cardAssignments: _fake.lorem.sentence(),
        badgeType: _fake.lorem.word(),
        tags: _fake.lorem.words(3).join(", "),
      ),
    );
  }

  static Future<void> saveFile(List<int> bytes, String fileName) async {
    String? path;

    try {
      if (Platform.isAndroid) {
        final Directory? directory = await getExternalStorageDirectory();
        if (directory != null) {
          path = directory.path;
        }
      } else if (Platform.isIOS || Platform.isLinux || Platform.isWindows) {
        final Directory? directory = await getDownloadsDirectory();
        path = directory?.path;
      } else if (Platform.isMacOS) {
        Directory? directory = await getDownloadsDirectory();
        path = directory?.path;
      } else {
        path = await PathProviderPlatform.instance.getApplicationSupportPath();
      }

      print("Saving file at: $path");

      final File file =
          File(Platform.isWindows ? '$path\\$fileName' : '$path/$fileName');

      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint(
        "Error saving file: $e\n"
        "Please check if you have the permission to write to the directory.",
      );
    }
  }
}
