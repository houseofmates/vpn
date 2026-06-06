import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';

class ProtonSRP {
  static const int _srpLenBytes = 256;
  static const int _saltLenBytes = 10;

  static const _bcryptBase64 =
      './ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const _stdBase64 =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  static List<int> _pmHash(List<int> data) {
    final out = <int>[];
    for (int i = 0; i < 4; i++) {
      out.addAll(sha512.convert(data + [i]).bytes);
    }
    return out;
  }

  static String _bcryptB64Encode(List<int> data) {
    final std = base64Encode(data);
    final sb = StringBuffer();
    for (final c in std.codeUnits) {
      final ch = String.fromCharCode(c);
      final idx = _stdBase64.indexOf(ch);
      sb.write(idx >= 0 ? _bcryptBase64[idx] : ch);
    }
    return sb.toString();
  }

  static List<int> _hashPassword3(
      List<int> password, List<int> salt, List<int> modulus) {
    final saltProton = (salt + [112, 114, 111, 116, 111, 110]).sublist(0, 16);
    final encoded = _bcryptB64Encode(saltProton);
    final b64Salt = encoded.substring(0, 22);
    final bcryptSalt = '\$2y\$10\$' + b64Salt;
    final hashed = BCrypt.hashpw(utf8.decode(password), bcryptSalt);
    return sha512.convert(utf8.encode(hashed) + modulus).bytes.toList();
  }

  static BigInt _bytesToLong(List<int> bytes) {
    var result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = result | (BigInt.from(bytes[i] & 0xff) << (8 * i));
    }
    return result;
  }

  static List<int> _longToBytes(BigInt n, int numBytes) {
    final result = List<int>.filled(numBytes, 0);
    for (int i = 0; i < numBytes; i++) {
      result[i] = (n >> (8 * i)).toInt() & 0xff;
    }
    return result;
  }

  static BigInt _customHash(List<dynamic> args) {
    var data = <int>[];
    for (final arg in args) {
      if (arg is BigInt) {
        data.addAll(_longToBytes(arg, _srpLenBytes));
      } else if (arg is List<int>) {
        data.addAll(arg);
      }
    }
    return _bytesToLong(_pmHash(data));
  }

  static BigInt _hashK(BigInt g, BigInt modulus) {
    return _customHash([
      _longToBytes(g, _srpLenBytes),
      _longToBytes(modulus, _srpLenBytes),
    ]);
  }

  /// Extracts the base64-encoded inner data from a PGP signed message.
  static String _extractPgpData(String pgpMessage) {
    final lines = pgpMessage.split('\n');
    int start = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('-----BEGIN PGP SIGNED MESSAGE-----')) {
        start = i;
        break;
      }
    }
    if (start < 0) return pgpMessage.trim();

    int dataStart = -1;
    for (int i = start + 1; i < lines.length; i++) {
      if (lines[i].trim().startsWith('-----BEGIN PGP SIGNATURE-----')) {
        dataStart = i;
        break;
      }
    }

    if (dataStart < 0) return pgpMessage.trim();

    final dataLines = <String>[];
    bool inHash = false;
    for (int i = start + 1; i < dataStart; i++) {
      final line = lines[i].trim();
      if (line.startsWith('Hash:')) {
        inHash = true;
        continue;
      }
      if (line.isEmpty && inHash) {
        inHash = false;
        continue;
      }
      if (!inHash && line.isNotEmpty) {
        dataLines.add(line);
      }
    }

    return dataLines.join('\n').trim();
  }

  static List<int> _parseModulus(String modulusArmored) {
    final dataStr = _extractPgpData(modulusArmored);
    final cleaned = dataStr.replaceAll(RegExp(r'\s'), '');
    final padded = cleaned.padRight(((cleaned.length + 3) ~/ 4) * 4, '=');
    return base64Decode(padded);
  }

  static List<int> _generateRandomBytes(int count) {
    final random = Random.secure();
    final bytes = List<int>.filled(count, 0);
    for (int i = 0; i < count; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  static BigInt _generatePrivateValue(BigInt N) {
    final bytes = _generateRandomBytes(32);
    bytes[0] = bytes[0] | 0x80;
    var a = _bytesToLong(bytes);
    a = a % (N - BigInt.one);
    if (a < BigInt.from(2)) a = BigInt.from(2);
    return a;
  }

  /// Performs the full Proton SRP auth flow.
  /// Returns [clientEphemeral, clientProof] as base64 strings.
  static Map<String, String> computeProof({
    required String password,
    required String modulusArmored,
    required String serverEphemeralB64,
    required String saltB64,
    required int version,
  }) {
    final modulusBytes = _parseModulus(modulusArmored);
    final N = _bytesToLong(modulusBytes);
    final g = BigInt.from(2);

    final Bbytes = base64Decode(serverEphemeralB64);
    final B = _bytesToLong(Bbytes);

    final saltBytes = base64Decode(saltB64);

    final passwordBytes = utf8.encode(password);

    final k = _hashK(g, N);

    var xBytes = _hashPassword3(passwordBytes, saltBytes, modulusBytes);
    var x = _bytesToLong(xBytes);

    var a = _generatePrivateValue(N);
    var A = g.modPow(a, N);

    var u = _customHash([A, B]);

    if (u == BigInt.zero) {
      a = _generatePrivateValue(N);
      A = g.modPow(a, N);
      u = _customHash([A, B]);
    }

    var v = g.modPow(x, N);
    var kv = (k * v) % N;
    var diff = B - kv;
    if (diff < BigInt.zero) diff = diff + N;
    var exp = a + u * x;
    var S = diff.modPow(exp, N);

    var K = _longToBytes(S, _srpLenBytes);

    var M1 = _customHash([A, B, K]);

    final clientEphemeral = base64Encode(_longToBytes(A, _srpLenBytes));
    final clientProof = base64Encode(_longToBytes(M1, _srpLenBytes));

    return {
      'clientEphemeral': clientEphemeral,
      'clientProof': clientProof,
    };
  }
}
