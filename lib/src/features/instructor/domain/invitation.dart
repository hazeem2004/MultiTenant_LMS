class Invitation {
  final String id;
  final String cohortId;
  final String token;
  final DateTime expiresAt;

  const Invitation({
    required this.id,
    required this.cohortId,
    required this.token,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cohortId': cohortId,
      'token': token,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  factory Invitation.fromMap(String id, Map<String, dynamic> map) {
    return Invitation(
      id: id,
      cohortId: map['cohortId'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String).toLocal(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
