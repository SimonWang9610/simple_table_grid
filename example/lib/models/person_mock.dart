class MockPersonInfo {
  final String key;
  final String surname;
  final String givenName;
  final String? phoneNumber;
  final String? cardAssignments;

  final String? badgeType;
  final String? tags;

  const MockPersonInfo({
    required this.key,
    required this.surname,
    required this.givenName,
    this.phoneNumber,
    this.cardAssignments,
    this.badgeType,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'Key': key,
      'Surname': surname,
      'GivenName': givenName,
      'PhoneNumber': phoneNumber,
      'CardAssignments': cardAssignments,
      'BadgeType': badgeType,
      'Tags': tags,
    };
  }
}
