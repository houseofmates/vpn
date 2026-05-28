import 'dart:convert';

UnauthSessionResponse unauthSessionResponseFromJson(String str) => UnauthSessionResponse.fromJson(json.decode(str));
String unauthSessionResponseToJson(UnauthSessionResponse data) => json.encode(data.toJson());

class UnauthSessionResponse {
  UnauthSessionResponse({
    required this.code,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.scopes,
    required this.uid,
    required this.localId,
  });

  int code;
  String accessToken;
  String refreshToken;
  String tokenType;
  List<String> scopes;
  String uid;
  int localId;

  factory UnauthSessionResponse.fromJson(Map<String, dynamic> json) => UnauthSessionResponse(
    code: json["Code"],
    accessToken: json["AccessToken"],
    refreshToken: json["RefreshToken"],
    tokenType: json["TokenType"],
    scopes: List<String>.from(json["Scopes"].map((x) => x)),
    uid: json["UID"],
    localId: json["LocalID"],
  );

  Map<String, dynamic> toJson() => {
    "Code": code,
    "AccessToken": accessToken,
    "RefreshToken": refreshToken,
    "TokenType": tokenType,
    "Scopes": List<dynamic>.from(scopes.map((x) => x)),
    "UID": uid,
    "LocalID": localId,
  };
}

CookieTokenResponse cookieTokenResponseFromJson(String str) => CookieTokenResponse.fromJson(json.decode(str));
String cookieTokenResponseToJson(CookieTokenResponse data) => json.encode(data.toJson());

class CookieTokenResponse {
  CookieTokenResponse({
    required this.code,
    required this.uid,
    required this.localId,
    required this.refreshCounter,
  });

  int code;
  String uid;
  int localId;
  int refreshCounter;

  factory CookieTokenResponse.fromJson(Map<String, dynamic> json) => CookieTokenResponse(
    code: json["Code"],
    uid: json["UID"],
    localId: json["LocalID"],
    refreshCounter: json["RefreshCounter"],
  );

  Map<String, dynamic> toJson() => {
    "Code": code,
    "UID": uid,
    "LocalID": localId,
    "RefreshCounter": refreshCounter,
  };
}

AuthInfoResponse authInfoResponseFromJson(String str) => AuthInfoResponse.fromJson(json.decode(str));
String authInfoResponseToJson(AuthInfoResponse data) => json.encode(data.toJson());

class AuthInfoResponse {
  AuthInfoResponse({
    required this.code,
    required this.modulus,
    required this.serverEphemeral,
    required this.salt,
    required this.srpSession,
    required this.username,
    required this.version,
  });

  int code;
  String modulus;
  String serverEphemeral;
  String salt;
  String srpSession;
  String username;
  int version;

  factory AuthInfoResponse.fromJson(Map<String, dynamic> json) => AuthInfoResponse(
    code: json["Code"],
    modulus: json["Modulus"],
    serverEphemeral: json["ServerEphemeral"],
    salt: json["Salt"],
    srpSession: json["SRPSession"],
    username: json["Username"],
    version: json["Version"],
  );

  Map<String, dynamic> toJson() => {
    "Code": code,
    "Modulus": modulus,
    "ServerEphemeral": serverEphemeral,
    "Salt": salt,
    "SRPSession": srpSession,
    "Username": username,
    "Version": version,
  };
}

AuthResponse authResponseFromJson(String str) => AuthResponse.fromJson(json.decode(str));
String authResponseToJson(AuthResponse data) => json.encode(data.toJson());

class AuthResponse {
  AuthResponse({
    required this.code,
    required this.localId,
    required this.scopes,
    required this.uid,
    required this.userId,
    required this.eventId,
    required this.passwordMode,
    required this.serverProof,
    required this.twoFactor,
    required this.twoFA,
    required this.temporaryPassword,
  });

  int code;
  int localId;
  List<String> scopes;
  String uid;
  String userId;
  String eventId;
  int passwordMode;
  String serverProof;
  int twoFactor;
  TwoFA twoFA;
  int temporaryPassword;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    code: json["Code"],
    localId: json["LocalID"],
    scopes: List<String>.from(json["Scopes"].map((x) => x)),
    uid: json["UID"],
    userId: json["UserID"],
    eventId: json["EventID"],
    passwordMode: json["PasswordMode"],
    serverProof: json["ServerProof"],
    twoFactor: json["TwoFactor"],
    twoFA: TwoFA.fromJson(json["2FA"]),
    temporaryPassword: json["TemporaryPassword"],
  );

  Map<String, dynamic> toJson() => {
    "Code": code,
    "LocalID": localId,
    "Scopes": List<dynamic>.from(scopes.map((x) => x)),
    "UID": uid,
    "UserID": userId,
    "EventID": eventId,
    "PasswordMode": passwordMode,
    "ServerProof": serverProof,
    "TwoFactor": twoFactor,
    "2FA": twoFA.toJson(),
    "TemporaryPassword": temporaryPassword,
  };
}

class TwoFA {
  TwoFA({
    required this.enabled,
    required this.fido2,
    required this.totp,
  });

  int enabled;
  Fido2 fido2;
  int totp;

  factory TwoFA.fromJson(Map<String, dynamic> json) => TwoFA(
    enabled: json["Enabled"],
    fido2: Fido2.fromJson(json["FIDO2"]),
    totp: json["TOTP"],
  );

  Map<String, dynamic> toJson() => {
    "Enabled": enabled,
    "FIDO2": fido2.toJson(),
    "TOTP": totp,
  };
}

class Fido2 {
  Fido2({
    required this.authenticationOptions,
    required this.registeredKeys,
  });

  dynamic authenticationOptions;
  List<dynamic> registeredKeys;

  Fido2.fromJson(Map<String, dynamic> json) {
    authenticationOptions = json["AuthenticationOptions"];
    registeredKeys = List<dynamic>.from(json["RegisteredKeys"].map((x) => x));
  }

  Map<String, dynamic> toJson() => {
    "AuthenticationOptions": authenticationOptions,
    "RegisteredKeys": List<dynamic>.from(registeredKeys.map((x) => x)),
  };
}

LogicalServersResponse logicalServersResponseFromJson(String str) => LogicalServersResponse.fromJson(json.decode(str));
String logicalServersResponseToJson(LogicalServersResponse data) => json.encode(data.toJson());

class LogicalServersResponse {
  LogicalServersResponse({
    required this.logicalServers,
  });

  List<LogicalServer> logicalServers;

  factory LogicalServersResponse.fromJson(Map<String, dynamic> json) => LogicalServersResponse(
    logicalServers: List<LogicalServer>.from(json["LogicalServers"].map((x) => LogicalServer.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "LogicalServers": List<dynamic>.from(logicalServers.map((x) => x.toJson())),
  };
}

class LogicalServer {
  LogicalServer({
    required this.name,
    required this.exitCountry,
    this.region,
    this.city,
    required this.servers,
    required this.features,
    this.tier,
  });

  String name;
  String exitCountry;
  String? region;
  String? city;
  List<PhysicalServer> servers;
  int features;
  int? tier;

  factory LogicalServer.fromJson(Map<String, dynamic> json) => LogicalServer(
    name: json["Name"],
    exitCountry: json["ExitCountry"],
    region: json["Region"],
    city: json["City"],
    servers: List<PhysicalServer>.from(json["Servers"].map((x) => PhysicalServer.fromJson(x))),
    features: json["Features"],
    tier: json["Tier"],
  );

  Map<String, dynamic> toJson() => {
    "Name": name,
    "ExitCountry": exitCountry,
    "Region": region,
    "City": city,
    "Servers": List<dynamic>.from(servers.map((x) => x.toJson())),
    "Features": features,
    "Tier": tier,
  };
}

class PhysicalServer {
  PhysicalServer({
    required this.entryIp,
    required this.exitIp,
    required this.domain,
    required this.status,
    required this.x25519PublicKey,
  });

  String entryIp;
  String exitIp;
  String domain;
  int status;
  String x25519PublicKey;

  factory PhysicalServer.fromJson(Map<String, dynamic> json) => PhysicalServer(
    entryIp: json["EntryIP"],
    exitIp: json["ExitIP"],
    domain: json["Domain"],
    status: json["Status"],
    x25519PublicKey: json["X25519PublicKey"],
  );

  Map<String, dynamic> toJson() => {
    "EntryIP": entryIp,
    "ExitIP": exitIp,
    "Domain": domain,
    "Status": status,
    "X25519PublicKey": x25519PublicKey,
  };
}