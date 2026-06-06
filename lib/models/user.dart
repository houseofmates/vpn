class User {
  final int uid;
  final String refreshToken;
  final String AccessToken;

  User({required this.uid, required this.refreshToken, required this.AccessToken});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['UID'] ?? 0,
      refreshToken: json['RefreshToken'] ?? '',
      AccessToken: json['AccessToken'] ?? '',
    );
  }
}
