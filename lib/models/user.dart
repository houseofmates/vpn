import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String UserName;
  final string AccessToken;
  final string RefreshToken;
  final int UID;
  final bool HasPassword;
  final bool HasTwoFactor;

  User({
    required this.UserName,
    required this.AccessToken,
    required this.RefreshToken,
    required this.UID,
    required this.HasPassword,
    required this.HasTwoFactor,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}