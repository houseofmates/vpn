import 'package:json_annotation/json_annotation.dart';

part 'logical_server.g.dart';

@JsonSerializable()
class LogicalServer {
  final String Name;
  final String EntryCountry;
  final double Load;
  final String? Domain;
  final String? EntryIP;
  final int Tier;

  LogicalServer({
    required this.Name,
    required this.EntryCountry,
    required this.Load,
    this.Domain,
    this.EntryIP,
    required this.Tier,
  });

  factory LogicalServer.fromJson(Map<String, dynamic> json) => _$LogicalServerFromJson(json);
  Map<String, dynamic> toJson() => _$LogicalServerToJson(this);
}
