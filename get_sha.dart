import 'dart:io';
import 'package:crypto/crypto.dart';

void main() async {
  final file = File('cert.der');
  if (!file.existsSync()) {
    print('cert.der not found');
    return;
  }
  final bytes = await file.readAsBytes();
  final digest = sha256.convert(bytes);

  // Format as AA:BB:CC...
  final hex = digest.toString().toUpperCase();
  final formatted = hex
      .split('')
      .asMap()
      .entries
      .map((e) {
        return (e.key % 2 == 1 && e.key < hex.length - 1)
            ? '${e.value}:'
            : e.value;
      })
      .join('');

  print('SHA-256: $formatted');

  // Also print pure hex just in case
  print('Pure Hex: $hex');
}
