class User {
  const User({required this.id, required this.email, this.nickname});

  final int id;
  final String email;
  final String? nickname;

  /// Falls back to the local part of the email so the home screen always has
  /// something to greet the user with. Nickname is optional on signup.
  String get displayName {
    final name = nickname?.trim();
    if (name != null && name.isNotEmpty) return name;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        nickname: json['nickname'] as String?,
      );
}
