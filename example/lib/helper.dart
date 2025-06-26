import 'package:example/models/person_mock.dart';
import 'package:faker/faker.dart';

final _fake = Faker();

class ExampleHelper {
  static Future<List<MockPersonInfo>> mockPeople(int limit,
      {String? keyword}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final people = List.generate(
      limit,
      (index) => MockPersonInfo(
        key: _fake.guid.guid(),
        surname: _fake.person.lastName(),
        givenName: "${_fake.person.firstName()}${keyword ?? ""}",
        phoneNumber: _fake.phoneNumber.us(),
        cardAssignments: "<Card Assignments>",
        badgeType: "<Badge Type>",
        tags: "<Tags>",
      ),
    );

    return people;
  }
}
