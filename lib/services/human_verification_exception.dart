class HumanVerificationException implements Exception {
  final String token;
  final List<String> methods;
  final String webUrl;
  final int expiresAt;

  HumanVerificationException({
    required this.token,
    required this.methods,
    required this.webUrl,
    required this.expiresAt,
  });

  @override
  String toString() =>
      'Human verification required. Open $webUrl in your browser to complete captcha, then paste the verification token.';
}
