import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  // Format numbers like 1200 → 1.2k
  static String formatCount(String number) {
    final n = int.tryParse(number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return n.toString();
  }

  // Show snackbars
  static void showSnack(BuildContext context, String msg,
      {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color ?? Colors.black87,
      ),
    );
  }

  // Add vertical space without repeating SizedBox(height: X)
  static Widget vSpace(double height) => SizedBox(height: height);

  // Add horizontal space
  static Widget hSpace(double width) => SizedBox(width: width);

  // Check dark mode easily
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
