import 'dart:convert';

/// Decodes the `exp` claim out of a JWT without verifying its signature —
/// only used client-side to know when to proactively drop a stored session.
DateTime? decodeJwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    var payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    final decoded = utf8.decode(base64Url.decode(payload));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    return null;
  } catch (_) {
    return null;
  }
}
