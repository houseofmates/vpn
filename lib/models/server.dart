import 'package:json_annotation/json_annotation.dart';

part 'server.g.dart';

@JsonSerializable()
class Server {
  final string Name;
  final string EntryCountry;
  final double Load;
  final string? Domain;
  final string? EntryIP;
  final int Tier;
  final List<dynamic>? Servers; // We'll simplify for now

  Server({
    required this.Name,
    required this.EntryCountry,
    required this.Load,
    this.Domain,
    this.EntryIP,
    required this.Tier,
    this.Servers,
  });

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
  Map<String, dynamic> toJson() => _$ServerToJson(this);
}